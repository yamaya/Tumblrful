/**
 * @file Deliverer.h
 * @brief Deliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import <WebKit/DOMHTMLDocument.h>

/**
 * Deliverer protocol
 */
@protocol Deliverer
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
- (NSString*) postType;
- (NSMenuItem*) createMenuItem;
- (void) action:(id)sender;
@end
