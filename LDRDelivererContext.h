/**
 * @file LDRDelivererContext.h
 * @brief LDRDelivererContext declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererContext.h"

@interface LDRDelivererContext : DelivererContext
{
	NSString* author_;
	NSString* title_;
	NSString* feedName_;
	NSString* uri_;
}
+ (BOOL) match:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement;
- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement;
- (NSString*) documentTitle;
- (NSString*) documentURL;
- (NSString*) menuTitle;

- (void) dealloc;
@end
