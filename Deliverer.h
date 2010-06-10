/**
 * @file Deliverer.h
 * @brief Deliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import <WebKit/DOMHTMLDocument.h>

/**
 * Deliverer protocol
 */
@protocol Deliverer

/**
 * create Deliver adopt object.
 *	@param[in] document 現在表示しているビューの DOMHTMLDocumentオブジェクト
 *	@param[in] clickedElement 選択していた要素の情報
 */
+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement;

/**
 * ポストのタイプを取得する.
 *	@return ポストタイプを示す文字列
 */
- (NSString *)postType;

/**
 * MenuItemを生成する
 *	@return NSMenuItemオブジェクト
 */
- (NSMenuItem *)createMenuItem;

/**
 * メニューのアクション.
 *	派生クラスがオーバーライドすることが前提。
 *	@param sender メニューを送信したオブジェクト
 */
- (void)action:(id)sender;
@end

