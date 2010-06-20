/**
 * @file ReblogDeliverer.m
 * @brief ReblogDeliverer class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLIFrameElement.h
#import "ReblogDeliverer.h"
#import "DelivererRules.h"
#import "NSString+Tumblrful.h"
#import "GrowlSupport.h"
#import "DebugLog.h"

static NSString * TYPE = @"Reblog";

#pragma mark -
@implementation ReblogDeliverer

@synthesize postID = postID_;
@synthesize reblogKey = reblogKey_;

+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	NSDictionary * tokens = [ReblogDeliverer reblogTokensFromIFrame:document];
	if (tokens == nil) return nil;

	ReblogDeliverer * deliverer = [[ReblogDeliverer alloc] initWithDocument:document target:clickedElement postID:[tokens objectForKey:@"pid"] reblogKey:[tokens objectForKey:@"rk"]];
	if (deliverer == nil) {
		D(@"Could not alloc+init %@Deliverer.", TYPE);
	}

	return deliverer;
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement postID:(NSString *)postID reblogKey:(NSString *)reblogKey
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
		if (postID != nil) postID_ = [postID retain];
		if (reblogKey != nil) reblogKey_ = [reblogKey retain];
	}
	return self;
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement postID:(NSString *)postID
{
	return [self initWithDocument:document target:targetElement postID:postID reblogKey:nil];
}

- (id)initWithContext:(DelivererContext *)context postID:(NSString *)postID reblogKey:(NSString *)reblogKey
{
	if ((self = [super initWithContext:context]) != nil) {
		if (postID != nil) postID_ = [postID retain];
		if (reblogKey != nil) reblogKey_ = [reblogKey retain];
	}
	return self;
}

- (id)initWithContext:(DelivererContext *)context postID:(NSString *)postID
{
	return [self initWithContext:context postID:postID reblogKey:nil];
}

- (void)dealloc
{
	[postID_ release], postID_ = nil;
	[reblogKey_ release], reblogKey_ = nil;

	[super dealloc];
}

- (NSString *)postType
{
	return [TYPE lowercaseString];
}

- (NSString *)titleForMenuItem
{
	return TYPE;
}

- (void)action:(id)sender
{
#pragma unused (sender)
	@try {
		NSDictionary * params = [NSDictionary dictionaryWithObjectsAndKeys:postID_, @"pid", reblogKey_, @"rk", nil];
		D(@"params=%@", [params description]);
		[self postEntry:params];
	}
	@catch (NSException * e) {
		D0([e description]);
	}
}

+ (NSDictionary *)reblogTokensFromIFrame:(DOMHTMLDocument *)document
{
	static NSString * XPath = @"//iframe[@id='tumblr_controls']";

	DOMXPathResult * result = [document evaluate:XPath contextNode:document resolver:nil type:DOM_ANY_TYPE inResult:nil];

	if (result != nil && ![result invalidIteratorState]) {
		DOMHTMLIFrameElement * iframe = (DOMHTMLIFrameElement *)[result iterateNext];
		NSString * src = [[iframe getAttribute:@"src"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if (src != nil) {
			D(@"src=%@", src);
			NSURL * u = [NSURL URLWithString:src];
			NSDictionary * tokens = [[u query] dictionaryWithKVPConnector:@"=" withSeparator:@"&"];
			D(@"tokens=%@", [tokens description]);
			return tokens;
		}
		else {
			D0([iframe description]);
			D0([iframe innerHTML]);
			D0([iframe outerHTML]);
		}
	}
	else {
		D0([result description]);
	}
	return nil;
}

#pragma mark -
#pragma mark Override Methods

- (void)successed:(NSString *)response
{
#pragma unused (response)
	D(@"self.retainCount=%x", [self retainCount]);

	@try {
		NSString * message = [NSString stringWithFormat:@"%@\nPost ID: %@", context_.documentTitle, postID_];
		[self notify:message];
	}
	@catch (NSException * e) {
		D0([e description]);
	}
}

- (void)notify:(NSString *)message
{
	NSString * typeDescription = [NSString stringWithFormat:@"%@", [[self postType] capitalizedString]];
	[GrowlSupport notifyWithTitle:typeDescription description:message];
}
@end
