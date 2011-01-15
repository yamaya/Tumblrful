/**
 * @file:   VideoDeliverer.m
 * @brief:	VideoDeliverer implementation
 * @author:	Masayuki YAMAYA
 * @date:   2008-03-03
 * Last Change:	2008-10-13 20:21.
 */
#import "VideoDeliverer.h"
#import "DelivererRules.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"
#import <WebKit/DOMHTMLAnchorElement.h>

static NSString * TYPE = @"Video";

#pragma mark -
@implementation VideoDeliverer

+ (NSString *)name
{
	return TYPE;
}

+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	D(@"clickedElement:%@", [clickedElement description]);

	id node = [clickedElement objectForKey:WebElementDOMNodeKey];
	if (node == nil) {
		return nil;
	}

	D(@"DOMNode:%@", [node description]);

	// check URL's host
	NSURL * url = [NSURL URLWithString:[[document URL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ([[url host] hasSuffix:@"youtube.com"] == NO) {
		return nil;
	}
	NSRange range = [[url path] rangeOfString:@"/watch"];
	if (range.location == NSNotFound) {
		return nil;
	}

	// create object
	VideoDeliverer * deliverer = [[VideoDeliverer alloc] initWithDocument:document target:clickedElement];
	if (deliverer == nil)
		D(@"Could not alloc+init %@Deliverer.", [self name]);

	return deliverer;
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)clickedElement
{
	if ((self = [super initWithDocument:document target:clickedElement]) != nil) {
		clickedElement_ = [clickedElement retain];
	}
	return self;
}

- (void)dealloc
{
	[clickedElement_ release], clickedElement_ = nil;

	[super dealloc];
}

- (NSString *)postType
{
	return [TYPE lowercaseString];
}

- (NSString *)titleForMenuItem
{
	return [NSString stringWithFormat:@"%@ - Youtube", TYPE];
}

- (void)action:(id)sender
{
#pragma unused (sender)
	@try {
		NSString * url;
		NSString * caption;
		NSDictionary * contents = [self videoContents];
		if (contents != nil) {
			url = [contents objectForKey:@"source"];
			caption = [contents objectForKey:@"caption"];
		}
		else {
			url = context_.documentURL;
			caption = nil;
		}
		[super postVideo:url caption:caption];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithException:e];
	}
}

- (NSDictionary *)videoContents
{
	static NSString * XPathForTitle = @"//div[@id='watch-headline']/h1[@id='watch-headline-title']";
//	static NSString * XPathForURL = @"//input[@class='watch-actions-share-input']";
	static NSString * XPathForURL = @"//input[@name='video_id']";
	static NSString * XPathForUserName = @"//div[@id='watch-headline-user-info']/a[@id='watch-username']";

	DOMNode * clickedNode = [clickedElement_ objectForKey:WebElementDOMNodeKey];
	if (clickedNode == nil) {
		D(@"clickedNode not found: %@", clickedElement_);
		return nil;
	}

	DOMXPathResult * result;
	DOMHTMLAnchorElement * user = nil;
	NSString * title = nil;
	NSString * url = nil;

	// title
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
	if (title != nil) {
		title = [title stringByTrimmingWhitespace];
	}
	else {
		D(@"Failed XPath for Title. XPathResult:%@", SafetyDescription(result));
		return nil;
	}

	// URL
	result = [context_ evaluateToDocument:XPathForURL contextNode:clickedNode type:DOM_ANY_TYPE inResult:nil];
	if (result != nil && ![result invalidIteratorState]) {
		D(@"result(URL):%@", [result description]);
		DOMNode* node;
		for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			D(@"node(title): class=%@ name=%@ type=%d text=%@", [node className], [node nodeName], [node nodeType], [node textContent]);
			DOMElement* element = (DOMElement*)node;
			url = [NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", [element getAttribute:@"value"]];
			break;
		}
	}
	if (url == nil) {
		D(@"Failed XPath for URL. XPathResult: %@", SafetyDescription(result));
		return nil;
	}

	// username
	result = [context_ evaluateToDocument:XPathForUserName contextNode:clickedNode type:DOM_ANY_TYPE inResult:nil];
	if (result != nil && ![result invalidIteratorState]) {
		D0([result description]);
		for (DOMNode * node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			D(@"node: name=%@ type=%d text=%@", [node nodeName], [node nodeType], [node textContent]);
			D(@"node: description=%@ respondsToSelector=%d", [node description], [node respondsToSelector:@selector(absoluteLinkURL)]);
			if ([node respondsToSelector:@selector(absoluteLinkURL)]) {
				user = (DOMHTMLAnchorElement *)node;
				break;
			}
		}
	}
	if (user == nil) {
		D(@"Failed XPath for Username. XPathResult:%@", SafetyDescription(result));
		return nil;
	}

	NSString * caption = [NSString stringWithFormat:@"%@ (via %@)",
		[DelivererRules anchorTagWithName:url name:title],
		[DelivererRules anchorTagWithName:[[user absoluteLinkURL] absoluteString] name:[user textContent]]];

	return [NSDictionary dictionaryWithObjectsAndKeys:url, @"source", caption, @"caption", nil];
}

@end

