/**
 * @file Tumblrful.cpp
 * @brief SIMBL Plugin entry point
 * @author Masayuki YAMAYA
 * @date 2008-03-02
 */
#import "Tumblrful.h"
#import "TumblrfulBrowserWebView.h"
#import "SafariSingleWindow.h"
#import "GrowlSupport.h"
#import "UserSettings.h"
#import "TumblrfulConstants.h"
#import "DebugLog.h"
#import <objc/objc-runtime.h>

#ifdef DEBUG
#define DEBUG_LOG_SWITCH	true
#else
#define DEBUG_LOG_SWITCH	false
#endif

#define V(format, ...)	Log(format, __VA_ARGS__)
//#define V(format, ...)

/**
 * Original code is from http://github.com/rentzsch/jrswizzle
 * Copyright (c) 2007 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
 */
static BOOL jr_swizzleMethod(Class klass, SEL origSel, SEL altSel)
{
	Method origMethod = class_getInstanceMethod(klass, origSel);
	V(@"original method=%p", origMethod);
	if (origMethod == NULL) {
		return NO;
	}

	Method altMethod = class_getInstanceMethod(klass, altSel);
	V(@"replacement method=%p", altMethod);
	if (altMethod == NULL) {
		return NO;
	}

	class_addMethod(klass, origSel, class_getMethodImplementation(klass, origSel), method_getTypeEncoding(origMethod));
	class_addMethod(klass, altSel, class_getMethodImplementation(klass, altSel), method_getTypeEncoding(altMethod));

	method_exchangeImplementations(class_getInstanceMethod(klass, origSel), class_getInstanceMethod(klass, altSel));
	return YES;
}

static BOOL jr_swizzleClassMethod(Class klass, SEL origSel, SEL altSel)
{
	Method origMethod = class_getClassMethod(klass, origSel);
	V(@"original ClassMethod=%p", origMethod);
	if (origMethod == NULL) {
		return NO;
	}

	Method altMethod = class_getClassMethod(klass, altSel);
	V(@"replacement ClassMethod=%p", altMethod);
	if (altMethod == NULL) {
		return NO;
	}

	method_exchangeImplementations(origMethod, altMethod);
	return YES;
}

@implementation Tumblrful
/**
 * 'load' class method
 *	A special method called by SIMBL once the application has started and
 *	all classes are initialized.
 */
+ (void) load
{
	NSString * bundleInfoString = [[[NSBundle bundleWithIdentifier:TUMBLRFUL_BUNDLE_ID] infoDictionary] objectForKey:@"CFBundleGetInfoString"];
	LogEnable(DEBUG_LOG_SWITCH);
	NSLog(bundleInfoString);
	D0(bundleInfoString);

	Tumblrful* plugin = [Tumblrful sharedInstance];
	plugin = plugin;

	// Contextual Menu
	Class clazz = NSClassFromString(@"BrowserWebView");
	jr_swizzleMethod(clazz, @selector(webView:contextMenuItemsForElement:defaultMenuItems:), @selector(webView_SwizzledByTumblrful:contextMenuItemsForElement:defaultMenuItems:));
	jr_swizzleMethod(clazz, @selector(performKeyEquivalent:), @selector(performKeyEquivalent_SwizzledByTumblrful:));

	// Single Window
	if ([[UserSettings sharedInstance] boolForKey:@"openInBackgroundTab"]) {
		clazz = NSClassFromString(@"BrowserWebView");
		jr_swizzleMethod(clazz, @selector(webView:createWebViewWithRequest:windowFeatures:), @selector(webView_SwizzledBySafariSingleWindow:createWebViewWithRequest:windowFeatures:));
		jr_swizzleMethod(clazz, @selector(webView:createWebViewWithRequest:), @selector(webView_SwizzledBySafariSingleWindow:createWebViewWithRequest:));
		jr_swizzleMethod(clazz, @selector(webView:setFrame:), @selector(webView_SwizzledBySafariSingleWindow:setFrame:));
		jr_swizzleMethod(clazz, @selector(webView:setToolbarsVisible:), @selector(webView_SwizzledBySafariSingleWindow:setToolbarsVisible:));
		jr_swizzleMethod(clazz, @selector(webView:setStatusBarVisible:), @selector(webView_SwizzledBySafariSingleWindow:setStatusBarVisible:));
	}

	// Preferences Pange
	clazz = NSClassFromString(@"NSPreferences");
	jr_swizzleClassMethod(
			  clazz
			, @selector(sharedPreferences)
			, @selector(sharedPreferences_SwizzledByTumblrful)
			);
}

/**
 * install.
 *	invoke by SIMBL, after 'load' method.
 * @note need NSPricipalClass description in Info.plist.
 */
+ (void) install
{
	// do nothing.
}

/**
 * 'sharedInstance' class method
 * @return the single static instance of the plugin object
 */
+ (Tumblrful*) sharedInstance
{
	static Tumblrful* plugin = nil;

	if (plugin == nil) {
		plugin = [[Tumblrful alloc] init];
	}
	return plugin;
}
@end
