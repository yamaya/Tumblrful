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
#if 1
	if (class_addMethod(klass, orgSel, method_getImplementation(altMethod), method_getTypeEncoding(altMethod))) {
		class_addMethod(klass, altSel, method_getImplementation(orgMethod), method_getTypeEncoding(orgMethod));
	}
	else {
		method_exchangeImplementations(orgMethod, altMethod);
	}
#else
	class_addMethod(klass, orgSel, class_getMethodImplementation(klass, orgSel), method_getTypeEncoding(orgMethod));
	class_addMethod(klass, altSel, class_getMethodImplementation(klass, altSel), method_getTypeEncoding(altMethod));

	method_exchangeImplementations(class_getInstanceMethod(klass, orgSel), class_getInstanceMethod(klass, altSel));
#endif
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
	BOOL swizzled;
	Class clazz = NSClassFromString(@"BrowserWebView");
	swizzled = jr_swizzleMethod(clazz, @selector(webView:contextMenuItemsForElement:defaultMenuItems:), @selector(webView_SwizzledByTumblrful:contextMenuItemsForElement:defaultMenuItems:));
	if (!swizzled) D0(@"failed swizzle webView:contextMenuItemsForElement:defaultMenuItems:");
	swizzled = jr_swizzleMethod(clazz, @selector(performKeyEquivalent:), @selector(performKeyEquivalent_SwizzledByTumblrful:));
	if (!swizzled) D0(@"failed swizzle performKeyEquivalent:");
	swizzled = jr_swizzleMethod(clazz, @selector(mouseMoved:), @selector(mouseMoved_SwizzledByTumblrful:));
	if (!swizzled) D0(@"failed swizzle mouseMoved:");

	// Single Window
	if ([[UserSettings sharedInstance] boolForKey:@"openInBackgroundTab"]) {
		swizzled = jr_swizzleMethod(clazz, @selector(webView:createWebViewWithRequest:windowFeatures:), @selector(webView_SwizzledBySafariSingleWindow:createWebViewWithRequest:windowFeatures:));
		if (!swizzled) D0(@"failed swizzle webView:createWebViewWithRequest:windowFeatures:");
		swizzled = jr_swizzleMethod(clazz, @selector(webView:createWebViewWithRequest:), @selector(webView_SwizzledBySafariSingleWindow:createWebViewWithRequest:));
		if (!swizzled) D0(@"failed swizzle webView:createWebViewWithRequest:");
		swizzled = jr_swizzleMethod(clazz, @selector(webView:setFrame:), @selector(webView_SwizzledBySafariSingleWindow:setFrame:));
		if (!swizzled) D0(@"failed swizzle webView:setFrame:");
		swizzled = jr_swizzleMethod(clazz, @selector(webView:setToolbarsVisible:), @selector(webView_SwizzledBySafariSingleWindow:setToolbarsVisible:));
		if (!swizzled) D0(@"failed swizzle webView:setToolbarsVisible:");
		swizzled = jr_swizzleMethod(clazz, @selector(webView:setStatusBarVisible:), @selector(webView_SwizzledBySafariSingleWindow:setStatusBarVisible:));
		if (!swizzled) D0(@"failed swizzle webView:setStatusBarVisible:");
	}

	clazz = NSClassFromString(@"WebHTMLView");
	swizzled = jr_swizzleMethod(clazz, @selector(mouseDown:), @selector(mouseDown_SwizzledByTumblrful:));
	if (!swizzled) D0(@"failed swizzle mouseDown:");
	
	
	// Preferences Pange
	clazz = NSClassFromString(@"NSPreferences");
	swizzled = jr_swizzleClassMethod(
			  clazz
			, @selector(sharedPreferences)
			, @selector(sharedPreferences_SwizzledByTumblrful)
			);
	if (!swizzled) D0(@"failed swizzle sharedPreferences");
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
