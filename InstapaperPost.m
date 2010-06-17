/**
 * @file InstapaperPost.m
 */
#import "InstapaperPost.h"
#import "NSString+Tumblrful.h"
#import "UserSettings.h"
#import "DebugLog.h"

static NSString * API_ADD_ENDPOINT = @"https://www.instapaper.com/api/add";

#define TIMEOUT (30.0)

@interface InstapaperPost ()
- (NSURLRequest *)createRequest:(NSDictionary *)params;
- (void)callbackOnMainThread:(SEL)selector withObject:(id)obj;
@end

@implementation InstapaperPost

#pragma mark -
#pragma mark Custom Public Methods

+ (BOOL)enabled
{
	return [[UserSettings sharedInstance] boolForKey:@"instapaperEnabled"];
}

#pragma mark -
#pragma mark Override Methods

+ (NSString *)username
{
	return [[UserSettings sharedInstance] stringForKey:@"instapaperUsername"];
}

+ (NSString *)password
{
	return [[UserSettings sharedInstance] stringForKey:@"instapaperPassword"];
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
	[data_ release], data_ = nil;

	[super dealloc];
}

- (NSMutableDictionary *)createMinimumRequestParams
{
	NSString * username = [InstapaperPost username];
	NSString * password = [InstapaperPost password];
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:username, @"username", password, @"password", nil];
}

- (BOOL)privated
{
	return NO;
}

- (void)postWith:(NSDictionary *)params
{
	data_ = [[NSMutableData data] retain];

	NSURLRequest * request = [self createRequest:params]; // request は connection に指定した時点で reatin upする
	D(@"request:%@", [request description]);

	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];
	if (connection == nil) {
		[self callback:@selector(failedWithError:) withObject:nil];
		[data_ release], data_ = nil;
	}
}

#pragma mark -
#pragma mark Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
#pragma unused (connection)
	D_METHOD;

	NSString * user = [InstapaperPost username];
	NSString * pass = [InstapaperPost password];

	NSURLCredential * crendential = [NSURLCredential credentialWithUser:user password:pass persistence:NSURLCredentialPersistenceForSession];
	[[challenge sender] useCredential:crendential forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused (connection)
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response; // この cast は正しい
	if ([httpResponse statusCode] == 200 || [httpResponse statusCode] == 201) {
		D(@"success. HTTP status=%d", [httpResponse statusCode]);
	}
	else {
		D(@"failed. HTTP status=%d, allHeaderFields=%@", [httpResponse statusCode], [[httpResponse allHeaderFields] description]);
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#pragma unused (connection)
	[data_ appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#pragma unused (connection)
	D(@"response data is %d bytes", [data_ length]);

	if (callback_ != nil) {
		NSString * statusCode = [[[NSString alloc] initWithData:data_ encoding:NSUTF8StringEncoding] autorelease];

		[self callbackOnMainThread:@selector(successed:) withObject:statusCode];
	}
	else {
		D(@"Callback object should be set");
	}

	[self autorelease];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused (connection)
	D0([error description]);

	[self callbackOnMainThread:@selector(failedWithError:) withObject:error];

	[self autorelease];
}

#pragma mark -
#pragma mark Private Methods

- (NSURLRequest *)createRequest:(NSDictionary *)params
{
	@try {
		// create URL with parameters
		NSMutableString * ps = [NSMutableString string];
		NSEnumerator * enumerator = [params keyEnumerator];
		for (NSString * key; (key = [enumerator nextObject]) != nil; ) {
			D(@"%@=%@", key, [params objectForKey:key]);
			[ps appendFormat:@"&%@=%@", key, [[params objectForKey:key] stringByURLEncoding:NSUTF8StringEncoding]];
		}
		NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", API_ADD_ENDPOINT, ps]];

		// create the POST request
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:TIMEOUT];
		[request setValue:@"Tumblrful" forHTTPHeaderField:@"User-Agent"];

		return request;
	}
	@catch (NSException * e) {
		D0([e description]);
	}
	return nil;
}

- (void)callbackOnMainThread:(SEL)selector withObject:(id)obj
{
	if (callback_ != nil && [callback_ respondsToSelector:selector]) {
		[callback_ performSelectorOnMainThread:selector withObject:obj waitUntilDone:NO];
	}
}
@end
