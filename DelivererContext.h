/**
 * @file DelivererContext.h
 * @brief DelivererContext class declaration
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
	DOMHTMLDocument * document_;
}

@property (nonatomic, readonly) DOMHTMLDocument * document;

@property (nonatomic, readonly) NSString * documentTitle;

@property (nonatomic, readonly) NSString * documentURL;

@property (nonatomic, readonly) NSString * anchorToDocument;

@property (nonatomic, readonly) NSString * menuTitle;

/**
 * To process HTML documents to determine whether.
 *	@param[in] document DOM document to be evaluated
 *	@param[in] targetElement DOM lement to be evaluated
 *	@return YES is to be processed
 */
+ (BOOL)match:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement;

/**
 * To process HTML documents to determine whether - auto detect DOM element.
 *	@param[in] document DOM document to be evaluated
 *	@param[in] wso WebScriptObject object
 *	@return YES is to be processed
 */
+ (DOMHTMLElement *)matchForAutoDetection:(DOMHTMLDocument *)document windowScriptObject:(WebScriptObject *)wso;

/**
 * Evaluate XPath expression
 *	@param[in] expressions XPath expression (array of NSString object)
 *	@param[in] document DOM document to be evaluated
 *	@param[in] contextNode DOM node to be evaluated
 *	@return DOMHTMLElement object of XPath evalueted
 */
+ (DOMHTMLElement *)evaluate:(NSArray *)expressions document:(DOMHTMLDocument *)document contextNode:(DOMNode *)node;

/**
 * Evaluate XPath expression
 *	@param[in] expressions XPath expression string
 *	@param[in] contextNode DOM node to be evaluated
 *	@param[in] type XPath evaluate type
 *	@param[in] inResult XPathResult object for evaluate
 *	@return DOMXPathResult object
 */
- (DOMXPathResult *)evaluateToDocument:(NSString *)expression contextNode:(DOMNode *)contextNode type:(unsigned short)type inResult:(DOMXPathResult *)inResult;

/**
 * Initialize object
 *	creates an object inside DelivererContext.
 *	@param[in] document Currently displayed object DOMHTMLDocument
 *	@param[in] targetElement Selected elements
 */
- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement;
@end
