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
- (void)postWithEndpoint:(NSString *)endpointURL withParams:(NSDictionary *)params;
- (void)postWithEndpoint:(NSString *)endpointURL withReblogContents:(NSDictionary *)contents;
- (void)callbackOnMainThread:(SEL)selector withObject:(NSObject *)param;
@end

#pragma mark -

@implementation TumblrPost

@synthesize privated = private_;
@synthesize queuingEnabled = queuing_;
@synthesize extractEnabled = extractEnabled_;

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
	[reblogParams_ release], reblogParams_ = nil;

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
	}
	D0(escaped);

	// create the POST request
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:TIMEOUT];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[escaped dataUsingEncoding:NSUTF8StringEncoding]];

	return request;
}

- (void)postWith:(NSDictionary *)params
{
	D(@"type=%@", [params objectForKey:@"type"]);

	if ([[params objectForKey:@"type"] caseInsensitiveCompare:@"reblog"] == NSOrderedSame) {
		NSString * postID = [params objectForKey:@"pid"];
		NSString * reblogKey = [params objectForKey:@"rk"];
		if (self.extractEnabled) {
			reblogParams_ = [params retain];
			TumblrReblogExtractor * extractor = [[TumblrReblogExtractor alloc] initWithDelegate:self];
			[extractor startWithPostID:postID withReblogKey:reblogKey];
		}
		else {
			NSString * endpoint = [TumblrReblogExtractor endpointWithPostID:postID withReblogKey:reblogKey];
			NSMutableDictionary * contents = [NSMutableDictionary dictionaryWithDictionary:params];
			[contents removeObjectForKey:@"pid"];
			[contents removeObjectForKey:@"rk"];
			[self postWithEndpoint:endpoint withReblogContents:contents];
		}
	}
	else {
		[self postWithEndpoint:TUMBLRFUL_TUMBLR_WRITE_URL withParams:params];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused (connection)
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;

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

	[self release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused (connection)
	D0([error description]);

	[self callbackOnMainThread:@selector(failedWithError:) withObject:error];
	[self release];
}

- (NSURLRequest *)createRequest:(NSString *)url params:(NSDictionary *)params withData:(NSData *)data
{
	static NSString * BOUNDARY = @"0xKhTmLbOuNdArY";

	// create the body
	NSMutableData * body = [NSMutableData data];
	// add key-values from the NSDictionary object
	NSEnumerator * enumerator = [params keyEnumerator];
	NSString * key;
	NSString * value;
	while ((key = [enumerator nextObject]) != nil) {
		value = [params objectForKey:key];
		[body appendData:[[NSString stringWithFormat:@"--%@\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\n\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	}

	// add data field and file data(jpeg only)
	[body appendData:[[NSString stringWithFormat:@"--%@\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"data\"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\n\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:data];
	[body appendData:[[NSString stringWithString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"\n--%@--\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];

	// create the POST request. and add the body to the post
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:TIMEOUT];
	[request setHTTPMethod:@"POST"];
	[request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", BOUNDARY] forHTTPHeaderField: @"Content-Type"];
	[request setHTTPBody:body];

	return request;
}

#pragma mark -
#pragma mark Private Methods

- (void)postWithEndpoint:(NSString *)endpointURL withParams:(NSDictionary *)params
{
	D0(endpointURL);
	D0([params description]);

	BOOL const useMultipart = ([[params objectForKey:@"type"] isEqualToString:@"photo"] && [params objectForKey:@"data"] != nil);
	D(@"useMultipart=%d", useMultipart);

	NSURLRequest * request;
	if (useMultipart) {
		NSMutableDictionary * p = [NSMutableDictionary dictionaryWithDictionary:params];
		NSData * data = [[p objectForKey:@"data"] retain];
		[p removeObjectForKey:@"data"];
		request = [self createRequest:endpointURL params:p withData:data];	// request は connection に指定した時点で reatin upする
		[data release];
	}
	else {
		request = [self createRequest:endpointURL params:params];	// request は connection に指定した時点で reatin upする
	}
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];	// autoreleased
	if (connection == nil) {
		[self callbackOnMainThread:@selector(failedWithError:) withObject:nil];
	}
}

- (void)postWithEndpoint:(NSString *)endpointURL withReblogContents:(NSDictionary *)contents
{
	NSMutableDictionary * params = [NSMutableDictionary dictionaryWithDictionary:contents];
	if (self.queuingEnabled)
		[params setObject:@"2" forKey:@"post[state]"];	// queuing post

	[self postWithEndpoint:endpointURL withParams:params];
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
		NSException * e = [NSException exceptionWithName:TUMBLRFUL_EXCEPTION_NAME reason:message userInfo:nil];
		[self callbackOnMainThread:@selector(failedWithException:) withObject:e];
		return;
	}
	else if ([contents count] < 2) {
		NSString * message = [NSString stringWithFormat:@"Unrecognized Reblog form. too few fields. type:%@", SafetyDescription([contents objectForKey:@"type"])];
		NSException * e = [NSException exceptionWithName:TUMBLRFUL_EXCEPTION_NAME reason:message userInfo:nil];
		[self callbackOnMainThread:@selector(failedWithException:) withObject:e];
		return;
	}

	// Tumblrへポストする
	[self postWithEndpoint:extractor.endpoint withReblogContents:contents];
}

- (void)extractor:(TumblrReblogExtractor *)extractor didFailExtractWithError:(NSError *)error
{
#pragma unused (extractor)
	[self callbackOnMainThread:@selector(failedWithError:) withObject:error];
}

- (void)extractor:(TumblrReblogExtractor *)extractor didFailExtractWithException:(NSException *)exception
{
#pragma unused (extractor)
	[self callbackOnMainThread:@selector(failedWithException:) withObject:exception];
}
@end // TumblrPost
