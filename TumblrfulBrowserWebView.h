/**
 * @file TumblrfulBrowserWebView.h
 * @brief TumblrfulBrowserWebView declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import <WebKit/WebKit.h> // need before Safari header

@interface WebView (TumblrfulBrowserWebView)
- (NSArray *)webView_SwizzledByTumblrful:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems;

/**
 * Deliverer の class を singleton な array にしまっておく
 *	@return array of Deliverers.
 */
- (NSArray *)sharedDelivererClasses;

/**
 * コンテキストメニューに独自の要素を追加する。
 *	@param[in] menu オリジナルの NSMenuItem の配列
 *	@param[in] element クリックしている要素
 *	@return NSMenuItem の配列
 */
- (NSArray *)buildMenu:(NSMutableArray *)menu element:(NSDictionary *)element;

/**
 * validate account
 *	@return true is valid account, other than false.
 */
- (BOOL)validateAccount;

- (BOOL)performKeyEquivalent_SwizzledByTumblrful:(NSEvent *)event;
@end
