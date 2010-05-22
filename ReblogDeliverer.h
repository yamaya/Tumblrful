/**
 * @file ReblogDeliverer.h
 * @brief ReblogDeliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererBase.h"

@interface ReblogDeliverer : DelivererBase<PostCallback>
{
	NSString* postID_;
	NSString* reblogKey_;
	NSString* type_;
}
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
- (void) action:(id)sender;
+ (NSDictionary*)tokensFromIFrame:(DOMHTMLDocument*)document;
- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement postID:(NSString*)postID reblogKey:(NSString*)key;
- (void) setPostID:(NSString*)postId;
- (void) setReblogKey:(NSString*)reblogKey;
- (void) reblog;
- (void) dealloc;
- (NSString*) postType;
- (NSString*) titleForMenuItem;
@end
