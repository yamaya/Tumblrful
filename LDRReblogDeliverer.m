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
#import "NSString+Tumblrful.h"
#import <WebKit/WebKit.h>
#import "DebugLog.h"
#import <objc/objc-runtime.h>

static NSString * TUMBLR_DOMAIN = @".tumblr.com";
static NSString * TUMBLR_DATA_URI = @"htpp://data.tumblr.com/";

/// Reblog Key を得るための NSURLConnection で使う Delegateクラス.
@interface ReblogKeyDelegate : NSObject
{
	NSString * endpoint_;
	NSMutableData * data_;
	LDRReblogDeliverer * deliverer_;
}

- (id)initWithEndpoint:(NSString *)endpoint deliverer:(LDRReblogDeliverer *)deliverer;
@end

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

	NSURL * url = [NSURL URLWithString:context.documentURL];
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

	NSString * postID = [context.documentURL lastPathComponent];
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

- (void)dealloc
{
	[webView_ release], webView_ = nil;
	[delegate_ release], delegate_ = nil;
	[super dealloc];
}

- (void)action:(id)sender
{
	@try {
		// ReblogKeyDelegateから(その通信後に)呼び出された場合
		if (object_getClass(sender) == [ReblogKeyDelegate class]) {
			[super action:sender];
		}
		// メニューから呼び出された場合
		else {
			NSString * endpoint = context_.documentURL;

			delegate_ = [[ReblogKeyDelegate alloc] initWithEndpoint:endpoint deliverer:self];

			NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];

			webView_ = [[WebView alloc] initWithFrame:NSZeroRect frameName:nil groupName:nil];
			[webView_ setHidden:YES];
			[webView_ setDrawsBackground:NO];
			[webView_ setShouldUpdateWhileOffscreen:NO];
			[webView_ setFrameLoadDelegate:delegate_];
			[[webView_ mainFrame] loadRequest:request];
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

#pragma mark -
#pragma mark WebFrameLoadDelegate Methods

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	D(@"mainFrame=%d", ([sender mainFrame] == frame));
	if ([sender mainFrame] != frame) return;

	D0([error description]);
	[self performSelectorOnMainThread:@selector(delegateDidFailExtractMethod:) withObject:error waitUntilDone:YES];
	[self autorelease];
}

/// フレームデータ読み込みの完了
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	D(@"mainFrame=%d", ([sender mainFrame] == frame));
	if ([sender mainFrame] != frame) return;

	DOMHTMLDocument * htmlDoc = (DOMHTMLDocument *)[frame DOMDocument];
	if (![htmlDoc isKindOfClass:[DOMHTMLDocument class]]) return;

	@try {
		NSDictionary * tokens = [ReblogDeliverer reblogTokensFromIFrame:htmlDoc];
		if (tokens != nil) {
			[deliverer_ setPostID:[tokens objectForKey:@"pid"]];
			[deliverer_ setReblogKey:[tokens objectForKey:@"rk"]];

			D(@"pid=%@, rk=%@", deliverer_.postID, deliverer_.reblogKey);
			if (deliverer_.postID != nil && deliverer_.reblogKey != nil) {
				// メニューから呼び出されたのと同じ事をする
				[deliverer_ performSelector:@selector(action:) withObject:self];
			}
			else {
				[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"tumblr_controls iframe found, but not found 'pid' or 'rk'"];
			}
		}
		else {
			[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"Not found tumblr_controls iframe."];
		}
	}
	@catch (NSException * e) {
		D0([e description]);
		[deliverer_ performSelector:@selector(failedWithException:) withObject:e];
	}
	@finally {
		[self autorelease];
	}
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	if ([sender mainFrame] != frame) return;

	D0([error description]);
	[self performSelectorOnMainThread:@selector(delegateDidFailExtractMethod:) withObject:error waitUntilDone:YES];

	[self autorelease];
}

@end // ReblogKeyDelegate
