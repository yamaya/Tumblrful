/**
 * @file DelivererBase.h
 * @brief DelivererBase class declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "Deliverer.h"
#import "DelivererContext.h"
#import "PostCallback.h"

#define MENUITEM_TAG_NEED_EDIT	0x8000
#define MENUITEM_TAG_MASK		0x00FF

/**
 * DelivererBase abstract class
 */
@interface DelivererBase : NSObject<Deliverer, PostCallback>
{
	DelivererContext * context_;
	NSUInteger filterMask_;
	BOOL needEdit_;
}

/**
 * Initialize object
 *	@param[in] context DelivererContext object
 */
- (id)initWithContext:(DelivererContext *)context;

/**
 * Initialize object
 *	creates an object inside DelivererContext.
 *	@param[in] document 現在表示しているビューの DOMHTMLDocumentオブジェクト
 *	@param[in] targetElement 選択していた要素の情報
 */
- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement;

/**
 * post "Link" contents
 *	@param[in] url	URL
 *	@param[in] title	URL title
 */
- (void)postLink:(NSString *)url title:(NSString *)title;

/**
 * post "Quote" contents
 *	@param[in] quote	quote text
 *	@param[in] source	source
 */
- (void)postQuote:(NSString *)quote source:(NSString *)source;

/**
 * post "Photo" contents
 *	@param[in] source	URL of image
 *	@param[in] caption	caption text
 *	@param[in] url	click-through URL
 *	@param[in] image	NSImage object
 */
- (void)postPhoto:(NSString *)source caption:(NSString *)caption through:(NSString *)url image:(NSImage *)image;

/**
 * "Video" post.
 *	@param[in] embed embed or URL
 *	@param[in] caption caption
 */
- (void)postVideo:(NSString *)embed caption:(NSString *)caption;

/**
 * "Reblog" post.
 *	@param[in] params	contents of Reblog. Determined by the target service.
 */
- (void)postEntry:(NSDictionary *)params;

/**
 * Notify message to UI
 *	@param[in] message	message text
 */
- (void)notify:(NSString *)message;

/**
 * MenuItem's title
 *	@return title
 */
- (NSString *)titleForMenuItem;

/**
 * Create the some Menu items
 *	@return array of NSMenuItem objet
 */
- (NSArray *)createMenuItems;

/**
 * Action with parameters
 *	@param[in] param array object following contents
 *	- index 0 ... Sender object
 *	- index 1 ... Mask
 */
- (void)actionWithMask:(NSArray *)param;
@end
