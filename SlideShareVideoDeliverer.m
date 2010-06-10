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
#import "Log.h"
#import <WebKit/DOMHTMLObjectElement.h>
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLObjectElement.h

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

@implementation SlideShareVideoDeliverer
/**
 * Deliverer のファクトリ
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	V(@"clickedElement:%@", [clickedElement description]);

	id node = [clickedElement objectForKey:WebElementDOMNodeKey];
	if (node == nil) {
		return nil;
	}

	V(@"DOMNode:%@", [node description]);

	/* check URL's host */
	NSURL* url = [NSURL URLWithString:[[document URL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ([[url host] hasSuffix:@"slideshare.net"] == NO) {
		return nil;
	}

	if ([[url path] length] == 0) {
		return nil;
	}

	/* create object */
	SlideShareVideoDeliverer* deliverer = nil;
	deliverer = [[SlideShareVideoDeliverer alloc] initWithDocument:document element:clickedElement];
	if (deliverer != nil) {
		return [deliverer retain]; //need?
	}
	Log(@"Could not alloc+init %@Deliverer.", [self name]);

	return deliverer;
}

/**
 * MenuItemのタイトルを返す
 */
- (NSString*) titleForMenuItem
{
	return [NSString stringWithFormat:@"%@ - SlideShare", [SlideShareVideoDeliverer name]];
}

/**
 * makeContextForVimeo FIXME: SlideShareだってばよ
 */
- (NSDictionary*) makeContextForVimeo
{
	static NSString* XPathForTitle = @"//div[@class=\"right_group\"]/div[@class=\"slideProfile\" and position() = 1]/div[@class=\"zingedright\"]/h3";
	static NSString* XPathForUserName = @"//div[@class=\"right_group\"]/div[@class=\"slideProfile\" and position() = 1]/div[@class=\"zingedright\"]/p/a[@class=\"blue_link_normal\"]";
	static NSString* XPathForEmbed = @"//div[@id=\"slideView_swf\"]/embed";

	DOMNode* clickedNode = [clickedElement_ objectForKey:WebElementDOMNodeKey];
	if (clickedNode == nil) {
		V(@"clickedNode not found: %@", clickedElement_);
		return nil;
	}

	DOMXPathResult* result;
	DOMHTMLAnchorElement* anchor = nil;
	NSString* title = nil;
	NSString* obj = nil;

	/* title */
	result = [context_ evaluateToDocument:XPathForTitle contextNode:clickedNode type:DOM_ANY_TYPE inResult:nil];
	if (result != nil && ![result invalidIteratorState]) {
		V(@"result(title):%@", [result description]);
		DOMNode* node;
		for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			V(@"node(title): class=%@ name=%@ type=%d text=%@", [node className], [node nodeName], [node nodeType], [node textContent]);
			title = [node textContent];
			break;
		}
	}
	if (title == nil) {
		V(@"Failed XPath for Title. XPathResult: %@", SafetyDescription(result));
		return nil;
	}
	title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	/* username */
	result = [context_ evaluateToDocument:XPathForUserName contextNode:clickedNode type:DOM_ANY_TYPE inResult:nil];
	if (result != nil && ![result invalidIteratorState]) {
		V(@"result:%@", [result description]);
		DOMNode* node;
		for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			V(@"node: name=%@ type=%d text=%@", [node nodeName], [node nodeType], [node textContent]);
			V(@"node: description=%@ respondsToSelector=%d", [node description], [node respondsToSelector:@selector(absoluteLinkURL)]);
			if ([node respondsToSelector:@selector(absoluteLinkURL)]) {
				anchor = (DOMHTMLAnchorElement*)node;
				break;
			}
		}
	}
	if (anchor == nil) {
		V(@"Failed XPath for Username. XPathResult: %@", SafetyDescription(result));
		return nil;
	}
	NSString* caption =
	 	[NSString stringWithFormat:@"%@ (via %@)",
						[DelivererRules anchorTagWithName:[context_ documentURL] name:title],
						[DelivererRules anchorTagWithName:[[anchor absoluteLinkURL] absoluteString] name:[anchor textContent]]];
	V(@"caption: [%@]", caption);

	/* object */
	result = [context_ evaluateToDocument:XPathForEmbed contextNode:clickedNode type:DOM_ANY_TYPE inResult:nil];
	if (result != nil && ![result invalidIteratorState]) {
		V(@"result(obj):%@", [result description]);
		DOMNode* node;
		for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			DOMHTMLObjectElement* domObj = (DOMHTMLObjectElement*)node;
			V(@"node(obj): class=%@ name=%@ type=%d outerHTML=%@", [domObj className], [domObj nodeName], [domObj nodeType], [domObj outerHTML]);
			obj = [domObj outerHTML];
			break;
		}
	}
	if (obj == nil) {
		V(@"Failed XPath for Embed. XPathResult: %@", SafetyDescription(result));
		return nil;
	}

	NSMutableDictionary* context = [[[NSMutableDictionary alloc] init] autorelease];
	[context setValue:obj forKey:@"embed"];
	[context setValue:caption forKey:@"caption"];
	[context setValue:@"" forKey:@"title"]; /* title は未サポート */

	return context;
}

/**
 * メニューのアクション
 */
- (void) action:(id)sender
{
#pragma unused (sender)
	@try {
		NSDictionary* context = [self makeContextForVimeo];
		if (context != nil) {
			[super postVideo:[context objectForKey:@"embed"]
								 title:[context objectForKey:@"title"]
							 caption:[context objectForKey:@"caption"]];
		}
	}
	@catch (NSException* e) {
		[self failedWithException:e];
	}
}
@end
