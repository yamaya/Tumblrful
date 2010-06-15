/**
 * @file GoogleReaderDelivererContext.m
 * @brief GoogleReaderDelivererContext class implementation
 * @author Masayuki YAMAYA
 * @date 2008-11-16
 */
#import "GoogleReaderDelivererContext.h"
#import "DebugLog.h"
#import <WebKit/DOM.h>
#import <WebKit/WebView.h>

static NSString * GOOGLEREADER_HOSTNAME	= @"www.google.com";
static NSString * GOOGLEREADER_PATH		= @"/reader/view";

@interface GoogleReaderDelivererContext ()
+ (BOOL)siteMatchWithURL:(NSString *)URL;
- (NSString *)titleWithNode:(DOMNode *)targetNode;
- (NSString *)sourceWithNode:(DOMNode *)targetNode;
- (NSString *)URLWithNode:(DOMNode *)targetNode;
@end

@implementation GoogleReaderDelivererContext

+ (BOOL)siteMatchWithURL:(NSString *)URL
{
	NSURL * url = [NSURL URLWithString:URL];
	if (url != nil) {
		if ([[url host] isEqualToString:GOOGLEREADER_HOSTNAME]) {
			if ([[url path] hasPrefix:GOOGLEREADER_PATH]) {
				return YES;
			}
		}
	}
	return NO;
}

+ (BOOL)match:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
	if ([self siteMatchWithURL:[document URL]]) {
		if ([self entryNodeWithDocument:document target:targetElement] != nil) {
			D0(@"matched");
			return YES;
		}
	}
	D0(@"mismatched");
	return NO;
}

+ (DOMHTMLElement *)matchForAutoDetection:(DOMHTMLDocument *)document windowScriptObject:(WebScriptObject *)wso;
{
#pragma unused (wso)
	DOMHTMLElement * element = nil;

	if ([self siteMatchWithURL:[document URL]]) {
		NSArray * expressions = [NSArray arrayWithObjects:
			  @"//div[@id=\"current-entry\"]//div[@class=\"item-body\"]//img"
			, @"//div[@id=\"current-entry\"]//div[@class=\"item-body\"]"
			, nil
			];
		element = [DelivererContext evaluate:expressions document:document contextNode:document];
	}

	return element;
}

+ (NSString *)name
{
	return @"Google Reader";
}

/// フィードエントリとその情報(Authorとか)を含む最も内側の div要素を得る
+ (NSString *)entryNodeExpression
{
	return @"ancestor-or-self::div[@class=\"entry-main\"]";
}

#pragma mark -
#pragma mark Private Methods


/// フィードエントリのタイトルを得る
- (NSString *)titleWithNode:(DOMNode *)targetNode
{
	static NSString * xpath = @"./h2[@class=\"entry-title\"]//a/text()";

	NSString * title = [self evaluateWithXPathExpression:xpath target:targetNode];
	if (title == nil) title = @"(no title)";
	return title;
}

/// フィードソース名(サイト名)を得る
- (NSString *)sourceWithNode:(DOMNode *)targetNode
{
	static NSString * xpath = @"./div[@class=\"entry-author\"]//a/text()";

	NSString * source = [self evaluateWithXPathExpression:xpath target:targetNode];
	if (source == nil) source = @"(no source)";
	return source;
}

/// 元記事へのURLを得る
- (NSString *)URLWithNode:(DOMNode *)targetNode
{
	static NSString * xpath = @"./h2[@class=\"entry-title\"]//a/@href";

	@try {
		DOMXPathResult * result = [self evaluateToDocument:xpath contextNode:targetNode type:DOM_ANY_TYPE inResult:nil];
		[[self class] dump:result];

		if (result != nil && [result resultType] == DOM_UNORDERED_NODE_ITERATOR_TYPE && ![result invalidIteratorState]) {
			for (DOMNode * node = [result iterateNext]; node != nil; node = [result iterateNext]) {
				D(@"name=%@ type=%d value=%@ textContent=%@", [node nodeName], [node nodeType], [node nodeValue], [node textContent]);
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
