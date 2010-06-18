/**
 * @file DelivererContext.m
 * @brief DelivererContext class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLDocument.h
// /System/Library/Frameworks/WebKit.framework/Headers/DOMDocument.h
#import "DelivererContext.h"
#import "DelivererRules.h"
#import "DebugLog.h"
#import <WebKit/DOMHTMLDocument.h>

@implementation DelivererContext

@synthesize document = document_;
@dynamic documentTitle;
@dynamic documentURL;
@dynamic anchorToDocument;
@dynamic menuTitle;

+ (BOOL)match:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
#pragma unused (document, targetElement)
	return YES; // 常に真
}

+ (DOMHTMLElement *)matchForAutoDetection:(DOMHTMLDocument*)document windowScriptObject:(WebScriptObject*)window;
{
#pragma unused (document, window)
	return nil; // 常に nil
}

+ (DOMHTMLElement *)evaluate:(NSArray *)expressions document:(DOMHTMLDocument *)document contextNode:(DOMNode *)contextNode
{
	DOMHTMLElement * element = nil;

	@try {
		// とりあえず photo優先で調べてみる
		// img で失敗したら reblogにまわしてみるために item-body までの XPath
		// DOMHTMLEmement を得てみる
		size_t N = [expressions count];
		size_t i;
		for (i = 0; i < N && element == nil; ++i) {
			NSString* expr = [expressions objectAtIndex:i];
			DOMXPathResult* xpresult = [document evaluate:expr contextNode:contextNode resolver:nil type:DOM_ANY_TYPE inResult:nil];
			D(@"XPathResult: %@ %d/%d", SafetyDescription(xpresult), i, N);
			if (xpresult != nil) {
				DOMNode* node = nil;
				while (![xpresult invalidIteratorState]) {
					node = [xpresult iterateNext];
					D(@"XPathResult's node: %@ %d/%d", SafetyDescription(node), i, N);
					if (node != nil) {
						if ([node isKindOfClass:[DOMHTMLElement class]]) {
							element = (DOMHTMLElement*)node;
							break;
						}
					}
					else {
						break;
					}
				}
			}
		}
	}
	@catch (NSException* e) {
		D(@"Exception: %@", [e description]);
		element = nil;
	}

	return element;
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
#pragma unused (targetElement)
	if ((self = [super init]) != nil) {
		document_ = [document retain];
	}
	return self;
}

- (void)dealloc
{
	[document_ release], document_ = nil;

	[super dealloc];
}

- (NSString *)documentTitle
{
	return [document_ title];
}

- (NSString *)documentURL
{
	return [document_ URL];
}

- (NSString *)anchorToDocument
{
	return [DelivererRules anchorTagWithName:self.documentURL name:self.documentTitle];
}

- (NSString *)menuTitle
{
	return @"";
}

- (DOMXPathResult *)evaluateToDocument:(NSString*)expression contextNode:(DOMNode *)contextNode type:(unsigned short)type inResult:(DOMXPathResult *)inResult
{
	// nil for HTML document
	return [document_ evaluate:expression contextNode:contextNode resolver:nil type:type inResult:inResult];
}
@end
