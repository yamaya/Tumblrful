/**
 * @file TumblrPost.m
 * @brief TumblrPost class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "TumblrPost.h"
#import "UserSettings.h"
#import "TumblrfulConstants.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"
#import <WebKit/WebKit.h>
#import <Foundation/NSXMLDocument.h>

static float TIMEOUT = 60.0f;

#pragma mark -

@interface TumblrPost ()
- (void)postWithEndpoint:(NSString *)url withParams:(NSDictionary *)params;
- (void)callbackOnMainThread:(SEL)selector withObject:(NSObject *)param;
@end

#pragma mark -

@implementation TumblrPost

@synthesize privated = private_;
@synthesize queuingEnabled = queuing_;

- (id)initWithCallback:(NSObject<PostCallback> *)callback
{
	if ((self = [super init]) != nil) {
		UserSettings * defaults = [UserSettings sharedInstance];
		private_ = [defaults boolForKey:@"tumblrPrivateEnabled"];
		queuing_ = [defaults boolForKey:@"tumblrQueuingEnabled"];

		callback_ = [callback retain];
		responseData_ = nil;
	}
	return self;
}

- (void)dealloc
{
	[callback_ release], callback_ = nil;
	[responseData_ release], responseData_ = nil;

	[super dealloc];
}

+ (NSString *)username
{
	return [[UserSettings sharedInstance] stringForKey:@"tumblrEmail"];
}

+ (NSString *)password
{
	return [[UserSettings sharedInstance] stringForKey:@"tumblrPassword"];
}

- (NSMutableDictionary *)createMinimumRequestParams
{
	NSMutableArray * keys = [NSMutableArray arrayWithObjects:@"email", @"password", @"generator", nil];
	NSMutableArray * objs = [NSMutableArray arrayWithObjects:[TumblrPost username], [TumblrPost password], @"Tumblrful", nil];
	if (self.privated) {
		[keys addObject:@"private"];
		[objs addObject:@"1"];
	}
	return [NSMutableDictionary dictionaryWithObjects:objs forKeys:keys];
}

- (NSURLRequest *)createRequest:(NSString *)url params:(NSDictionary *)params
{
	NSMutableString * escaped = [NSMutableString string];

	// create the body. add key-values paire from the NSDictionary object
	NSEnumerator * enumerator = [params keyEnumerator];
	NSString * key;
	while ((key = [enumerator nextObject]) != nil) {
        NSObject * any = [params objectForKey:key]; 
		NSString * value;
        if ([any isMemberOfClass:[NSURL class]]) {
            value = [(NSURL *)any absoluteString];
        }
        else {
            value = (NSString *)any;
        }
		value = [value stringByURLEncoding:NSUTF8StringEncoding];
		[escaped appendFormat:@"&%@=%@", key, value];
		D0(escaped);
	}

	// create the POST request
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:TIMEOUT];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[escaped dataUsingEncoding:NSUTF8StringEncoding]];

	return request;
}

- (void)postWith:(NSDictionary *)params
{
	D(@"type=%@", [params objectForKey:@"type"]);

	if ([[params objectForKey:@"type"] isEqualToString:@"reblog"]) {
		TumblrReblogExtractor * extractor = [[TumblrReblogExtractor alloc] initWithDelegate:self];
		[extractor startWithPostID:[params objectForKey:@"pid"] withReblogKey:[params objectForKey:@"rk"]];
	}
	else {
		[self postWithEndpoint:TUMBLRFUL_TUMBLR_WRITE_URL withParams:params];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused (connection)
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response; /* この cast は正しい */

	NSInteger const httpStatus = [httpResponse statusCode];
	if (httpStatus != 201 && httpStatus != 200) {
		D(@"statusCode:%d", httpStatus);
		D(@"ResponseHeader:%@", [[httpResponse allHeaderFields] description]);
	}

	responseData_ = [[NSMutableData data] retain];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#pragma unused (connection)
	[responseData_ appendData:data]; // append data to receive buffer
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#pragma unused (connection)
	if (callback_ != nil) {
		NSString * text = [[[NSString alloc] initWithData:responseData_ encoding:NSUTF8StringEncoding] autorelease];
		[self callbackOnMainThread:@selector(successed:) withObject:text];
	}
	else {
		NSError * error = [NSError errorWithDomain:TUMBLRFUL_ERROR_DOMAIN code:-1 userInfo:nil];
		[self callbackOnMainThread:@selector(failedWithError:) withObject:error];
	}

	[responseData_ release]; /* release receive buffer */
	[self release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused (connection)
	D0([error description]);

	[responseData_ release], responseData_ = nil;

	[self callbackOnMainThread:@selector(failedWithError:) withObject:error];
	[self release];
}

