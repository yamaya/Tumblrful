/**
 * @file DeliciousPost.m
 * @brief DeliciousPost class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-28
 */
// /System/Library/Frameworks/Foundation.framework/Headers/NSXMLDocument.h
// /System/Library/Frameworks/Foundation.framework/Headers/NSXMLNode.h
#import "DeliciousPost.h"
#import "NSDataBase64.h"
#import "UserSettings.h"
#import "DebugLog.h"
#import <Foundation/NSXMLDocument.h>

static NSString * API_ADD_ENDPOINT = @"https://api.del.icio.us/v1/posts/add?";

#define TIMEOUT (30.0)

#pragma mark -
@interface DeliciousPost ()
- (NSURLRequest *)createRequest:(NSDictionary *)params;
- (void)callback:(SEL)selector withObject:(id)obj;
@end

#pragma mark -
@implementation DeliciousPost
+ (NSString *)username
{
	return [[UserSettings sharedInstance] stringForKey:@"deliciousUsername"];
}

+ (NSString *)password
{
	return [[UserSettings sharedInstance] stringForKey:@"deliciousPassword"];
}

/**
 * enable on del.icio.us post
 */
+ (BOOL)isEnabled
{
	return [[UserSettings sharedInstance] boolForKey:@"deliciousEnabled"];
}

- (id)initWithCallback:(NSObject<PostCallback> *)callback
{
	if ((self = [super init]) != nil) {
		callback_ = [callback retain];
		responseData_ = nil;
		private_ = [[UserSettings sharedInstance] boolForKey:@"deliciousPrivateEnabled"];
	}
	return self;
}

- (void)dealloc
{
	[callback_ release], callback_ = nil;
	[responseData_ release], responseData_ = nil;

	[super dealloc];
}

- (NSMutableDictionary *)createMinimumRequestParams
{
	NSString * shared = [NSString stringWithFormat:@"%@", ([self privated] ? @"no" : @"yes")];

	NSMutableArray * keys = [NSMutableArray arrayWithObjects:@"shared", nil];
	NSMutableArray * objs = [NSMutableArray arrayWithObjects:shared, nil];

	return [[NSMutableDictionary alloc] initWithObjects:objs forKeys:keys];
}

- (BOOL)privated
{
	return private_;
}

- (void)postWith:(NSDictionary *)params
{
	responseData_ = [[NSMutableData data] retain];

	NSURLRequest * request = [self createRequest:params]; // request は connection に指定した時点で reatin upする
	D(@"request:%@", [request description]);

	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];

	D(@"connection:%@", SafetyDescription(connection));
	if (connection == nil) {
		[self callback:@selector(failedWithError:) withObject:nil];
		[responseData_ release], responseData_ = nil;
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
#pragma unused (connection)
	D_METHOD;

	NSString * user = [DeliciousPost username];
	NSString * pass = [DeliciousPost password];

	NSURLCredential * crendential = [NSURLCredential credentialWithUser:user password:pass persistence:NSURLCredentialPersistenceForSession];
	[[challenge sender] useCredential:crendential forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused (connection)
	D(@"DeliciousPost.didReceiveResponse retain:%x", [self retainCount]);

	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response; /* この cast は正しい */
	if ([httpResponse statusCode] != 201) {
		D(@"\tAbnormal! statusCode: %d", [httpResponse statusCode]);
		D(@"\tallHeaderFields: %@", [[httpResponse allHeaderFields] description]);
	}

	[responseData_ setLength:0]; // initialize receive buffer
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#pragma unused (connection)
	[responseData_ appendData:data]; // append data to receive buffer
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#pragma unused (connection)
	D(@"succeeded to load %d bytes", [responseData_ length]);

	if (callback_ != nil) {
		NSError * error = nil;
		NSXMLDocument * xmlDoc = [[[NSXMLDocument alloc] initWithData:responseData_ options:NSXMLDocumentTidyHTML error:&error] autorelease];
		NSXMLNode * node = [[xmlDoc rootElement] attributeForName:@"code"];

		NSString * resultCode = nil;
		if (node != nil) {
			resultCode = [node stringValue];
		}
		D(@"resultCode:%@", resultCode);

		[self callback:@selector(successed:) withObject:resultCode];
	}
	else {
		[self callback:@selector(failedWithError:) withObject:nil];
	}
}

- (NSURLRequest *)createRequest:(NSDictionary *)params
{
#pragma unused (connection)
	@try {
		NSMutableString * ms = [[[NSMutableString alloc] initWithString:API_ADD_ENDPOINT] autorelease];
		NSEnumerator * enumerator = [params keyEnumerator];
		NSString * key;
		while ((key = [enumerator nextObject]) != nil) {
			[ms appendFormat:@"&%@=%@", key, [params objectForKey:key]];
		}
		NSString * s = [NSString stringWithString:ms];
		s = [s stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		s = [s stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];

		// create the POST request
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:s] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:TIMEOUT];
		[request setValue:@"Tumblrful" forHTTPHeaderField:@"User-Agent"];

		return request;
	}
	@catch (NSException * e) {
		D0([e description]);
	}
	return nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused (connection)
	D0([error description]);

	[self callback:@selector(failedWithError:) withObject:error];
}

- (void)callback:(SEL)selector withObject:(id)obj
{
	if (callback_ != nil && [callback_ respondsToSelector:selector]) {
		[callback_ performSelectorOnMainThread:selector withObject:obj waitUntilDone:NO];
	}
}
@end
