/**
 * @file ReblogDeliverer.h
 * @brief ReblogDeliverer class declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererBase.h"

/**
 * Deliverer concrete class for Tumblr service
 *	Tumblr's page can be used only
 */
@interface ReblogDeliverer : DelivererBase
{
	NSString * postID_;
	NSString * reblogKey_;
}

/**
 * Initialize object
 *	creates an object inside DelivererContext.
 *	@param[in] document 現在表示しているビューの DOMHTMLDocumentオブジェクト
 *	@param[in] targetElement 選択していた要素の情報
 *	@param[in] postID ポストID
 *	@param[in] reblogKey Reblogキー
 */
- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement postID:(NSString *)postID reblogKey:(NSString *)key;

/**
 * Initialize object
 *	creates an object inside DelivererContext.
 *	reblogKey is set to nil.
 *	@param[in] document 現在表示しているビューの DOMHTMLDocumentオブジェクト
 *	@param[in] targetElement 選択していた要素の情報
 *	@param[in] postID ポストID
 */
- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement postID:(NSString *)postID;

/**
 * Initialize object
 *	@param[in] context DelivererContext object
 *	@param[in] postID ポストID
 *	@param[in] reblogKey Reblogキー
 */
- (id)initWithContext:(DelivererContext *)context postID:(NSString *)postID reblogKey:(NSString *)rk;

/**
 * Initialize object
 *	reblogKey is set to nil.
 *	@param[in] context DelivererContext object
 *	@param[in] postID ポストID
 */
- (id)initWithContext:(DelivererContext *)context postID:(NSString *)postID;

/**
 * Set PostID
 */
- (void)setPostID:(NSString *)postId;

/**
 * Set Reblog Key
 */
- (void) setReblogKey:(NSString*)reblogKey;
@end
