/**
 * @file FlickrPhotoDeliverer.h
 * @brief FlickrPhotoDeliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "PhotoDeliverer.h"

@interface FlickrPhotoDeliverer : PhotoDeliverer
/*
 * PhotoDeliver overrides
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
- (NSString*) titleForMenuItem;
- (void) action:(id)sender;
@end
