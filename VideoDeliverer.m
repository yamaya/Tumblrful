/**
 * @file:   VideoDeliverer.m
 * @brief:	VideoDeliverer implementation
 * @author:	Masayuki YAMAYA
 * @date:   2008-03-03
 * Last Change:	2008-10-13 20:21.
 */
#import "VideoDeliverer.h"
#import "DelivererRules.h"
#import "Log.h"
#import <WebKit/DOMHTMLAnchorElement.h>

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

static NSString* TYPE = @"Video";

#pragma mark -
@implementation VideoDeliverer
/**
 * Deliverer の名前
 */
+ (NSString*) name
{
	return TYPE;
}

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
	if ([[url host] hasSuffix:@"youtube.com"] == NO) {
		return nil;
	}
	NSRange range = [[url path] rangeOfString:@"/watch"];
	if (range.location == NSNotFound) {
		return nil;
	}

	/* create object */
	VideoDeliverer* deliverer = nil;
	deliverer = [[VideoDeliverer alloc] initWithDocument:document element:clickedElement];
	if (deliverer != nil) {
		return [deliverer retain]; //need?
	}
	Log(@"Could not alloc+init %@Deliverer.", [self name]);

	return deliverer;
}

/**
 * オブジェクトを初期化する
 */
- (id) initWithDocument:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	if ((self = [super initWithDocument:document target:clickedElement]) != nil) {
		clickedElement_ = [clickedElement retain];
	}
	return self;
}

/**
 * オブジェクトの解放
 */
- (void) dealloc
{
	[clickedElement_ release];
	[super dealloc];
}

/**
 * Tumblr APIが規定するポストのタイプ
 */
- (NSString*) postType
{
	return [TYPE lowercaseString];
}

/**
 * MenuItemのタイトルを返す
 */
- (NSString*) titleForMenuItem
{
	return [NSString stringWithFormat:@"%@ - Youtube", TYPE];
}

/**
 * メニューのアクション
 */
- (void) action:(id)sender
{
	@try {
		[super postVideo:[context_ documentURL]
							 title:[context_ documentTitle]
						 caption:[self makeCaption]];
	}
	@catch (NSException* e) {
		[self failedWithException:e];
	}
}

/**
 * makeCaption
 * (via {username の a tag})
 */
- (NSString*) makeCaption
{
	static NSString* XPathForTitle = @"//div[@id=\"watch-vid-title\"]/h1";
	static NSString* XPathForURL = @"//input[@name=\"video_link\"]";
	static NSString* XPathForUserName = @"//div[@id=\"watch-channel-stats\"]/a";

	DOMNode* clickedNode = [clickedElement_ objectForKey:WebElementDOMNodeKey];
	if (clickedNode == nil) {
		V(@"clickedNode not found: %@", clickedElement_);
		return nil;
	}

	DOMXPathResult* result;
	DOMHTMLAnchorElement* anchor = nil;
	NSString* title = nil;
	NSString* url = nil;

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

	/* URL */
	result = [context_ evaluateToDocument:XPathForURL
									contextNode:clickedNode
												 type:DOM_ANY_TYPE
										 inResult:nil];
	if (result != nil && ![result invalidIteratorState]) {
		V(@"result(URL):%@", [result description]);
		DOMNode* node;
		for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			V(@"node(title): class=%@ name=%@ type=%d text=%@", [node className], [node nodeName], [node nodeType], [node textContent]);
			DOMElement* element = (DOMElement*)node;
			url = [element getAttribute:@"value"];
			break;
		}
	}
	if (title == nil) {
		V(@"Failed XPath for URL. XPathResult: %@", SafetyDescription(result));
		return nil;
	}

	/* username */
	result = [context_ evaluateToDocument:XPathForUserName
									contextNode:clickedNode
												 type:DOM_ANY_TYPE
										 inResult:nil];
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

	return [NSString stringWithFormat:@"%@ (via %@)",
						[DelivererRules anchorTagWithName:url name:title],
						[DelivererRules anchorTagWithName:[[anchor absoluteLinkURL] absoluteString] name:[anchor textContent]]];
}

@end
