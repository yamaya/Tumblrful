/**
 * @file UmesuePost.m
 * @brief UmesuePost implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-28
 */
// /System/Library/Frameworks/Foundation.framework/Headers/NSXMLDocument.h
// /System/Library/Frameworks/Foundation.framework/Headers/NSXMLNode.h
#import "UmesuePost.h"
#import "UserSettings.h"
#import "DebugLog.h"
#import "NSDataBase64.h"
#import <Foundation/NSXMLDocument.h>

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

#define TIMEOUT (30.0)

#pragma mark -
@interface UmesuePost (Private)
- (void) callback:(SEL)selector withObject:(id)obj;
- (NSString*) makeAuthorization;
@end

#pragma mark -
@interface NSDictionary (PrivateForUmesue)
- (NSData*) umesueXML;
@end

#pragma mark -
@implementation UmesuePost
/**
 * get name of account on umesue
 */
+ (NSString*) username
{
	return [[UserSettings sharedInstance] stringForKey:@"otherTumblogLoginName"];
}

/**
 * get passowrd of account on umesue
 */
+ (NSString*) password
{
	return [[UserSettings sharedInstance] stringForKey:@"otherTumblogPassword"];
}

/**
  get post URL endpoint
 */
+ (NSString*) endpoint
{
	NSString* uri = [[UserSettings sharedInstance] stringForKey:@"otherTumblogSiteURL"];
	/* 行末の '/' を取り除いて */
	NSString* endpoint = [NSString stringWithFormat:@"%@/posts.xml", [uri stringByDeletingPathExtension]];
	return endpoint;
}

/**
 * get enable on umesue
 */
+ (BOOL) isEnabled
{
	return [[UserSettings sharedInstance] boolForKey:@"otherTumblogEnabled"];
}

/**
 * initWithCallback
 *	@param callback コールバックオブジェクト
 */
- (id) initWithCallback:(NSObject<PostCallback>*)callback
{
	if ((self = [super init]) != nil) {
		callback_ = [callback retain];
		responseData_ = nil;
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
	if (responseData_ != nil) {
		[responseData_ release];
		responseData_ = nil;
	}
	[super dealloc];
}

/**
 * create minimum request param for umesue.
 *	@return NSMutableDictionary オブジェクト
 */
- (NSMutableDictionary*) createMinimumRequestParams
{
	return [[NSMutableDictionary alloc] init];
}

/**
 * プライベートか否かを返す.
 *	@return プライベートフラグ
 */
- (BOOL) privated
{
	return NO;
}

/**
 * post to umesue.
 *	@param params - request parameteres
 *	@param delegate - delegate for NSURLConnection
 */
- (void) postWith:(NSDictionary*)params
{
	NSMutableURLRequest* request =
	[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[UmesuePost endpoint]]
							cachePolicy:NSURLRequestReloadIgnoringCacheData
						timeoutInterval:TIMEOUT];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/xml" forHTTPHeaderField:@"Content-type"];
	[request addValue:[self makeAuthorization] forHTTPHeaderField:@"Authorization"];
	[request setHTTPBody:[params umesueXML]];

	V(@"UmesuePost.post: request: %@", [request description]);

	NSURLConnection* connection =
		[NSURLConnection connectionWithRequest:request delegate:self];
	[connection retain];

	V(@"UmesuePost.post connection: %@", SafetyDescription(connection));
	if (connection == nil) {
		[self callback:@selector(failedWithError:) withObject:nil];
	}
}

/**
 * didReceiveAuthenticationChallenge
 *	delegate method
 */
- (void)connection:(NSURLConnection*)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
#pragma unused (connection)
	V(@"didReceiveAuthenticationChallenge: %@", @"enter");

	NSURLCredential* crendential =
		[NSURLCredential credentialWithUser:[UmesuePost username]
								   password:[UmesuePost password]
								persistence:NSURLCredentialPersistenceForSession];

	[[challenge sender] useCredential:crendential forAuthenticationChallenge:challenge];
}

