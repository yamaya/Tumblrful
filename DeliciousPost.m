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

@interface DeliciousPost ()
- (NSURLRequest *)createRequest:(NSDictionary *)params;
- (void)callback:(SEL)selector withObject:(id)obj;
@end

@implementation DeliciousPost

#pragma mark -
#pragma mark Custom Public Methods

+ (BOOL)enabled
{
	return [[UserSettings sharedInstance] boolForKey:@"deliciousEnabled"];
}

#pragma mark -
#pragma mark Override Methods

+ (NSString *)username
{
	return [[UserSettings sharedInstance] stringForKey:@"deliciousUsername"];
}

+ (NSString *)password
{
	return [[UserSettings sharedInstance] stringForKey:@"deliciousPassword"];
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

- (BOOL)privated
{
	return [[UserSettings sharedInstance] boolForKey:@"deliciousPrivateEnabled"];
}

- (NSMutableDictionary *)createMinimumRequestParams
{
	NSString * shared = [NSString stringWithFormat:@"%@", ([self privated] ? @"no" : @"yes")];
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:shared, @"shared", nil];
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
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
	if ([httpResponse statusCode] != 201) {
		D(@"Abnormal! statusCode: %d", [httpResponse statusCode]);
		D(@"allHeaderFields: %@", [[httpResponse allHeaderFields] description]);
	}

	[data_ setLength:0]; // initialize receive buffer
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#pragma unused (connection)
	[data_ appendData:data]; // append data to receive buffer
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#pragma unused (connection)
	D(@"response data is %d bytes", [data_ length]);

	@try {
		if (callback_ != nil) {
			NSError * error = nil;
			NSXMLDocument * xmlDoc = [[[NSXMLDocument alloc] initWithData:data_ options:NSXMLDocumentTidyHTML error:&error] autorelease];
			if (error != nil) {
				[self callback:@selector(failedWithError:) withObject:error];
				return;
			}

			NSString * resultCode = nil;
			NSXMLNode * node = [[xmlDoc rootElement] attributeForName:@"code"];
			if (node != nil) {
				resultCode = [node stringValue];
			}
			D(@"resultCode:%@", resultCode);

			[self callback:@selector(successed:) withObject:resultCode];
		}
		else {
			D(@"Callback object should be set");
		}
	}
	@catch (NSException * e) {
		[self callback:@selector(failedWithException:) withObject:e];
	}
	@finally {
		[self autorelease];
	}
}

- (NSURLRequest *)createRequest:(NSDictionary *)params
{
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
	[self autorelease];
}

- (void)callback:(SEL)selector withObject:(id)obj
{
	if (callback_ != nil && [callback_ respondsToSelector:selector]) {
		[callback_ performSelectorOnMainThread:selector withObject:obj waitUntilDone:NO];
	}
}
@end
