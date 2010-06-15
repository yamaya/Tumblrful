/**
 * @file LDRReblogDeliverer.m
 * @brief LDRReblogDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLDocument.h
#import "LDRReblogDeliverer.h"
#import "LDRDelivererContext.h"
#import "TumblrfulConstants.h"
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
@interface ReblogKeyDelegate : NSObject
{
	NSString * endpoint_;
	NSMutableData * data_;
	LDRReblogDeliverer * deliverer_;
}
- (id)initWithEndpoint:(NSString *)endpoint deliverer:(LDRReblogDeliverer *)deliverer;
- (void)dealloc;
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
	@try {
		// ReblogKeyDelegateから(その通信後に)呼び出された場合
		if (object_getClass(sender) == [ReblogKeyDelegate class]) {
			[super action:sender];
		}
		else {
			// メニューから呼び出された場合
			NSString * endpoint = [context_ documentURL];
			NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];
			ReblogKeyDelegate * delegate = [[ReblogKeyDelegate alloc] initWithEndpoint:endpoint deliverer:self];
#if 0 // TODO alloc/init しているのに retainはいらんだろ
			[delegate retain];	// 通信後、このオブジェクト自身でreleaseする
#endif
			NSURLConnection * connection;
			connection = [NSURLConnection connectionWithRequest:request delegate:delegate];
		}
	}
	@catch (NSException * e) {
		D0([e description]);
	}
}
@end

@implementation ReblogKeyDelegate

- (id)initWithEndpoint:(NSString *)endpoint deliverer:(LDRReblogDeliverer *)deliverer
{
	if ((self = [super init]) != nil) {
		endpoint_ = [endpoint retain];
		deliverer_ = [deliverer retain];
		data_ = nil;
	}
	return self;
}

- (void)dealloc
{
	[endpoint_ release], endpoint_ = nil;
	[deliverer_ release], deliverer_ = nil;
	[data_ release], data_ = nil;

	[super dealloc];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused (connection)
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;

	if ([httpResponse statusCode] == 200) {
		data_ = [[NSMutableData data] retain];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#pragma unused (connection)
	if (data_ != nil) [data_ appendData:data];
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

	@try {
		if (data_ == nil) return;

		// DOMにする
		NSError * error = nil;
		NSXMLDocument * xmlDoc = [[[NSXMLDocument alloc] initWithData:data_ options:NSXMLDocumentTidyHTML error:&error] autorelease];
		D0([error description]);

		if (xmlDoc != nil) {
			error = nil;
			NSArray * elements = [[xmlDoc rootElement] nodesForXPath:@"//iframe[@id=\"tumblr_controls\"]" error:&error];
			D0([error description]);
			if (elements != nil && [elements count] > 0) {
				NSXMLElement * element = [elements objectAtIndex:0];
				NSString * src = [[[element attributeForName:@"src"] stringValue] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSRange range = [src rangeOfString:@"&pid="];
				NSString * s = [src substringFromIndex:range.location + 1];
				D0([s description]);

				NSArray * segments = [s componentsSeparatedByString:@"&"];
				NSEnumerator* enumerator = [segments objectEnumerator];
				while ((s = [enumerator nextObject]) != nil) {
					D0([s description]);
					range = [s rangeOfString:@"pid="];
					if (range.location != NSNotFound) {
						[deliverer_ setPostID:[s substringFromIndex:range.location + range.length]];
						continue;
					}
					range = [s rangeOfString:@"rk="];
					if (range.location != NSNotFound) {
						[deliverer_ setReblogKey:[s substringFromIndex:range.location + range.length]];
						continue;
					}
				}
			}
			else {
				NSString * message = @"Not found tumblr_controls iframe.";
				D0(message);
				NSException * e = [NSException exceptionWithName:TUMBLRFUL_EXCEPTION_NAME reason:message userInfo:nil];
				[deliverer_ performSelector:@selector(failedWithException:) withObject:e];
				return;
			}
		}

		// メニューから呼び出されたのと同じ事をする
		[deliverer_ performSelector:@selector(action:) withObject:self];
	}
	@catch (NSException * e) {
		D0([e description]);
		[deliverer_ performSelector:@selector(failedWithException:) withObject:e];
	}
	@finally {
		[self release];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused (connection)
	D0([error description]);

	[deliverer_ performSelector:@selector(failedWithError:) withObject:error];

	[self release];
}
@end // ReblogKeyDelegate