/**
 * didReceiveResponse.
 * delegate method
 *	正常なら statusCode は 200
 *	Account 不正なら 403
 *	@param connection コネクション
 *	@param response レスポンス
 */
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
#pragma unused (connection)
	V(@"UmesuePost.didReceiveResponse retain:%x", [self retainCount]);

	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response; /* この cast は正しい */

	if ([httpResponse statusCode] == 200) {
		responseData_ = [[[NSMutableData alloc] init] retain];
	}
	else {
		Log(@"Error: statusCode=%d", [httpResponse statusCode]);
		Log(@"\tallHeaderFields=%@", [[httpResponse allHeaderFields] description]);
	}
}

/**
 * didReceiveData
 *	delegate method
 */
- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
#pragma unused (connection)
	if (responseData_ != nil) {
		[responseData_ appendData:data]; /* append data to receive buffer */
	}
}

/**
 * connectionDidFinishLoading
 *	@param connection NSURLConnection オブジェクト
 */
- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
	V(@"UmesuePost.connectionDidFinishLoading: succeeded to load %d bytes", [responseData_ length]);

	[connection release];

	if (callback_ != nil && responseData_ != nil) {
		NSString* rc = nil;
		NSXMLNode* node = nil;
		NSError* error = nil;
		NSXMLDocument* document =
			[[[NSXMLDocument alloc] initWithData:responseData_
										 options:NSXMLDocumentTidyXML
										   error:&error] autorelease];
		V(@"response=%@", [document description]);
		node = [[document rootElement] attributeForName:@"action"];
		if (node != nil) {
			rc = [node stringValue];
		}
		V(@"result: %@", rc);
		[self callback:@selector(successed:) withObject:[rc retain]];
	}
	else {
		[self callback:@selector(failedWithError:) withObject:nil];
	}
}

/**
 * didFailWithError
 *	delegate method
 */
- (void) connection:(NSURLConnection*)connection
	 didFailWithError:(NSError*)error
{
	V(@"UmesuePost.didFailWithError: in, NSError:%@", [error description]);

	[connection release];

	[self callback:@selector(failedWithError:) withObject:error];
}

@end

#pragma mark -
@implementation UmesuePost (Private)
/**
	callback on MainThread
 */
- (void) callback:(SEL)selector withObject:(id)obj
{
	if (callback_ != nil && [callback_ respondsToSelector:selector]) {
		[callback_ performSelectorOnMainThread:selector withObject:obj waitUntilDone:NO];
	}
}

/**
 * make Basic Authorization string
 *	@return HTTPヘッダに設定する BASIC認証文字列
 */
- (NSString*) makeAuthorization
{
	NSString* s = [NSString stringWithFormat:@"%@:%@", [UmesuePost username], [UmesuePost password]];
	NSData* d = [s dataUsingEncoding:NSASCIIStringEncoding];
	return [NSString stringWithFormat:@"Basic %@", [d encodeBase64WithNL:NO]];
}

@end

#pragma mark -
@implementation NSDictionary (PrivateForUmesue)
/**
 * make XML for umesue
 */
- (NSData*) umesueXML
{
	NSXMLDocument* xml = [[[NSXMLDocument alloc] init] autorelease];
	[xml setDocumentContentKind:NSXMLDocumentXMLKind];
	[xml setVersion:@"1.0"];
	[xml setCharacterEncoding:@"UTF-8"];

	NSXMLElement* element = [[[NSXMLElement alloc] initWithName:@"post"] autorelease];

	[xml addChild:element];

	NSEnumerator* enumerator = [self keyEnumerator];
	NSString* key;
	NSXMLElement* node;
	while ((key = [enumerator nextObject]) != nil) {
		node = [[[NSXMLElement alloc] initWithName:key] autorelease];
		[node setStringValue:[self objectForKey:key]];

		[element addChild:node];
	}
	NSData* data = [xml XMLDataWithOptions:NSXMLDocumentTidyXML];

	//NSString* debug = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	//V(@"umesueXML: %@", debug);
	return data;
}
@end
