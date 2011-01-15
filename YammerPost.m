/**
 * @file YammerPost.m
 */
#import "YammerPost.h"
#import "NSString+Tumblrful.h"
#import "UserSettings.h"
#import "TumblrfulConstants.h"
#import "DebugLog.h"

#define TIMEOUT (30.0)

static NSString * ENDPOINT_FORMAT = @"https://www.yammer.com/%@/messages/new";

@interface YammerPost ()
- (void)callbackOnMainThread:(SEL)selector withObject:(id)obj;
@end

@implementation YammerPost

#pragma mark -
#pragma mark Custom Public Methods

+ (BOOL)enabled
{
	return [[UserSettings sharedInstance] boolForKey:@"yammerEnabled"];
}

#pragma mark -
#pragma mark Override Methods

+ (NSString *)username
{
	return nil;
}

+ (NSString *)password
{
	return nil;
}

- (id)initWithCallback:(NSObject<PostCallback> *)callback
{
	if ((self = [super init]) != nil) {
		callback_ = [callback retain];
	}
	return self;
}

- (void)dealloc
{
	[callback_ release], callback_ = nil;
	[webView_ release], webView_ = nil;
	[super dealloc];
}

- (NSMutableDictionary *)createMinimumRequestParams
{
	return [NSMutableDictionary dictionary];
}

- (BOOL)privated
{
	return NO;
}

- (void)postWith:(NSDictionary *)params
{
	releasable_ = NO;

	@try {
		// URL
		NSString * network = [[UserSettings sharedInstance] stringForKey:@"yammerNetwork"];
		NSString * url = [NSString stringWithFormat:ENDPOINT_FORMAT, network];
		D0(url);

		// status(body text)
		D0([params objectForKey:@"body"]);
		NSString * status = [[params objectForKey:@"body"] stringByURLEncoding:NSUTF8StringEncoding];

		NSURL * u = [NSURL URLWithString:[NSString stringWithFormat:@"%@?status=%@", url, status]];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:u cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:TIMEOUT];

		webView_ = [[WebView alloc] initWithFrame:NSZeroRect frameName:nil groupName:nil];
		[webView_ setHidden:YES];
		[webView_ setFrameLoadDelegate:self];
		[webView_ setResourceLoadDelegate:self];
		[[webView_ mainFrame] loadRequest:request];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self callbackOnMainThread:@selector(failedWithException:) withObject:e];
	}
}

- (void)callbackOnMainThread:(SEL)selector withObject:(id)obj
{
	if (callback_ != nil && [callback_ respondsToSelector:selector]) {
		[callback_ performSelectorOnMainThread:selector withObject:obj waitUntilDone:NO];
	}
}

#pragma mark -
#pragma mark WebFrameLoadDelegate Methods

/// ページの読み込みを始めるときに呼び出される
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
#pragma unused (sender, frame)
	D_METHOD;
}

- (void)webView:(WebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame
{
#pragma unused (sender, frame)
	D_METHOD;
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
#pragma unused (sender, error, frame)
	D0([error description]);
	[self callbackOnMainThread:@selector(failedWithError:) withObject:error];
}

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
#pragma unused (sender, frame)
	D_METHOD;
}

/// ページタイトルが決定したら
- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
#pragma unused (sender, title, frame)
	D0(title);
}

/// ページアイコンを受信したら
- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame
{
#pragma unused (sender, image, frame)
	D_METHOD;
}

