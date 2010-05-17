#import "SafariSingleWindow.h"
#import "Log.h"

#define V(format, ...)	Log(format, __VA_ARGS__)
//#define V(format, ...)

@implementation WebView (SafariSingleWindow)

- (WebView *) webView_SwizzledBySafariSingleWindow:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
	V(@"%@", @"webView_SwizzledBySafariSingleWindow:createWebViewWithRequest");
	NSWindow * window = [self window];
	if (!window)
		goto failed;

	NSWindowController * controller = [window windowController];
	if (!controller)
		goto failed;

	WebView * tab = [controller createInactiveTab];
	if (!tab)
		goto failed;

	WebFrame * frame = [tab mainFrame];
	if (!frame) {
		V(@"%@", @"[SafariSingleWindow] Got nil mainFrame for createTab, attempting closeTab");
		[controller closeTab: tab];
		goto failed;
	}

succeeded:
	[frame loadRequest: request];
	return tab;

failed:
	return [self webView_SwizzledBySafariSingleWindow: sender createWebViewWithRequest: request];
}

- (WebView *) webView_SwizzledBySafariSingleWindow:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request windowFeatures:(NSDictionary *)features
{
	V(@"%@", @"webView_SwizzledBySafariSingleWindow:createWebViewWithRequest:windowFeatures");

	NSWindow * window = [self window];
	if (!window)
		goto failed;

	NSWindowController * controller = [window windowController];
	if (!controller)
		goto failed;

	WebView * tab = [controller createInactiveTab];
	if (!tab)
		goto failed;

	WebFrame * frame = [tab mainFrame];
	if (!frame) {
		V(@"%@", @"[SafariSingleWindow] Got nil mainFrame for createTab, attempting closeTab");
		[controller closeTab: tab];
		goto failed;
	}

succeeded:
	V(@"%@", @"succeeded");
	[frame loadRequest:request];
	return tab;

failed:
	V(@"%@", @"failed");
	return [self webView_SwizzledBySafariSingleWindow: sender createWebViewWithRequest: request windowFeatures: features];
}

- (WebView *) webView_SwizzledBySafariSingleWindow:(WebView *)sender setFrame:(NSRect)frameRect
{
	// nop
	return nil;
}

- (WebView *) webView_SwizzledBySafariSingleWindow:(WebView *)sender setToolbarsVisible:(BOOL)toggle
{
	// nop
	return nil;
}

- (WebView *) webView_SwizzledBySafariSingleWindow:(WebView *)sender setStatusBarVisible:(BOOL)toggle
{
	// nop
	return nil;
}
@end