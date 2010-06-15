/**
 * @file LDRDelivererContext.m
 * @brief LDRDelivererContext class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "LDRDelivererContext.h"
#import "DebugLog.h"
#import <WebKit/DOM.h>
#import <WebKit/WebView.h>

static NSString * LDR_HOSTNAME			= @"reader.livedoor.com";
static NSString * FASTLADDER_HOSTNAME	= @"fastladder.com";

@interface LDRDelivererContext ()
+ (BOOL)siteMatchWithURL:(NSString *)URL;
- (NSString *)titleWithNode:(DOMNode *)targetNode;
- (NSString *)sourceWithNode:(DOMNode *)targetNode;
- (NSString *)URLWithNode:(DOMNode *)targetNode;
@end

@implementation LDRDelivererContext

+ (BOOL)siteMatchWithURL:(NSString *)URL
{
	NSURL * u = [NSURL URLWithString:URL];
	if (u != nil) {
		// host をチェック
		NSString * host = [u host];
		if ([host isEqualToString:LDR_HOSTNAME] || [host isEqualToString:FASTLADDER_HOSTNAME]) {
			return YES;
		}
	}
	return NO;
}


+ (BOOL)match:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
	if ([self siteMatchWithURL:[document URL]]) {
		if ([self entryNodeWithDocument:document target:targetElement] != nil) {
			return YES;
		}
	}
	return NO;
}

+ (DOMHTMLElement *)matchForAutoDetection:(DOMHTMLDocument *)document windowScriptObject:(WebScriptObject *)wso;
{
	if ([self siteMatchWithURL:[document URL]] == NO) return nil;

	DOMHTMLElement * element = nil;

	@try {
		DOMHTMLElement * itemBody = nil;
		// window.get_active_item メソッドを利用して、フォーカスしているアイテムを得る
		// このメソッドは LDR から供給されている
		NSArray * args = [NSArray arrayWithObjects:[NSNumber numberWithBool:YES], nil];
		id item = [wso callWebScriptMethod:@"get_active_item" withArguments:args];
		D(@"get_active_item result=%@", SafetyDescription(item));
		if (item != nil) {
			// id を得る
			NSString * element_id = [item valueForKey:@"id"];
			D(@"  id=%@", element_id);
			if (element_id != nil) {
				// item_body_XXX な要素を DOMNode オブジェクトとして得るために '$' メソッドを通す
				args = [NSArray arrayWithObjects:[NSString stringWithFormat:@"item_body_%@", element_id], nil];
				itemBody = [wso callWebScriptMethod:@"$" withArguments:args];
				D(@"itemBody result=%@", SafetyDescription(itemBody));
				D(@"  className=%@", [itemBody className]);
				D(@"  idName=%@", [itemBody idName]);
			}
		}

		if (itemBody != nil) {
			// @class=item_body な div からの相対
			NSArray * expressions = [NSArray arrayWithObjects:
				  @"./div[@class=\"body\"]/img"
				, @"./div[@class=\"body\"]"
				, nil
				];
			element = [DelivererContext evaluate:expressions document:document contextNode:itemBody];
		}
	}
	@catch (NSException * e) {
		D0([e description]);
	}

	return element;
}

+ (NSString *)name
{
	return @"LDR";
}

/// LDRのエントリに存在する item_count を持つ要素を得る
+ (NSString *)entryNodeExpression
{
	return @"ancestor-or-self::div[starts-with(@id,\"item_count\")]";
}

- (NSString *)titleWithNode:(DOMNode *)targetNode
{
	static NSString * xpath = @"./div[@class=\"item_header\"]//a/text()";

	NSString * title = [self evaluateWithXPathExpression:xpath target:targetNode];
	if (title == nil) title = @"(no title)";
	return title;
}

- (NSString *)sourceWithNode:(DOMNode *)targetNode
{
#pragma unused (targetNode)
	static NSString * xpath = @"id(\"right_body\")/div[@class=\"channel\"]//a/text()";

	@try {
		DOMXPathResult * result = [self evaluateToDocument:xpath contextNode:document_ type:DOM_STRING_TYPE inResult:nil];

		[[self class] dump:result];

		if (result != nil && [result resultType] == DOM_STRING_TYPE) {
			return [result stringValue];
		}
	}
	@catch (NSException * e) {
		D0([e description]);
	}

	return @"(no source)";
}

- (NSString *)URLWithNode:(DOMNode *)targetNode
{
	static NSString * xpath = @"(div[@class=\"item_info\"]/a)[1]/@href";

	@try {
		DOMXPathResult * result = [self evaluateToDocument:xpath contextNode:targetNode type:DOM_ANY_TYPE inResult:nil];
		[[self class] dump:result];

		if (result != nil && [result resultType] == DOM_UNORDERED_NODE_ITERATOR_TYPE && ![result invalidIteratorState]) {
			for (DOMNode * node = [result iterateNext]; node != nil; node = [result iterateNext]) {
				D(@"%@ type=%d value=%@ textContent=%@", [node nodeName], [node nodeType], [node nodeValue], [node textContent]);
				return [node textContent];
			}
		}
	}
	@catch (NSException * e) {
		D0([e description]);
	}

	return @"(no URL)";
}
@end
