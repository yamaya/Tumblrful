/**
 * @file ReblogDeliverer.m
 * @brief ReblogDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLIFrameElement.h
#import "ReblogDeliverer.h"
#import "DelivererRules.h"
#import "GrowlSupport.h"
#import "Log.h"

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

static NSString* TYPE = @"Reblog";

#pragma mark -
@implementation ReblogDeliverer
/**
 * IFrameが存在するか調べる
 */
+ (NSDictionary*) tokensFromIFrame:(DOMHTMLDocument*)document
{
	static NSString* IFRAME_ID = @"tumblr_controls";

	V(@"tokensFromIFrame: document=%@", SafetyDescription(document));

	/* document content から iframe を探す */
	DOMElement* element = [document getElementById:IFRAME_ID];
	V(@"tokensFromIFrame: element=%@", SafetyDescription(element));
	if (element == nil) {
		return nil;
	}

	NSDictionary* tokens = nil;
	DOMHTMLIFrameElement* iframe = (DOMHTMLIFrameElement*)element;
	/*
	 * <iframe
	 *	src="http://www.tumblr.com/dashboard/iframe?src=http://suwaowalog.tumblr.com/post/31541959&pid=31541959&rk=2e9uZXxz"
	 *	id="tumblr_controls">
	 * </iframe>
	 */
	NSString* src = [[iframe src] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	V(@"iframe src=%@", src);
	NSRange range = [src rangeOfString:@"&pid="];
	if (range.location != NSNotFound) {
		NSString* segmentString = [src substringFromIndex:range.location + 1];
		V(@"segmentString=%@", segmentString);
		NSArray* segments = [segmentString componentsSeparatedByString:@"&"];
		NSEnumerator* enumerator = [segments objectEnumerator];
		NSString* segment;
		tokens = [[[NSMutableDictionary alloc] init] autorelease];
		while ((segment = [enumerator nextObject]) != nil) {
			range = [segment rangeOfString:@"pid="];
			if (range.location != NSNotFound) { /* post id */
				[tokens setValue:[segment substringFromIndex:range.location + range.length] forKey:@"pid"];
				continue;
			}
			range = [segment rangeOfString:@"rk="];
			if (range.location != NSNotFound) { /* rk */
				[tokens setValue:[segment substringFromIndex:range.location + range.length] forKey:@"rk"];
				continue;
			}
		}
		V(@"tokens=%@", [tokens description]);
	}
	return tokens;
}

/**
 * Deliverer のファクトリ
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	ReblogDeliverer* deliverer = nil;

	NSDictionary* tokens = [ReblogDeliverer tokensFromIFrame:document];
	if (tokens == nil) {
		return nil;
	}
	deliverer = [[ReblogDeliverer alloc] initWithDocument:document target:clickedElement postID:[tokens objectForKey:@"pid"] reblogKey:[tokens objectForKey:@"rk"]];
	if (deliverer != nil) {
		[deliverer retain];	//TODO: need?
	}
	else {
		V(@"Could not alloc+init %@Deliverer.", TYPE);
	}
	return deliverer;
}

/**
 * オブジェクトを初期化する
 */
- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement postID:(NSString*)postID reblogKey:(NSString*)rk
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
		type_ = nil;
		postID_ = [postID retain];
		if (rk != nil) {
			reblogKey_ = [rk retain];
		}
		else {
			reblogKey_ = nil;
		}
		V(@"initWith) postID:%@", postID_);
	}
	return self;
}

/**
 * オブジェクトの解放
 */
- (void) dealloc
{
	if (postID_ != nil) {
		[postID_ release];
		postID_ = nil;
	}
	if (reblogKey_ != nil) {
		[reblogKey_ release];
		reblogKey_ = nil;
	}
	if (type_ != nil) {
		[type_ release];
		type_ = nil;
	}

	[super dealloc];
}

/**
 * Tumblr APIが規定するポストのタイプ
 */
- (NSString*) postType
{
	return type_;
}

- (NSString*) titleForMenuItem
{
	return TYPE; /* この時点では type_ は nil なので使えないんだな */
}

/**
 * メニューのアクション
 *	@param sender アクションを起こしたオブジェクト
 */
- (void) action:(id)sender
{
#pragma unused (sender)
	[self reblog];
}

- (void) reblog
{
	NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:postID_, @"pid", reblogKey_, @"rk", nil];
	V(@"params=%@", [params description]);
	type_ = (NSString*)[self postEntry:params];
}

/**
 * PostID を設定する.
 *	@param postID ポストID
 */
- (void) setPostID:(NSString*)postID
{
	if (postID_ != nil) [postID_ release];
	postID_ = [postID retain];
}

/**
 * ReblogKey を設定する.
 *	@param reblogKey Reblogキー
 */
- (void) setReblogKey:(NSString*)reblogKey
{
	if (reblogKey_ != nil)
		[reblogKey_ release];
	reblogKey_ = [reblogKey retain];
}

#pragma mark -
/**
 * ポストが成功した時
 */
- (void) posted:(NSData *)responseData
{
#pragma unused (responseData)
	V(@"posted) retain=%x", [self retainCount]);

	@try {
		NSString* message = [NSString stringWithFormat:@"%@\nPost ID: %@", [context_ documentTitle], postID_];
		[self notify:message];
	}
	@catch(NSException* e) {
		Log([e description]);
	}
}

/**
 * 汎用メッセージ処理
 */
- (void) notify:(NSString*)message
{
	NSString* typeDescription = [NSString stringWithFormat:@"%@ %@", TYPE, [[self postType] capitalizedString]];
	[GrowlSupport notify:typeDescription description:message];
}
@end
