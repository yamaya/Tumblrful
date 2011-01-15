/**
 * @file TumblrfulBrowserWebView.h
 * @brief TumblrfulBrowserWebView declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import <WebKit/WebKit.h> // need before Safari header

@interface WebView (TumblrfulBrowserWebView)
/**
 * @method webView:contextMenuItemsForElement:defaultMenuItems:
 * @brief Returns the menu items to display in an element's contextual menu.
 * @param[in] sender The WebView sending the delegate method.
 * @param[in] element A dictionary representation of the clicked element.
 * @param[in] defaultMenuItems An array of default NSMenuItems to include in all contextual menus.
 * @return An array of NSMenuItems to include in the contextual menu.
 */
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

/**
 * @method performKeyEquivalent
 * @brief このメソッドが呼ばれるのはjavascriptで食われていないキーの時だけみたい。
 *	このメソッドはとりあえずで作ったのでクラスの責務を逸脱しているし、コンテ
 *	キストメニューとの統一も考えてない。が、使い心地が良いのでそのままにして
 *	ある。 
 * @param event NSEvent object
 * @return イベントに応答した場合 YES。
 */
- (BOOL)performKeyEquivalent_SwizzledByTumblrful:(NSEvent *)event;

- (void)setCaptureEnabledByTumblrful:(NSNumber *)enabled;

@end
