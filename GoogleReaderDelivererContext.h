/**
 * @file GoogleReaderDelivererContext.h
 * @brief GoogleReaderDelivererContext declaration
 * @author Masayuki YAMAYA
 * @date 2008-11-16
 *
 * TODO: LDRDelivererContext と全く同じ。共通化しないと
 */
#import "DelivererContext.h"

@interface GoogleReaderDelivererContext : DelivererContext
{
	NSString* author_;
	NSString* title_;
	NSString* feedName_;
	NSString* uri_;
}
+ (BOOL) match:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement;
+ (DOMHTMLElement*) matchForAutoDetection:(DOMHTMLDocument*)document windowScriptObject:(WebScriptObject*)wso;
- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement;
- (NSString*) documentTitle;
- (NSString*) documentURL;
- (NSString*) menuTitle;

- (void) dealloc;
@end
