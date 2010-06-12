/**
 * @file LDRReblogDeliverer.m
 * @brief LDRReblogDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLDocument.h
#import "LDRReblogDeliverer.h"
#import "LDRDelivererContext.h"
#import "DebugLog.h"
#import <WebKit/WebKit.h>
#import <Foundation/NSXMLDocument.h>
#import <objc/objc-runtime.h>

static NSString * TUMBLR_DOMAIN = @".tumblr.com";
static NSString * TUMBLR_DATA_URI = @"htpp://data.tumblr.com/";

#pragma mark -
/**
 * Reblog Key を得るための NSURLConnection で使う Delegateクラス.
 */
@interface DelegateForReblogKey : NSObject
{
	NSString* endpoint_;
	NSMutableData* responseData_;	/**< for NSURLConnection */
	LDRReblogDeliverer* continuation_;
}
- (id) initWithEndpoint:(NSString*)endpoint continuation:(LDRReblogDeliverer*)continuation;
- (void) dealloc;
@end

#pragma mark -
@implementation LDRReblogDeliverer

+ (NSString *)sitePostfix
{
	return TUMBLR_DOMAIN;
}

+ (NSString *)dataSiteURL
{
	return TUMBLR_DATA_URI;
}

+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	// Tumblr ポストかどうかのチェック
	if (![LDRDelivererContext match:document target:clickedElement]) return nil;

	// LDRDelivererContext を生成する
	LDRDelivererContext * context = [[[LDRDelivererContext alloc] initWithDocument:document target:clickedElement] autorelease];
	if (context == nil) return nil;

	NSURL * url = [NSURL URLWithString:[context documentURL]];
	if (url == nil) 
		return nil;

	NSRange range;
	DOMNode * node = [clickedElement objectForKey:WebElementImageURLKey];
	if (node != nil && [[node className] isEqualToString:@"DOMHTMLImageElement"]) {
		DOMHTMLImageElement * img = (DOMHTMLImageElement *)node;
		range = [[img src] rangeOfString:[self dataSiteURL]];
		if (!(range.location == 0 && range.length >= [[self dataSiteURL] length])) {
			return nil;
		}
	}
	else {
		range = [[url host] rangeOfString:[self sitePostfix]];
		if (!(range.location > 0 && range.length == [[self sitePostfix] length])) {
			return nil;
		}
	}

	NSString * postID = [[context documentURL] lastPathComponent];
	if (postID == nil) {
		D(@"Could not get PostID. element:%@", [clickedElement description]);
		return nil;
	}

	// LDR ではこの時点で ReblogKey は得られないので未指定で
	LDRReblogDeliverer * deliverer = [[LDRReblogDeliverer alloc] initWithContext:context postID:postID];
	if (deliverer == nil) {
		D(@"Could not alloc+init %@.", [LDRReblogDeliverer className]);
	}

	return deliverer;
}

- (void)action:(id)sender
{
#pragma unused (sender)
	D_METHOD;

	@try {
		// DelegateForReblogKeyから(その通信後に)呼び出された場合
		if (object_getClass(sender) == [DelegateForReblogKey class]) {
			[super action:sender];
		}
		else {
			// メニューから呼び出された場合
			NSString* endpoint = [context_ documentURL];

			NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];

			DelegateForReblogKey * delegate = [[DelegateForReblogKey alloc] initWithEndpoint:endpoint continuation:self];
			[delegate retain];	// 通信後、このオブジェクト自身でreleaseする

			NSURLConnection * connection;
			connection = [NSURLConnection connectionWithRequest:request delegate:delegate];
		}
	}
	@catch (NSException * e) {
		D0([e description]);
	}
}
@end

@implementation DelegateForReblogKey
/**
 * オブジェクトを初期化する.
 *	@param endpoint
 *	@return 初期化済みオブジェクト
 */
- (id)initWithEndpoint:(NSString*)endpoint continuation:(LDRReblogDeliverer*)continuation
{
	if ((self = [super init]) != nil) {
		endpoint_ = [endpoint retain];
		continuation_ = [continuation retain];
		responseData_ = nil;
	}
	return self;
}

/**
 * オブジェクトの解放
 */
- (void) dealloc
{
	if (endpoint_ != nil) {
		[endpoint_ release];
		endpoint_ = nil;
	}
	if (continuation_ != nil) {
		[continuation_ release];
		continuation_ = nil;
	}
	if (responseData_ != nil) {
		[responseData_ release];
		responseData_ = nil;
	}
	[super dealloc];
}

/**
 * didReceiveResponse デリゲートメソッド.
 *	@param connection NSURLConnection オブジェクト
 *	@param response NSURLResponse オブジェクト
 */
- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
#pragma unused (connection)
	/* この cast は正しい */
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;

	if ([httpResponse statusCode] == 200) {
		responseData_ = [[NSMutableData data] retain];
	}
}

/**
 * didReceiveData デリゲートメソッド.
 *	@param connection NSURLConnection オブジェクト
 *	@param response data NSData オブジェクト
 */
- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
#pragma unused (connection)
	if (responseData_ != nil) {
		[responseData_ appendData:data];
	}
}

/**
 * connectionDidFinishLoading デリゲートメソッド.
 *	@param connection NSURLConnection オブジェクト
 *
 *	caramel*tumblr はへんてこなHTMLらしく nodesForXPath で iframeがとれない。
 *	よって Reblogできない。NSXMLDocument じゃなくて NSString にして、文字列
 *	を検索した方がHit率高そう。
 *	しかし ReblogDeliverer は上手くいくんだよなぁ。WebKit の方ががんばってく
 *	れるということなんだろう。DOMHTMLDocument を使いたいのだけれど NSDataから
 *	の生成方法がわからないよ。
 */
- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
#pragma unused (connection)
	D_METHOD;

	if (responseData_ != nil) {
		// DOMにする
		NSError * error = nil;
		NSXMLDocument * document = [[NSXMLDocument alloc] initWithData:responseData_ options:NSXMLDocumentTidyHTML error:&error];
		if (document != nil) {
			NSArray* elements = [[document rootElement] nodesForXPath:@"//iframe[@id=\"tumblr_controls\"]" error:&error];
			if (elements != nil && [elements count] > 0) {
				NSXMLElement * element = [elements objectAtIndex:0];
				NSString* src = [[[element attributeForName:@"src"] stringValue] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSRange range = [src rangeOfString:@"&pid="];
				NSString* s = [src substringFromIndex:range.location + 1];
				NSArray* segments = [s componentsSeparatedByString:@"&"];

				NSEnumerator* enumerator = [segments objectEnumerator];
				while ((s = [enumerator nextObject]) != nil) {
					range = [s rangeOfString:@"pid="];
					if (range.location != NSNotFound) {
						[continuation_ setPostID:[s substringFromIndex:range.location + range.length]];
						continue;
					}
					range = [s rangeOfString:@"rk="];
					if (range.location != NSNotFound) {
						[continuation_ setReblogKey:[s substringFromIndex:range.location + range.length]];
						continue;
					}
				}
			}
		}
		[responseData_ release];

		// メニューから呼び出されたのと同じ事をする
		[continuation_ performSelector:@selector(action:) withObject:self];
	}

	[self release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused (connection, error)
	D0([error description]);

	[self release];
}
@end // DelegateForReblogKey
