/**
 * @file AggregatorDeliverContext.h
 */
#import "DelivererContext.h"

/**
 * AggregatorDeliverContext class
 */
@interface AggregatorDeliverContext : DelivererContext
{
	NSString * title_;		// entry title
	NSString * source_;		// entry source e.g. "TechCrunch Japan"
	NSString * URL_;		// URL to original page
}

+ (DOMNode *)entryNodeWithDocument:(DOMHTMLDocument *)document target:(NSDictionary*)targetElement;

/**
 * Subclass should be override this method.
 */
+ (NSString *)entryNodeExpression;

/**
 * Aggregator(Service) name - e.g. "Google Reader" ...etc
 * Subclass should be override this method.
 */
+ (NSString *)name;

/**
 * Utility method for Subclass.
 */
- (NSString *)evaluateWithXPathExpression:(NSString *)expression target:(DOMNode *)targetNode;

- (NSString *)titleWithNode:(DOMNode *)targetNode;

- (NSString *)sourceWithNode:(DOMNode *)targetNode;

- (NSString *)URLWithNode:(DOMNode *)targetNode;

/**
 * Utility method for Subclass.
 */
+ (void)dump:(DOMXPathResult *)result;
@end
