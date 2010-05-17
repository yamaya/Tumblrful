/**
 * @file GoogleReaderReblogDeliverer.h
 * @brief GoogleReaderReblogDeliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-11-16
 */
#import "LDRReblogDeliverer.h"

/**
 * @class GoogleReaderReblogDeliverer
 */
@interface GoogleReaderReblogDeliverer : LDRReblogDeliverer
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
@end
