/**
 * @file SafariSingleWindow.m
 * @brief SafariSingleWindow class implementation
 */
#import "SafariSingleWindow.h"
#import "UserSettings.h"
#import "DebugLog.h"

@implementation WebView (SafariSingleWindow)

- (WebView *)webView_SwizzledBySafariSingleWindow:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
	D0(@"webView_SwizzledBySafariSingleWindow:createWebViewWithRequest");

	if (![[UserSettings sharedInstance] boolForKey:@"openInBackgroundTab"])
		goto failed;

	NSWindow * window = [self window];
	if (!window)
		goto failed;

	NSWindowController * controller = [window windowController];
	if (!controller)
		goto failed;

	WebView * tab = [controller performSelector:@selector(createInactiveTab) withObject:nil];
	if (!tab)
		goto failed;

	WebFrame * frame = [tab mainFrame];
	if (!frame) {
		D0(@"Got nil mainFrame for createTab, attempting closeTab");
		[controller performSelector:@selector(closeTab:) withObject:tab];
		goto failed;
	}

	[frame loadRequest: request];
	return tab;

failed:
	return [self webView_SwizzledBySafariSingleWindow:sender createWebViewWithRequest:request];
}

- (WebView *)webView_SwizzledBySafariSingleWindow:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request windowFeatures:(NSDictionary *)features
{
	D0(@"webView_SwizzledBySafariSingleWindow:createWebViewWithRequest:windowFeatures");

	if (![[UserSettings sharedInstance] boolForKey:@"openInBackgroundTab"])
		goto failed;

	NSWindow * window = [self window];
	if (!window)
		goto failed;

	NSWindowController * controller = [window windowController];
	if (!controller)
		goto failed;

	WebView * tab = [controller performSelector:@selector(createInactiveTab) withObject:nil];
	if (!tab)
		goto failed;

	WebFrame * frame = [tab mainFrame];
	if (!frame) {
		D0(@"Got nil mainFrame for createTab, attempting closeTab");
		[controller performSelector:@selector(closeTab:) withObject:tab];
		goto failed;
	}

	D0(@"succeeded");
	[frame loadRequest:request];
	return tab;

failed:
	return [self webView_SwizzledBySafariSingleWindow: sender createWebViewWithRequest: request windowFeatures: features];
}

- (WebView *)webView_SwizzledBySafariSingleWindow:(WebView *)sender setFrame:(NSRect)frameRect
{
	if (![[UserSettings sharedInstance] boolForKey:@"openInBackgroundTab"])
		return [self webView_SwizzledBySafariSingleWindow:sender setFrame:frameRect];

	// nop
	return nil;
}

- (WebView *)webView_SwizzledBySafariSingleWindow:(WebView *)sender setToolbarsVisible:(BOOL)toggle
{
	if (![[UserSettings sharedInstance] boolForKey:@"openInBackgroundTab"])
		return [self webView_SwizzledBySafariSingleWindow:sender setToolbarsVisible:toggle];

	// nop
	return nil;
}

- (WebView *)webView_SwizzledBySafariSingleWindow:(WebView *)sender setStatusBarVisible:(BOOL)toggle
{
	if (![[UserSettings sharedInstance] boolForKey:@"openInBackgroundTab"])
		return [self webView_SwizzledBySafariSingleWindow:sender setStatusBarVisible:toggle];

	// nop
	return nil;
}
@end
