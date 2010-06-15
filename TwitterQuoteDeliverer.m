/**
 * @file TwitterQuoteDeliverer.m
 */
#import "TwitterQuoteDeliverer.h"
#import "NSString+Tumblrful.h"
#import "DelivererRules.h"
#import "DebugLog.h"

static NSString * TWITTER_HOSTNAME = @"twitter.com";

@interface TwitterQuoteDeliverer ()
- (NSDictionary *)contentsFromTwitterStatus;
@end

@implementation TwitterQuoteDeliverer
+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	DOMNode * clickedNode = [clickedElement objectForKey:WebElementDOMNodeKey];
	if (clickedNode == nil) return nil;

	// selectionされていたらここではやらない。通常quoteに回す
	id selected = [clickedElement objectForKey:WebElementIsSelectedKey];
	D(@"selected:%@", SafetyDescription(selected));
	if (selected != nil && CFBooleanGetValue((CFBooleanRef)selected)) return nil;

	NSURL * u = [NSURL URLWithString:[[document URL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ([[u host] hasSuffix:TWITTER_HOSTNAME] == NO) return nil;

	NSRange range = [[u path] rangeOfString:@"/status"];
	if (range.location == NSNotFound) return nil;

	TwitterQuoteDeliverer * deliverer = [[TwitterQuoteDeliverer alloc] initWithDocument:document target:clickedElement];
	if (deliverer == nil) {
		D(@"Could not alloc+init %@Deliverer.", [TwitterQuoteDeliverer className]);
	}

	return deliverer;
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
		clickedElement_ = [targetElement retain];
	}
	return self;
}

- (void)dealloc
{
	[clickedElement_ release];

	[super dealloc];
}

- (NSString *)titleForMenuItem
{
	return [NSString stringWithFormat:@"%@ - Twitter", [[self postType] capitalizedString]];
}

- (void)action:(id)sender
{
#pragma unused (sender)
	@try {
		NSDictionary * contents = [self contentsFromTwitterStatus];
		if (contents != nil) {
			[super postQuote:[contents objectForKey:@"quote"] source:[contents objectForKey:@"source"]];
		}
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithException:e];
	}
}

- (NSDictionary *)contentsFromTwitterStatus
{
	static NSString * XPathForQuote = @"(//span[@class=\"entry-content\"])[1]";

	DOMXPathResult * result = nil;
	NSString * quote = nil;
	NSString * source = nil;

	{	// quote text
		DOMNode * clickedNode = [clickedElement_ objectForKey:WebElementDOMNodeKey];
		result = [context_ evaluateToDocument:XPathForQuote contextNode:clickedNode type:DOM_ANY_TYPE inResult:nil];
		D0([result description]);
		if (result == nil || [result invalidIteratorState]) return nil;

		for (DOMNode * node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			D(@"class=%@ name=%@ type=%d text=%@", [node className], [node nodeName], [node nodeType], [node textContent]);
			quote = [node textContent];
			break;
		}
		if (quote == nil) return nil;

		quote = [quote stringByTrimmingWhitespace];
	}
	{	// source
		NSString * title = [context_ documentTitle];
		title = [title stringByTrimmingWhitespace];
		NSRange range = [title rangeOfString:@": "];
		if (range.location != NSNotFound) {
			title = [title substringToIndex:range.location];
		}
		source = [DelivererRules anchorTagWithName:[context_ documentURL] name:title];
	}

	return [NSDictionary dictionaryWithObjectsAndKeys:quote, @"quote", source, @"source", nil];
}
@end
