/**
 * @file QuoteDeliverer.h
 * @brief QuoteDeliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererBase.h"

@interface QuoteDeliverer : DelivererBase
{
	NSString* selectionText_;
}
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement selection:(NSString*)selection;
- (void) dealloc;
- (NSString*) postType;
- (NSString*) titleForMenuItem;
- (void) action:(id)sender;
@end
