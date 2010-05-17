/**
 * @file DelivererContext.h
 * @brief DelivererContext declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import <Foundation/NSObject.h>
#import <WebKit/WebScriptObject.h>

@class DOMHTMLDocument;
@class DOMHTMLElement;
@class DOMNode;
@class DOMXPathResult;

@interface DelivererContext : NSObject
{
	DOMHTMLDocument* document_;
}
+ (BOOL) match:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement;
+ (DOMHTMLElement*) matchForAutoDetection:(DOMHTMLDocument*)document windowScriptObject:(WebScriptObject*)wso;
+ (DOMHTMLElement*) evaluate:(NSArray*)expressions document:(DOMHTMLDocument*)document contextNode:(DOMNode*)node;
- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement;
- (DOMHTMLDocument*) document;
- (NSString*) documentTitle;
- (NSString*) documentURL;
- (NSString*) anchorTagToDocument;
- (NSString*) menuTitle;
- (DOMXPathResult*) evaluateToDocument:(NSString*)expression contextNode:(DOMNode*)contextNode type:(unsigned short)type inResult:(DOMXPathResult*)inResult;
@end