#ifdef SUPPORT_MULTIPART_PORT
/**
 * create multipart POST request
 */
-(NSURLRequest *)createRequestForMultipart:(NSDictionary *)params withData:(NSData *)data
{
	static NSString* HEADER_BOUNDARY = @"0xKhTmLbOuNdArY";

	// create the URL POST Request to tumblr
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:TUMBLRFUL_TUMBLR_WRITE_URL]];

	[request setHTTPMethod:@"POST"];

	// add the header to request
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", HEADER_BOUNDARY] forHTTPHeaderField: @"Content-Type"];

	// create the body
	NSMutableData* body = [NSMutableData data];
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", HEADER_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];

	// add key-values from the NSDictionary object
	NSEnumerator* enumerator = [params keyEnumerator];
	NSString* key;
	while ((key = [enumerator nextObject]) != nil) {
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"%@", [params objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", HEADER_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
	}

	// add data field and file data
	[body appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"data\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[NSData dataWithData:data]];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", HEADER_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];

	// add the body to the post
	[request setHTTPBody:body];

	return request;
}
#endif /* SUPPORT_MULTIPART_PORT */

#pragma mark -
#pragma mark Private Methods

- (void)postWithEndpoint:(NSString *)url withParams:(NSDictionary *)params
{
	D_METHOD;

	NSURLRequest * request = [self createRequest:url params:params];	// request は connection に指定した時点で reatin upする
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];	// autoreleased

	if (connection == nil) {
		[self callbackOnMainThread:@selector(failedWithError:) withObject:nil];
	}
}

- (void)callbackOnMainThread:(SEL)selector withObject:(NSObject *)object
{
	if (callback_ != nil && [callback_ respondsToSelector:selector]) {
		[callback_ performSelectorOnMainThread:selector withObject:object waitUntilDone:NO];
	}
}

#pragma mark -
#pragma mark Delegate Methods

- (void)extractor:(TumblrReblogExtractor *)extractor didFinishExtract:(NSDictionary *)contents
{
	D(@"extract: contents=%@", SafetyDescription(contents));

	if (contents == nil) {
		NSString * message = [NSString stringWithFormat:@"Unrecognized Reblog form."];
		D0(message);
		NSException * e = [NSException exceptionWithName:TUMBLRFUL_EXCEPTION_NAME reason:message userInfo:nil];
		[self callbackOnMainThread:@selector(failedWithException:) withObject:e];
	}
	else if ([contents count] < 2) { // type[post] + 1このフィールドは絶対あるはず
		NSString * message = [NSString stringWithFormat:@"Unrecognized Reblog form. too few fields. type:%@", SafetyDescription([contents objectForKey:@"type"])];
		NSException * e = [NSException exceptionWithName:TUMBLRFUL_EXCEPTION_NAME reason:message userInfo:nil];
		[self callbackOnMainThread:@selector(failedWithException:) withObject:e];
		return;
	}

	NSMutableDictionary * params = [NSMutableDictionary dictionaryWithDictionary:contents];
	if (queuing_) [params setObject:@"2" forKey:@"post[state]"];	// queuing post
	[params addEntriesFromDictionary:contents];

	// Tumblrへポストする
	[self postWithEndpoint:extractor.endpoint withParams:params];
}

- (void)extractor:(TumblrReblogExtractor *)extractor didFailExtractWithError:(NSError *)error
{
#pragma unused (extractor)
	[self callbackOnMainThread:@selector(failedWithException:) withObject:error];
}
@end // TumblrPost
