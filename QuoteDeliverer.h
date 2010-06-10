/**
 * @file QuoteDeliverer.h
 * @brief QuoteDeliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererBase.h"

@interface QuoteDeliverer : DelivererBase
{
	NSString * selectionText_;
}
- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement selection:(NSString *)selection;

- (NSString *)postType;

- (NSString *)titleForMenuItem;

- (void)action:(id)sender;

+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
@end
