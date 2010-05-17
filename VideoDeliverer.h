/**
 * @file VideoDeliverer.h
 * @brief VideoDeliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererBase.h"

@interface VideoDeliverer : DelivererBase
{
	NSDictionary* clickedElement_;
}
+ (NSString*) name;
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
- (id) initWithDocument:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
- (void) dealloc;
- (NSString*) postType;
- (NSString*) makeCaption;
- (void) action:(id)sender;
@end
