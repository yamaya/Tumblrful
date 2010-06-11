/**
 * @file DelivererBase.h
 * @brief DelivererBase declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "Deliverer.h"
#import "DelivererContext.h"
#import "PostCallback.h"

#define MENUITEM_TAG_NEED_EDIT	0x8000
#define MENUITEM_TAG_MASK		0x00FF

/**
 * DeliverBase abstract class
 */
@interface DelivererBase : NSObject <Deliverer, PostCallback>
{
	DelivererContext * context_;
	NSUInteger filterMask_;
	BOOL needEdit_;
}

/* Deliverer protocols */
+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement;

- (NSMenuItem *)createMenuItem;

- (void)action:(id)sender;

/* common process for PostCallback */
- (void) posted:(NSData*)response;
- (void) failed:(NSError*)error;

- (id)initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement;

/**
 * post "Link" contents
 *	@param[in] url	URL
 *	@param[in] title	URL title
 */
- (void)postLink:(NSString *)url title:(NSString *)title;

/**
 * post "Quote" contents
 *	@param[in] quote	quote text
 */
- (void)postQuote:(NSString *)quote;

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

- (NSObject*) postEntry:(NSDictionary*)params;

/* PostCallback overrides */
- (void) successed:(NSString*)response;
- (void) failedWithError:(NSError*)error;
- (void) failedWithException:(NSException*)exception;

- (void) notify:(NSString*)message;
- (void) failedWithException:(NSException*)exception;

/**
 * メニューアイテムのタイトルを取得する
 *	@return タイトル
 */
- (NSString *)titleForMenuItem;

/**
 * メニューアイテム(複数)を生成する.
 *	@return メニューアイテムを格納した配列
 */
- (NSArray *)createMenuItems;

- (void)actionWithMask:(NSArray *)param;
@end
