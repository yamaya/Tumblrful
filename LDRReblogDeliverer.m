/**
 * @file LDRReblogDeliverer.m
 * @brief LDRReblogDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLDocument.h
#import "LDRReblogDeliverer.h"
#import "LDRDelivererContext.h"
#import "Log.h"
#import <WebKit/WebKit.h>
#import <Foundation/NSXMLDocument.h>

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

static NSString* TUMBLR_DOMAIN = @".tumblr.com";
static NSString* TUMBLR_DATA_URI = @"htpp://data.tumblr.com/";

#ifdef FIX20080412
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
#endif // FIX20080412

#pragma mark -
@implementation LDRReblogDeliverer
/**
 * create.
 *	@param document DOMHTMLDocument オブジェクト
 *	@param clickedElement クリックしたDOM要素の情報
 *	@return Deliverer オブジェクト
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	if (![LDRDelivererContext match:document target:clickedElement]) {
		return nil;
	}

	/* あーあ、しょうがないので自力で LDRDelivererContext を生成するよ */
	LDRDelivererContext* context =
		[[LDRDelivererContext alloc] initWithDocument:document
											   target:clickedElement];
	if (context == nil) {
		return nil;
	}
	[context autorelease];

	NSURL* url = [NSURL URLWithString:[context documentURL]];
	if (url == nil) {
		return nil;
	}

	NSRange range;
	DOMNode* node = [clickedElement objectForKey:WebElementImageURLKey];
	if (node != nil && [[node className] isEqualToString:@"DOMHTMLImageElement"]) {
		DOMHTMLImageElement* img = (DOMHTMLImageElement*)node;
		range = [[img src] rangeOfString:TUMBLR_DATA_URI];
		if (!(range.location == 0 && range.length >= [TUMBLR_DATA_URI length])) {
			V(@"LDRReblogDeliverer: type is Photo but On %@", TUMBLR_DATA_URI);
			return nil;
		}
	}
	else {
		range = [[url host] rangeOfString:TUMBLR_DOMAIN];
		if (!(range.location > 0 && range.length == [TUMBLR_DOMAIN length])) {
			V(@"LDRReblogDeliverer: Not in %@", TUMBLR_DOMAIN);
			return nil;
		}
	}

	LDRReblogDeliverer* deliverer = nil;

	NSString* postID = [[context documentURL] lastPathComponent];
	if (postID == nil) {
		V(@"Could not get PostID. element:%@", [clickedElement description]);
		return nil;
	}

	/* LDR ではこの時点で ReblogKey は得られないので nil を指定する */
	deliverer =
		[[LDRReblogDeliverer alloc] initWithDocument:document
											  target:clickedElement
											  postID:postID
										   reblogKey:nil];
	if (deliverer != nil) {
		[deliverer retain];	//TODO: need?
	}
	else {
		Log(@"Could not alloc+init %@.", [LDRReblogDeliverer className]);
	}
	return deliverer;
}
#ifdef FIX20080412
/**
 * メニューのアクション
 *	@param sender アクションを起こしたオブジェクト
 *
 *	1. Reblog 先のHTMLをdownloadして、そのiframeから reblogkey を得る
 *	2. reblogkey を得たら、このインスタンスを invokeする
 */
- (void) action:(id)sender
{
	NSString* endpoint = [context_ documentURL];

	V(@"endpoint: %@", endpoint);

	DelegateForReblogKey* delegate =
		[[DelegateForReblogKey alloc] initWithEndpoint:endpoint
																			continuation:self];
	[delegate retain];

	NSURLRequest* request =
		[NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];

	NSURLConnection* connection =
		[NSURLConnection connectionWithRequest:request delegate:delegate];
	connection = connection;	// for compiler warning

	V(@"connection=%@", SafetyDescription(connection));
}
#endif
@end

#ifdef FIX20080412
@implementation DelegateForReblogKey
/**
 * オブジェクトを初期化する.
 *	@param endpoint
 *	@return 初期化済みオブジェクト
 */
- (id) initWithEndpoint:(NSString*)endpoint continuation:(LDRReblogDeliverer*)continuation
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
- (void) connection:(NSURLConnection*)connection
 didReceiveResponse:(NSURLResponse*)response
{
	/* この cast は正しい */
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;

	V(@"didReceiveResponse: statusCode=%d", [httpResponse statusCode]);

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
	if (responseData_ != nil) {
		V(@"didReceiveData: append length=%d", [data length]);
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
- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
	V(@"connectionDidFinishLoading length=%d", [responseData_ length]);

	if (responseData_ != nil) {
		//V(@"%@", [[[NSString alloc] initWithData:responseData_ encoding:NSUTF8StringEncoding] autorelease]);

		/* DOMにする */
		NSError* error = nil;
		NSXMLDocument* document =
			[[NSXMLDocument alloc] initWithData:responseData_
										options:NSXMLDocumentTidyHTML
										  error:&error];
		V(@"error=%@", SafetyDescription(error));
		if (document != nil) {
			V(@"elements(test)=%@", SafetyDescription([[document rootElement] elementsForName:@"iframe"]));
			NSArray* elements = [[document rootElement] nodesForXPath:@"//iframe[@id=\"tumblr_controls\"]" error:&error];
			V(@"elements=%@ error=%@", SafetyDescription(elements), SafetyDescription(error));
			if (elements != nil && [elements count] > 0) {
				NSXMLElement* element = [elements objectAtIndex:0];
				NSString* src = [[[element attributeForName:@"src"] stringValue] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				V(@"src=%@", SafetyDescription(src));
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

		[continuation_ reblog];
	}

	[self release];
}

/**
 */
- (void) connection:(NSURLConnection*)connection
	 didFailWithError:(NSError*)error
{
	V(@"didFailWithError: %@", [error description]);
	[self release];
}
@end // DelegateForReblogKey
#endif
