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

/**
 * Original code is from http://github.com/rentzsch/jrswizzle
 * Copyright (c) 2007 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
 */
static BOOL jr_swizzleMethod(Class klass, SEL orgSel, SEL altSel)
{
	Method orgMethod = class_getInstanceMethod(klass, orgSel);
	if (orgMethod == NULL) {
		D0(@"failed class_getInstanceMethod for orignal");
		return NO;
	}

	Method altMethod = class_getInstanceMethod(klass, altSel);
	if (altMethod == NULL) {
		D0(@"failed class_getInstanceMethod for alternate");
		return NO;
	}

	class_addMethod(klass, orgSel, class_getMethodImplementation(klass, orgSel), method_getTypeEncoding(orgMethod));
	class_addMethod(klass, altSel, class_getMethodImplementation(klass, altSel), method_getTypeEncoding(altMethod));

	method_exchangeImplementations(class_getInstanceMethod(klass, orgSel), class_getInstanceMethod(klass, altSel));
	return YES;
}

static BOOL jr_swizzleClassMethod(Class klass, SEL orgSel, SEL altSel)
{
	Method orgMethod = class_getClassMethod(klass, orgSel);
	if (orgMethod == NULL) {
		D0(@"failed class_getClassMethod for orignal");
		return NO;
	}

	Method altMethod = class_getClassMethod(klass, altSel);
	if (altMethod == NULL) {
		D0(@"failed class_getClassMethod for alternate");
		return NO;
	}

	method_exchangeImplementations(orgMethod, altMethod);
	return YES;
}

@implementation Tumblrful
/**
 * 'load' class method
 *	A special method called by SIMBL once the application has started and
 *	all classes are initialized.
 */
+ (void)load
{
	NSString * bundleInfoString = [[[NSBundle bundleWithIdentifier:TUMBLRFUL_BUNDLE_ID] infoDictionary] objectForKey:@"CFBundleGetInfoString"];
	LogEnable(DEBUG_LOG_SWITCH);
	NSLog(@"%@", bundleInfoString);
	D0(bundleInfoString);

	Tumblrful* plugin = [Tumblrful sharedInstance];
	plugin = plugin;

	// Contextual Menu
	Class clazz = NSClassFromString(@"BrowserWebView");
	jr_swizzleMethod(clazz, @selector(webView:contextMenuItemsForElement:defaultMenuItems:), @selector(webView_SwizzledByTumblrful:contextMenuItemsForElement:defaultMenuItems:));
	jr_swizzleMethod(clazz, @selector(performKeyEquivalent:), @selector(performKeyEquivalent_SwizzledByTumblrful:));

	// Single Window
	if ([[UserSettings sharedInstance] boolForKey:@"openInBackgroundTab"]) {
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
+ (void)install
{
	// do nothing.
}

+ (Tumblrful *)sharedInstance
{
	static Tumblrful * plugin = nil;

	if (plugin == nil) {
		plugin = [[Tumblrful alloc] init];
	}
	return plugin;
}
@end
