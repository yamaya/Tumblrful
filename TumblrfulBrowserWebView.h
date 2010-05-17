/**
 * @file TumblrfulBrowserWebView.h
 * @brief TumblrfulBrowserWebView declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import <WebKit/WebKit.h> // need before Safari header

@interface WebView (TumblrfulBrowserWebView)
- (NSArray*) webView_SwizzledByTumblrful:(WebView*)sender contextMenuItemsForElement:(NSDictionary*)element defaultMenuItems:(NSArray*)defaultMenuItems;
- (NSArray*) sharedDelivererClasses;
- (NSArray*) buildMenu:(NSMutableArray*)menu element:(NSDictionary*)element;
- (BOOL) validateAccount;

- (BOOL) performKeyEquivalent_SwizzledByTumblrful:(NSEvent*)event;
@end
