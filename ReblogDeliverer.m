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
@interface ReblogDeliverer (Private)
#ifndef FIX20080412
+ (BOOL) existsIFrame:(DOMHTMLDocument*)document;
+ (NSArray*) makeXPathsWithURL:(NSString*)url;
+ (DOMNode*) findPermalink:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
#endif
@end

#pragma mark -
@implementation ReblogDeliverer (Private)
#ifndef FIX20080412
/**
 * IFrameが存在するか調べる
 */
+ (BOOL) existsIFrame:(DOMHTMLDocument*)document
{
	static NSString* IFRAME_ID = @"tumblr_controls";

	/* document content から iframe を探す */
	DOMElement* element = [document getElementById:IFRAME_ID];
	V(@"element=%@", SafetyDescription(element));

	return element != nil;
}

/**
 * XPath式を作る
 *
 * @note TWO の audio は試してない。ひょっとすると文字列違うかも。
 * starts-wtih(@class, "xfolkentry")にすれば一撃なんだけど、xfolkentryが
 * サイト固有だったらヤなので。
 * あと、xfolkentry なサイトは AutoPagerize で繋げたページの permalink が消
 * えているから、どうがんばっても post-idが取得できない。
 */
+ (NSArray*) makeXPathsWithURL:(NSString*)url
{
	static NSString* ONE = @"ancestor-or-self::div[starts-with(@class,\"post\")]//a[starts-with(@href,\"http://%@/post/\")]/@href";
	static NSString* TWO = @"ancestor-or-self::div[starts-with(@class,\"link\") or starts-with(@class,\"quote\") or starts-with(@class,\"photo\") or starts-with(@class,\"movie\") or starts-with(@class,\"audio\") or starts-with(@class,\"chat\") or starts-with(@class,\"normal-text\")]/following-sibling::p[starts-with(@class,\"permalink\")][1]/a[starts-with(@href,\"http://%@/post/\")]/@href";

	NSMutableArray* xpathes = [[NSMutableArray alloc] init];

	[xpathes addObject:[NSString stringWithFormat:ONE, [[NSURL URLWithString:url] host]]];
	[xpathes addObject:[NSString stringWithFormat:TWO, [[NSURL URLWithString:url] host]]];

	return xpathes;
}

/**
 * Reblog可能かどうかを "permalink" の存在で調べる
 */
+ (DOMNode*) findPermalink:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	@try {
		DOMNode* clickedNode = [clickedElement objectForKey:WebElementDOMNodeKey];
		if (clickedNode == nil) {
			V(@"DOMNode not found: %@", clickedElement);
			return NO;
		}

		if ([ReblogDeliverer existsIFrame:document]) {
			DOMXPathResult* result;

			/* XPath を順次試し、最初にヒットしたものを採用 */
			NSArray* xpathes = [ReblogDeliverer makeXPathsWithURL:[document URL]];
			NSEnumerator* enumerator = [xpathes objectEnumerator];
			NSString* xpath;
			while ((xpath = [enumerator nextObject]) != nil) {
				V(@"XPath: %@", xpath);

				result = [document evaluate:xpath
												contextNode:clickedNode
													 resolver:nil /* nil for HTML document */
															 type:DOM_ANY_TYPE
													 inResult:nil];

				if (result != nil) {
					V(@"invalidIteratorState=%d", [result invalidIteratorState]);
					if (![result invalidIteratorState]) {
						V(@"result:%@", [result description]);
						DOMNode* node;
						for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
							Log(@"iterateNext: name=%@ type=%d value=%@", [node nodeName], [node nodeType], [node nodeValue]);
							return node; /* 先頭のDOMノードでOK(1ノードしか選択していないハズ) */
						}
					}
				}
			}
			V(@"Failed XPath(number of %d) for clickedNode: %@", [xpathes count], [clickedNode description]);
		}
	}
	@catch (NSException* exp) {
		Log([exp description]);
	}
	return nil;
}
#endif // FIX20080412
@end

#pragma mark -
@implementation ReblogDeliverer
#ifdef FIX20080412
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
#endif /* FIX20080412 */

/**
 * Deliverer のファクトリ
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	ReblogDeliverer* deliverer = nil;

#ifdef FIX20080412
	NSDictionary* tokens = [ReblogDeliverer tokensFromIFrame:document];
	if (tokens == nil) {
		return nil;
	}
	deliverer = [[ReblogDeliverer alloc] initWithDocument:document target:clickedElement postID:[tokens objectForKey:@"pid"] reblogKey:[tokens objectForKey:@"rk"]];
#else
	DOMNode* permalinkNode = [ReblogDeliverer findPermalink:document element:clickedElement];
	if (permalinkNode == nil) {
		return nil;
	}
	NSString* postID = [[permalinkNode nodeValue] lastPathComponent];
	if (postID == nil) {
		V(@"Could not get post id. Node:%@", [permalinkNode description]);
		return nil;
	}

	deliverer = [[ReblogDeliverer alloc] initWithDocument:document target:clickedElement postID:postID];
#endif
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
#ifdef FIX20080412
- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement postID:(NSString*)postID reblogKey:(NSString*)rk
#else
- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement postID:(NSString*)postID
#endif
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
		type_ = nil;
		postID_ = [postID retain];
#ifdef FIX20080412
		if (rk != nil) {
			reblogKey_ = [rk retain];
		}
		else {
			reblogKey_ = nil;
		}
#endif
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
#ifdef FIX20080412
	if (reblogKey_ != nil) {
		[reblogKey_ release];
		reblogKey_ = nil;
	}
#endif
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
#ifdef FIX20080412
	[self reblog];
#else
	type_ = (NSString*)[self postEntry:postID_];
#endif
}

#ifdef FIX20080412
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
#endif

#pragma mark -
/**
 * ポストが成功した時
 */
- (void) posted:(NSData*)responseData
{
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
