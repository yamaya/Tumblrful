/**
 * @file DeliciousPost.m
 * @brief DeliciousPost implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-28
 */
// /System/Library/Frameworks/Foundation.framework/Headers/NSXMLDocument.h
// /System/Library/Frameworks/Foundation.framework/Headers/NSXMLNode.h
#import "DeliciousPost.h"
#import "Log.h"
#import "NSDataBase64.h"
#import <Foundation/NSXMLDocument.h>

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

static NSString* API_ADD_ENDPOINT = @"https://api.del.icio.us/v1/posts/add?";

#define TIMEOUT (30.0)

#pragma mark -
@interface DeliciousPost (Private)
- (NSURLRequest*) createRequest:(NSDictionary*)params;
- (void) callback:(SEL)selector withObject:(id)obj;
@end

#pragma mark -
@implementation DeliciousPost
/**
 * get name of account on del.icio.us
 */
+ (NSString*) username
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:@"TumblrfulDeliciousUsername"];
}

/**
 * get passowrd of account on del.icio.us
 */
+ (NSString*) password
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:@"TumblrfulDeliciousPassword"];
}

/**
 * get enable on del.icio.us
 */
+ (BOOL) isEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"TumblrfulWithDelicious"];
}

- (id) initWithCallback:(NSObject<PostCallback>*)callback
{
	if ((self = [super init]) != nil) {
		callback_ = [callback retain];
		responseData_ = nil;
		private_ = [[NSUserDefaults standardUserDefaults] boolForKey:@"TumblrfulDeliciousPrivate"];
	}
	return self;
}

/**
 * dealloc
 */
- (void) dealloc
{
	if (callback_ != nil) {
		[callback_ release];
		callback_ = nil;
	}
	[super dealloc];
}

/**
 * create minimum request param for del.icio.us
 */
- (NSMutableDictionary*) createMinimumRequestParams
{
	NSString* shared =
		[NSString stringWithFormat:@"%@", ([self private] ? @"no" : @"yes")];

	NSMutableArray* keys = [NSMutableArray arrayWithObjects:@"shared", nil];
	NSMutableArray* objs = [NSMutableArray arrayWithObjects:shared, nil];

	return [[NSMutableDictionary alloc] initWithObjects:objs forKeys:keys];
}

/**
 *
 */
- (BOOL) private
{
	return private_;
}

/**
 * post to del.icio.us
 *	@param params - request parameteres
 *	@param delegate - delegate for NSURLConnection
 */
- (void) postWith:(NSDictionary*)params
{
	responseData_ = [[[NSMutableData alloc] init] retain];

	NSURLRequest* request = [self createRequest:params]; /* request は connection に指定した時点で reatin upする */ 
	NSLog(@"DeliciousPost.post: request: %@", [request description]);

	NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[connection retain];

	V(@"DeliciousPost.post connection: %@", SafetyDescription(connection));
	if (connection == nil) {
		[self callback:@selector(failedWithError:) withObject:nil];
		[responseData_ release];
		responseData_ = nil;
		return;
	}
	V(@"DeliciousPost.post: %@", @"exit");
}

/**
 * didReceiveAuthenticationChallenge
 *	delegate method
 */
- (void)connection:(NSURLConnection*)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
	V(@"didReceiveAuthenticationChallenge: %@", @"enter");

	NSURLCredential* crendential =
		[NSURLCredential credentialWithUser:[DeliciousPost username]
															 password:[DeliciousPost password]
														persistence:NSURLCredentialPersistenceForSession];

	[[challenge sender] useCredential:crendential forAuthenticationChallenge:challenge];
}

/**
 * didReceiveResponse
 * delegate method
 *	正常なら statusCode は 201
 *	Account 不正なら 403
 */
- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
	V(@"DeliciousPost.didReceiveResponse retain:%x", [self retainCount]);

	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response; /* この cast は正しい */
	if ([httpResponse statusCode] != 201) {
		Log(@"\tAbnormal! statusCode: %d", [httpResponse statusCode]);
		Log(@"\tallHeaderFields: %@", [[httpResponse allHeaderFields] description]);
	}

	[responseData_ setLength:0]; // initialize receive buffer
}

/**
 * didReceiveData
 *	delegate method
 */
- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
	[responseData_ appendData:data]; // append data to receive buffer
}

/**
 * connectionDidFinishLoading
 *	delegate method
 */
- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
	V(@"DeliciousPost.connectionDidFinishLoading: succeeded to load %d bytes", [responseData_ length]);

	[connection release];

	if (callback_ != nil) {
		NSString* resultCode = nil;
		NSXMLNode* node = nil;
		NSError* error = nil;
		NSXMLDocument* document =
			[[[NSXMLDocument alloc] initWithData:responseData_
																	 options:NSXMLDocumentTidyHTML
																		 error:&error] autorelease];
		node = [[document rootElement] attributeForName:@"code"];
		if (node != nil) {
			resultCode = [node stringValue];
		}
		V(@"resultCode: %@", resultCode);
		[self callback:@selector(successed:) withObject:[resultCode retain]];
	}
	else {
		[self callback:@selector(failedWithError:) withObject:nil];
	}

	[responseData_ release]; /* release receive buffer */
	responseData_ = nil;
}
@end

#pragma mark -
@implementation DeliciousPost (Private)
/**
 * create POST request
 */
- (NSURLRequest*) createRequest:(NSDictionary*)params
{
	@try {
		NSMutableString* ms = [[[NSMutableString alloc] initWithString:API_ADD_ENDPOINT] autorelease];
		NSEnumerator* enumerator = [params keyEnumerator];
		NSString* key;
		while ((key = [enumerator nextObject]) != nil) {
			[ms appendFormat:@"&%@=%@", key, [params objectForKey:key]];
		}
		NSString* s = [NSString stringWithString:ms];
		s = [s stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		s = [s stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];

		/* create the POST request */
		NSMutableURLRequest* request =
			[NSMutableURLRequest requestWithURL:[NSURL URLWithString:s]
															cachePolicy:NSURLRequestReloadIgnoringCacheData
													timeoutInterval:TIMEOUT];
#if 0
    s = [NSString stringWithFormat:@"%@:%@", [DeliciousPost username], [DeliciousPost password]];
    s = [NSString stringWithFormat:@"Basic %@", [[s dataUsingEncoding:NSASCIIStringEncoding] encodeBase64]];
    [request setValue:s forHTTPHeaderField: @"Authorization"];
		[request setHTTPShouldHandleCookies:NO];
#endif
		[request setValue:@"Tumblrful" forHTTPHeaderField:@"User-Agent"];

		//V(@"request: %@", SafetyDescription(request));
		return request;
	}
	@catch (NSException* e) {
		V(@"Exception: %@", [e description]);
	}
	return nil;
}

/**
 * didFailWithError
 *	delegate method
 */
- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
	V(@"DeliciousPost.didFailWithError: in, NSError:%@", [error description]);

	[connection release];
	[responseData_ release];	/* release receive buffer */

	[self callback:@selector(failedWithError:) withObject:error];
}

/**
	callback on MainThread
 */
- (void) callback:(SEL)selector withObject:(id)obj
{
	if (callback_ != nil && [callback_ respondsToSelector:selector]) {
		[callback_ performSelectorOnMainThread:selector withObject:obj waitUntilDone:NO];
	}
}
@end
