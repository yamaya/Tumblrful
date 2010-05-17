#import <WebKit/WebKit.h>

@interface WebView (SafariSingleWindow)
- (WebView *) webView_SwizzledBySafariSingleWindow:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request;
- (WebView *) webView_SwizzledBySafariSingleWindow:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request windowFeatures:(NSDictionary *)features;
- (WebView *) webView_SwizzledBySafariSingleWindow:(WebView *)sender setFrame:(NSRect)frameRect;
- (WebView *) webView_SwizzledBySafariSingleWindow:(WebView *)sender setToolbarsVisible:(BOOL)toggle;
- (WebView *) webView_SwizzledBySafariSingleWindow:(WebView *)sender setStatusBarVisible:(BOOL)toggle;
@end
