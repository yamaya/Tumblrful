/**
 * @file LDRReblogDeliverer.h
 * @brief LDRReblogDeliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "ReblogDeliverer.h"

@interface LDRReblogDeliverer : ReblogDeliverer
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
@end
