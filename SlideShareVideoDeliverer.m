/**
 * @file SlideShareVideoDeliverer.m
 * @brief SlideShareVideoDeliverer implementation class
 * @author Masayuki YAMAYA
 * @date 2008-05-15
 *
 * あんまり使わないけど、とりあえずいっとけという感じの SlideShare 対応
 */
#import "SlideShareVideoDeliverer.h"
#import "DelivererRules.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"
#import <WebKit/DOMHTMLObjectElement.h>
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLObjectElement.h

static NSString * SLIDESHARE_HOSTNAME = @"slideshare.net";

@implementation SlideShareVideoDeliverer

+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	D(@"clickedElement:%@", [clickedElement description]);

	id node = [clickedElement objectForKey:WebElementDOMNodeKey];
	if (node == nil) {
		return nil;
	}

	D(@"DOMNode:%@", [node description]);

	// check URL's host
	NSURL* url = [NSURL URLWithString:[[document URL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ([[url host] hasSuffix:SLIDESHARE_HOSTNAME] == NO) {
		return nil;
	}

	if ([[url path] length] == 0) {
		return nil;
	}

	// create object
	SlideShareVideoDeliverer * deliverer = [[SlideShareVideoDeliverer alloc] initWithDocument:document target:clickedElement];
	if (deliverer == nil) {
		D(@"Could not alloc+init %@Deliverer.", [self name]);
	}

	return deliverer;
}

- (NSString *)titleForMenuItem
{
	return [NSString stringWithFormat:@"%@ - SlideShare", [SlideShareVideoDeliverer name]];
}

- (NSDictionary *)contextForSlideShare
{
	static NSString * XPathForTitle = @"//div[@class=\"right_group\"]/div[@class=\"slideProfile\" and position() = 1]/div[@class=\"zingedright\"]/h3";
	static NSString * XPathForUserName = @"//div[@class=\"right_group\"]/div[@class=\"slideProfile\" and position() = 1]/div[@class=\"zingedright\"]/p/a[@class=\"blue_link_normal\"]";
	static NSString * XPathForEmbed = @"//div[@id=\"slideView_swf\"]/embed";

	DOMNode* clickedNode = [clickedElement_ objectForKey:WebElementDOMNodeKey];
	if (clickedNode == nil) {
		D(@"clickedNode not found: %@", clickedElement_);
		return nil;
	}

	DOMXPathResult* result;
	DOMHTMLAnchorElement* anchor = nil;
	NSString* title = nil;
	NSString* obj = nil;

	/* title */
	result = [context_ evaluateToDocument:XPathForTitle contextNode:clickedNode type:DOM_ANY_TYPE inResult:nil];
	if (result != nil && ![result invalidIteratorState]) {
		D(@"result(title):%@", [result description]);
		DOMNode* node;
		for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			D(@"node(title): class=%@ name=%@ type=%d text=%@", [node className], [node nodeName], [node nodeType], [node textContent]);
			title = [node textContent];
			break;
		}
	}
	if (title == nil) {
		D(@"Failed XPath for Title. XPathResult: %@", SafetyDescription(result));
		return nil;
	}
	title = [title stringByTrimmingWhitespace];

	/* username */
	result = [context_ evaluateToDocument:XPathForUserName contextNode:clickedNode type:DOM_ANY_TYPE inResult:nil];
	if (result != nil && ![result invalidIteratorState]) {
		D(@"result:%@", [result description]);
		DOMNode* node;
		for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			D(@"node: name=%@ type=%d text=%@", [node nodeName], [node nodeType], [node textContent]);
			D(@"node: description=%@ respondsToSelector=%d", [node description], [node respondsToSelector:@selector(absoluteLinkURL)]);
			if ([node respondsToSelector:@selector(absoluteLinkURL)]) {
				anchor = (DOMHTMLAnchorElement*)node;
				break;
			}
		}
	}
	if (anchor == nil) {
		D(@"Failed XPath for Username. XPathResult: %@", SafetyDescription(result));
		return nil;
	}
	NSString* caption =
	 	[NSString stringWithFormat:@"%@ (via %@)",
						[DelivererRules anchorTagWithName:context_.URLOfDocument name:title],
						[DelivererRules anchorTagWithName:[[anchor absoluteLinkURL] absoluteString] name:[anchor textContent]]];
	D(@"caption: [%@]", caption);

	/* object */
	result = [context_ evaluateToDocument:XPathForEmbed contextNode:clickedNode type:DOM_ANY_TYPE inResult:nil];
	if (result != nil && ![result invalidIteratorState]) {
		D(@"result(obj):%@", [result description]);
		DOMNode* node;
		for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			DOMHTMLObjectElement* domObj = (DOMHTMLObjectElement*)node;
			D(@"node(obj): class=%@ name=%@ type=%d outerHTML=%@", [domObj className], [domObj nodeName], [domObj nodeType], [domObj outerHTML]);
			obj = [domObj outerHTML];
			break;
		}
	}
	if (obj == nil) {
		D(@"Failed XPath for Embed. XPathResult: %@", SafetyDescription(result));
		return nil;
	}

	NSMutableDictionary* context = [[[NSMutableDictionary alloc] init] autorelease];
	[context setValue:obj forKey:@"embed"];
	[context setValue:caption forKey:@"caption"];
	[context setValue:@"" forKey:@"title"]; /* title は未サポート */

	return context;
}

- (void)action:(id)sender
{
#pragma unused (sender)
	@try {
		NSDictionary * context = [self contextForSlideShare];
		if (context != nil) {
			[super postVideo:[context objectForKey:@"embed"] caption:[context objectForKey:@"caption"]];
		}
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithException:e];
	}
}
@end
