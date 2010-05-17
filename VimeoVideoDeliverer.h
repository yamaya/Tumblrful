/**
 * @file VimeoVideoDeliverer.h
 * @brief VimeoVideoDeliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "VideoDeliverer.h"

@interface VimeoVideoDeliverer : VideoDeliverer
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
- (NSString*) titleForMenuItem;
- (void) action:(id)sender;
@end
