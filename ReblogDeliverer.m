/**
 * @file ReblogDeliverer.m
 * @brief ReblogDeliverer class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLIFrameElement.h
#import "ReblogDeliverer.h"
#import "DelivererRules.h"
#import "GrowlSupport.h"
#import "DebugLog.h"

static NSString * TYPE = @"Reblog";

@interface ReblogDeliverer ()
+ (NSDictionary *)reblogTokensFromIFrame:(DOMHTMLDocument *)document;
@end

#pragma mark -
@implementation ReblogDeliverer

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
		D(@"postID:%@", postID_);
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
		D(@"postID:%@", postID_);
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
	static NSString* IFRAME_ID = @"tumblr_controls";

	D(@"document=%@", SafetyDescription(document));

	// document content から iframe を探す
	DOMElement * element = [document getElementById:IFRAME_ID];
	D(@"element=%@", SafetyDescription(element));
	if (element == nil) {
		return nil;
	}

	NSMutableDictionary * tokens = nil;
	DOMHTMLIFrameElement * iframe = (DOMHTMLIFrameElement *)element;
	/*
	 * <iframe
	 *	src="http://www.tumblr.com/dashboard/iframe?src=http://suwaowalog.tumblr.com/post/31541959&pid=31541959&rk=2e9uZXxz"
	 *	id="tumblr_controls">
	 * </iframe>
	 */
	NSString * src = [[iframe src] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	D(@"iframe src=%@", src);
	NSRange range = [src rangeOfString:@"&pid="];
	if (range.location != NSNotFound) {
		NSString * segmentString = [src substringFromIndex:range.location + 1];
		D(@"segmentString=%@", segmentString);
		NSArray * segments = [segmentString componentsSeparatedByString:@"&"];
		NSEnumerator * enumerator = [segments objectEnumerator];
		NSString * segment;
		tokens = [[[NSMutableDictionary alloc] init] autorelease];
		while ((segment = [enumerator nextObject]) != nil) {
			range = [segment rangeOfString:@"pid="];
			if (range.location != NSNotFound) { // post id
				[tokens setObject:[segment substringFromIndex:range.location + range.length] forKey:@"pid"];
				continue;
			}
			range = [segment rangeOfString:@"rk="];
			if (range.location != NSNotFound) { // rk
				[tokens setObject:[segment substringFromIndex:range.location + range.length] forKey:@"rk"];
				continue;
			}
		}
		D(@"tokens=%@", [tokens description]);
	}
	return tokens;
}

- (void)setPostID:(NSString *)postID
{
	[postID_ release];
	postID_ = [postID retain];
}

- (void)setReblogKey:(NSString *)reblogKey
{
	[reblogKey_ release];
	reblogKey_ = [reblogKey retain];
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