/// フレームデータ読み込みの完了
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
#pragma unused (sender, frame)
	D_METHOD;
	if ([sender mainFrame] != frame) return;

	DOMHTMLDocument * htmlDoc = (DOMHTMLDocument *)[frame DOMDocument];
	if (![htmlDoc isKindOfClass:[DOMHTMLDocument class]]) return;

	DOMHTMLCollection * forms = htmlDoc.forms;
	unsigned int const formCount = forms.length;
	D(@"formCount=%u", formCount);
	for (unsigned int i = 0; i < formCount; ++i) {
		DOMHTMLFormElement * form = (DOMHTMLFormElement *)[forms item:i];
		D(@"form.name=%@ method=%@ target=%@ id=%@", form.name, form.method, form.target, [form getAttribute:@"id"]);

		if ([[form getAttribute:@"id"] isEqualToString:@"main-message-form"]) {
			DOMNodeList * buttons = [form getElementsByClassName:@"message-form-submit submit-main-message action-btn new-btn"];
			unsigned int const buttonCount = buttons.length;
			D(@"buttons=%u", buttonCount);
			for (unsigned int j = 0; j < buttonCount; ++j) {
				DOMHTMLButtonElement * button = (DOMHTMLButtonElement *)[buttons item:j];
				[button click];
				D0(@"button clicked");
				[self callbackOnMainThread:@selector(successed:) withObject:@"done"];
				return;
			}
		}
	}

	NSString * message = @"Not found form or button elment";
	D0(message);
	NSException * e = [NSException exceptionWithName:TUMBLRFUL_EXCEPTION_NAME reason:message userInfo:nil];
	[self callbackOnMainThread:@selector(failedWithException:) withObject:e];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
#pragma unused (sender, error, frame)
	D0([error description]);
	[self callbackOnMainThread:@selector(failedWithError:) withObject:error];
	[self autorelease];
}

- (void)webView:(WebView *)sender didChangeLocationWithinPageForFrame:(WebFrame *)frame
{
#pragma unused (sender, frame)
	D_METHOD;
}

- (void)webView:(WebView *)sender willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame
{
#pragma unused (sender, URL, seconds, date, frame)
	D_METHOD;
}

- (void)webView:(WebView *)sender didCancelClientRedirectForFrame:(WebFrame *)frame
{
#pragma unused (sender, frame)
	D_METHOD;
}

- (void)webView:(WebView *)sender willCloseFrame:(WebFrame *)frame
{
#pragma unused (sender, frame)
	D(@"mainFrame=%d", ([sender mainFrame] == frame));
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
#pragma unused (sender, windowObject, frame)
	D(@"WebScriptObject=%@", [windowObject description]);
}

#pragma mark -
#pragma mark WebResourceLoadDelegate Methods
#if 0
- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
#pragma unused (sender, request, dataSource)
	D_METHOD;
}
#endif
- (void)webView:(WebView *)sender resource:(id)identifier didReceiveResponse:(NSURLResponse *)response fromDataSource:(WebDataSource *)dataSource
{
#pragma unused (sender, identifier, response, dataSource)
	D_METHOD;

	if ([sender mainFrame] != [dataSource webFrame]) return;

	NSInteger const statusCode = [((NSHTTPURLResponse *)response) statusCode];
	D(@"statusCode=%d", statusCode);

	releasable_ = (statusCode == 201);
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
#pragma unused (sender, identifier, dataSource)
	D0([identifier description]);

	if ([sender mainFrame] != [dataSource webFrame]) return;
#if 0
	NSString * s = [[[NSString alloc] initWithData:[dataSource data] encoding:NSUTF8StringEncoding] autorelease];
	D(@"data=%@", s);
	D(@"request=%@", [[dataSource request] description]);
	D(@"response.URL=%@", [[[dataSource response] URL] absoluteString]);
#endif
	if (releasable_) {
		releasable_ = NO;
		D0(@"autoreleased!");
		[self autorelease];
	}
}

- (void)webView:(WebView *)sender plugInFailedWithError:(NSError *)error dataSource:(WebDataSource *)dataSource
{
#pragma unused (sender, error, dataSource)
	D0([error description]);
	[self callbackOnMainThread:@selector(failedWithError:) withObject:error];
	if (releasable_) {
		releasable_ = NO;
		D0(@"autoreleased!");
		[self autorelease];
	}
}

@end
