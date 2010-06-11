/**
 * @file TumblrPost.m
 * @brief TumblrPost implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "TumblrPost.h"
#import "UserSettings.h"
#import "DebugLog.h"
#import <WebKit/WebKit.h>
#import <Foundation/NSXMLDocument.h>

static NSString* WRITE_URL = @"http://www.tumblr.com/api/write";
static NSString* TUMBLR_URL = @"http://www.tumblr.com";
static NSString* EXCEPTION_NAME = @"TumblrPostException";
static float TIMEOUT = 60.0f;

#pragma mark -
@interface NSString (URLEncoding)
- (NSString *)stringByURLEncoding:(NSStringEncoding)encoding;
@end

@implementation NSString (URLEncoding)

/**
 * URL エンコーディングを行う
 * @param [in] encoding エンコーディング
 * @return NSString オブジェクト
 */
- (NSString *)stringByURLEncoding:(NSStringEncoding)encoding
{
	NSArray* escapeChars = [NSArray arrayWithObjects:
			 @";" ,@"/" ,@"?" ,@":"
			,@"@" ,@"&" ,@"=" ,@"+"
			,@"$" ,@"," ,@"[" ,@"]"
			,@"#" ,@"!" ,@"'" ,@"("
			,@")" ,@"*"
			,nil];

	NSArray* replaceChars = [NSArray arrayWithObjects:
			  @"%3B" ,@"%2F" ,@"%3F"
			 ,@"%3A" ,@"%40" ,@"%26"
			 ,@"%3D" ,@"%2B" ,@"%24"
			 ,@"%2C" ,@"%5B" ,@"%5D"
			 ,@"%23" ,@"%21" ,@"%27"
			 ,@"%28" ,@"%29" ,@"%2A"
			 ,nil];

	NSMutableString* encodedString =
		[[[self stringByAddingPercentEscapesUsingEncoding:encoding] mutableCopy] autorelease];

	const NSUInteger N = [escapeChars count];
	for (NSUInteger i = 0; i < N; i++) {
		[encodedString replaceOccurrencesOfString:[escapeChars objectAtIndex:i]
									   withString:[replaceChars objectAtIndex:i]
										  options:NSLiteralSearch
											range:NSMakeRange(0, [encodedString length])];
	}

	return [NSString stringWithString: encodedString];
}
@end

#pragma mark -
@interface TumblrReblogDelegate : NSObject
{
	NSString * endpoint_;	/**< url */
	TumblrPost *	continuation_;
	NSMutableData * responseData_;	/**< for NSURLConnection */
}
- (id) initWithEndpoint:(NSString*)endpoint continuation:(TumblrPost*)continuation;
- (void) dealloc;
@end

#pragma mark -
@interface TumblrPost (Private)
- (void) invokeCallback:(SEL)selector withObject:(NSObject*)param;
- (NSString*) detectPostType:(NSArray*)inputs;
- (NSMutableDictionary*) collectInputFieldsAsLink:(NSArray*)elements;
- (NSMutableDictionary*) collectInputFieldsAsPhoto:(NSArray*)elements;
- (NSMutableDictionary*) collectInputFieldsAsQuote:(NSArray*)elements;
- (NSMutableDictionary*) collectInputFieldsAsRegular:(NSArray*)elements;
- (NSMutableDictionary*) collectInputFieldsAsChat:(NSArray*)elements;
- (NSMutableDictionary*) collectInputFieldsAsVideo:(NSArray*)elements;
- (void) addElementIfFormKey:(NSXMLElement*)element fields:(NSMutableDictionary*)fields;
// TODO: support "audio"
- (NSArray*) collectInputFields:(NSData*)form;
- (void) reblogPost:(NSString*)endpoint form:(NSData*)formData;
@end

@implementation TumblrPost (Private)
/**
 * MainThread上でコールバックする
 */
- (void) invokeCallback:(SEL)selector withObject:(NSObject*)param
{
	if (callback_) {
		if ([callback_ respondsToSelector:selector]) {
			[callback_ performSelectorOnMainThread:selector withObject:param waitUntilDone:NO];
		}
	}
}

/**
 * form HTMLからfieldを得る.
 * @param formData フォームデータ
 * @return フィールド(DOM要素)
 */
- (NSArray*) collectInputFields:(NSData*)formData
{
	static NSString* EXPR = @"//div[@id=\"container\"]/div[@id=\"content\"]/form[@id=\"edit_post\"]//(input[starts-with(@name, \"post\")] | textarea[starts-with(@name, \"post\")] | input[@id=\"form_key\"])";

	/* UTF-8 文字列にしないと後の [attribute stringValue] で日本語がコードポイント表記になってしまう */
	NSString* html = [[[NSString alloc] initWithData:formData encoding:NSUTF8StringEncoding] autorelease];

	/* DOMにする */
	NSError* error = nil;
	NSXMLDocument* document = [[NSXMLDocument alloc] initWithXMLString:html options:NSXMLDocumentTidyHTML error:&error];
	if (document == nil) {
		[NSException raise:EXCEPTION_NAME format:@"Couldn't make DOMDocument. error: %@", [error description]];
	}

	NSArray* inputs = [[document rootElement] nodesForXPath:EXPR error:&error];
	if (inputs == nil) {
		[NSException raise:EXCEPTION_NAME format:@"Failed nodesForXPath. error: %@", [error description]];
	}

	return inputs;
}

/**
 * input(NSXMLElement) array から post[type] の value を得る
 */
- (NSString*) detectPostType:(NSArray*)inputs
{
	NSRange empty = NSMakeRange(NSNotFound, 0);

	NSEnumerator* enumerator = [inputs objectEnumerator];
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];

		if (!NSEqualRanges([name rangeOfString:@"post[type]"], empty)) {
			return [[element attributeForName:@"value"] stringValue];
		}
	}
	return nil;
}

/**
 * "Link" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsLink:(NSArray*)elements
{
	NSMutableDictionary* fields = [[NSMutableDictionary alloc] init];
	[fields setValue:@"link" forKey:@"post[type]"];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSRange empty = NSMakeRange(NSNotFound, 0);
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];
		NSXMLNode* attribute;
		NSString* value;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], empty)) {
			attribute = [element attributeForName:@"value"];
			value = [attribute stringValue];
			[fields setValue:value forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], empty)) {
			[fields setValue:[[element attributeForName:@"value"] stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], empty)) {
			[fields setValue:[element stringValue] forKey:@"post[three]"];
		}
		else {
			[self addElementIfFormKey:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Photo" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsPhoto:(NSArray*)elements
{
	NSMutableDictionary* fields = [[NSMutableDictionary alloc] init];
	[fields setValue:@"photo" forKey:@"post[type]"];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSRange empty = NSMakeRange(NSNotFound, 0);
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];
		NSXMLNode* attribute;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], empty)) {
			/* one は出現しない？ */
			D0(@"post[one] is not implemented in Reblog(Photo).");
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], empty)) {
			[fields setValue:[element stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], empty)) {
			attribute = [element attributeForName:@"value"];
			[fields setValue:[attribute stringValue] forKey:@"post[three]"];
		}
		else {
			[self addElementIfFormKey:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Quote" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsQuote:(NSArray*)elements
{
	NSMutableDictionary* fields = [[NSMutableDictionary alloc] init];
	[fields setValue:@"quote" forKey:@"post[type]"];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSRange empty = NSMakeRange(NSNotFound, 0);
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], empty)) {
			[fields setValue:[element stringValue] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], empty)) {
			[fields setValue:[element stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], empty)) {
			/* three は出現しない？ */
			D0(@"post[three] is not implemented in Reblog(Quote).");
		}
		else {
			[self addElementIfFormKey:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Regular" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsRegular:(NSArray*)elements
{
	NSMutableDictionary* fields = [[NSMutableDictionary alloc] init];
	[fields setValue:@"regular" forKey:@"post[type]"];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSRange empty = NSMakeRange(NSNotFound, 0);
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];
		NSXMLNode* attribute;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], empty)) {
			attribute = [element attributeForName:@"value"];
			[fields setValue:[attribute stringValue] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], empty)) {
			[fields setValue:[element stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], empty)) {
			/* three は出現しない？ */
			D0(@"post[three] is not implemented in Reblog(Quote).");
		}
		else {
			[self addElementIfFormKey:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Conversation" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsChat:(NSArray*)elements
{
	NSMutableDictionary* fields = [[NSMutableDictionary alloc] init];
	[fields setValue:@"conversation" forKey:@"post[type]"];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSRange empty = NSMakeRange(NSNotFound, 0);
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], empty)) {
			NSXMLNode* attribute = [element attributeForName:@"value"];
			[fields setValue:[attribute stringValue] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], empty)) {
			[fields setValue:[element stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], empty)) {
			/* three は出現しない？ */
			D0(@"post[three] is not implemented in Reblog(Conversation).");
		}
		else {
			[self addElementIfFormKey:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Video" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsVideo:(NSArray*)elements
{
	NSMutableDictionary* fields = [[NSMutableDictionary alloc] init];
	[fields setValue:@"video" forKey:@"post[type]"];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSRange empty = NSMakeRange(NSNotFound, 0);
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], empty)) {
			[fields setValue:[element stringValue] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], empty)) {
			[fields setValue:[element stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], empty)) {
			/* three は出現しない？ */
			D0(@"post[three] is not implemented in Reblog(Video).");
		}
		else {
			[self addElementIfFormKey:element fields:fields];
		}
	}

	return fields;
}

/**
 * elementの要素名がformKeyであれば fields に追加する.
 */
- (void) addElementIfFormKey:(NSXMLElement*)element fields:(NSMutableDictionary*)fields
{
	NSRange empty = NSMakeRange(NSNotFound, 0);
	NSString* name = [[element attributeForName:@"name"] stringValue];

	if (!NSEqualRanges([name rangeOfString:@"form_key"], empty)) {
		NSXMLNode* attribute = [element attributeForName:@"value"];
		[fields setValue:[attribute stringValue] forKey:@"form_key"];
	}
}

/**
 * reblogPost.
 * @param endpoint ポスト先のURI
 * @param formData form データ
 */
- (void) reblogPost:(NSString*)endpoint form:(NSData*)formData
{
	NSArray* inputs = [self collectInputFields:formData];
	NSString* type = [self detectPostType:inputs];

	if (type != nil) {
		NSMutableDictionary* fields = nil;

		if ([type isEqualToString:@"link"]) {
			fields = [self collectInputFieldsAsLink:inputs];
		}
		else if ([type isEqualToString:@"photo"]) {
			fields = [self collectInputFieldsAsPhoto:inputs];
		}
		else if ([type isEqualToString:@"quote"]) {
			fields = [self collectInputFieldsAsQuote:inputs];
		}
		else if ([type isEqualToString:@"regular"]) {
			fields = [self collectInputFieldsAsRegular:inputs];
		}
		else if ([type isEqualToString:@"conversation"]) {
			fields = [self collectInputFieldsAsChat:inputs];
		}
		else if ([type isEqualToString:@"video"]) {
			fields = [self collectInputFieldsAsVideo:inputs];
		}
		else {
			[NSException raise:EXCEPTION_NAME format:@"Unknwon Reblog form. post type was invalid. type: %@", SafetyDescription(type)];
			return;
		}
		if (fields == nil) {
			[NSException raise:EXCEPTION_NAME format:@"Unknwon Reblog form. not found post[one|two|three] fields. type: %@", SafetyDescription(type)];
			return;
		}
		else if ([fields count] < 2) { /* type[post] + 1このフィールドは絶対あるはず */
			[NSException raise:EXCEPTION_NAME format:@"Unknwon Reblog form. too few fields. type: %@", SafetyDescription(type)];
			return;
		}

		NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
		[params setValue:type forKey:@"type"];
		if (queuing_)
			[params setValue:@"2" forKey:@"post[state]"];	// queuing post
		[params addEntriesFromDictionary:fields];

		/* Tumblrへポストする */
		[self postTo:endpoint params:params];
	}
}
@end

#pragma mark -
@implementation TumblrReblogDelegate

- (id)initWithEndpoint:(NSString *)endpoint continuation:(TumblrPost *)continuation
{
	if ((self = [super init]) != nil) {
		endpoint_ = [endpoint retain];
		continuation_ = [continuation retain];
		responseData_ = nil;
	}
	return self;
}

- (void) dealloc
{
	[endpoint_ release];
	[continuation_ release];
	[responseData_ release];

	[super dealloc];
}

/**
 * didReceiveResponse デリゲートメソッド.
 *	@param connection NSURLConnection オブジェクト
 *	@param response NSURLResponse オブジェクト
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused (connection)
	/* この cast は正しい */
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse *)response;

	if ([httpResponse statusCode] == 200) {
		responseData_ = [[NSMutableData data] retain];
	}
}

/**
 * didReceiveData デリゲートメソッド.
 *	@param connection NSURLConnection オブジェクト
 *	@param response data NSData オブジェクト
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#pragma unused (connection)
	if (responseData_ != nil) {
		[responseData_ appendData:data];
	}
}

/**
 * connectionDidFinishLoading.
 * @param connection コネクション
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#pragma unused (connection)
	if (continuation_ != nil) {
		[continuation_ reblogPost:endpoint_ form:responseData_];
	}
	else {
		NSError * error = [NSError errorWithDomain:@"TumblrfulErrorDomain" code:-1 userInfo:nil];
		[continuation_ invokeCallback:@selector(failed:) withObject:error]; /* 失敗時の処理 */
	}

	[responseData_ release];
	responseData_ = nil;

	[self release];
}

/**
 * エラーが発生した場合.
 * @param connection コネクション
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused (connection, error)
	D0([error description]);
	[self release];
}
@end // TumblrReblogDelegate

#pragma mark -
@implementation TumblrPost

@synthesize privated = private_;
@synthesize queuingEnabled = queuing_;

- (id)initWithCallback:(NSObject<PostCallback> *)callback
{
	if ((self = [super init]) != nil) {
		callback_ = [callback retain];

		UserSettings * defaults = [UserSettings sharedInstance];
		private_ = [defaults boolForKey:@"tumblrPrivateEnabled"];
		queuing_ = [defaults boolForKey:@"tumblrQueuingEnabled"];
		responseData_ = nil;
	}
	return self;
}

- (void) dealloc
{
	[callback_ release];
	[responseData_ release];

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
	NSMutableString * escaped = [[[NSMutableString alloc] init] autorelease];

	/* create the body */
	/* add key-values from the NSDictionary object */
	NSEnumerator * enumerator = [params keyEnumerator];
	NSString * key;
	while ((key = [enumerator nextObject]) != nil) {
        NSObject * any = [params objectForKey:key]; 
		NSString * value;
        if ([any isMemberOfClass:[NSURL class]]) {
            value = [(NSURL *)any absoluteString];
        }
        else {
            value = (NSString*)any;
        }
		value = [value stringByURLEncoding:NSUTF8StringEncoding];
		[escaped appendFormat:@"&%@=%@", key, value];
		D0(escaped);
	}

	/* create the POST request */
	NSMutableURLRequest * request =
		[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
								cachePolicy:NSURLRequestReloadIgnoringCacheData
							timeoutInterval:TIMEOUT];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[escaped dataUsingEncoding:NSUTF8StringEncoding]];

	return request;
}

#ifdef SUPPORT_MULTIPART_PORT
/**
 * create multipart POST request
 */
-(NSURLRequest *)createRequestForMultipart:(NSDictionary *)params withData:(NSData *)data
{
	static NSString* HEADER_BOUNDARY = @"0xKhTmLbOuNdArY";

	// create the URL POST Request to tumblr
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:WRITE_URL]];

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

/**
 * post to Tumblr.
 *	@param params - request parameteres
 */
- (void)postWith:(NSDictionary *)params
{
	[self postTo:WRITE_URL params:params];
}

- (void)postTo:(NSString *)url params:(NSDictionary *)params
{
	responseData_ = [[NSMutableData data] retain];

	NSURLRequest * request = [self createRequest:url params:params];	// request は connection に指定した時点で reatin upする
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];

	if (connection == nil) {
		[self invokeCallback:@selector(failed:) withObject:nil];
		[responseData_ release];
		responseData_ = nil;
		return;
	}

	[connection retain];
}

/**
 * reblog
 *	@param postID ポストのID(整数値)
 */
- (NSObject *)reblog:(NSString *)postID key:(NSString *)reblogKey
{
	NSString * endpoint = [NSString stringWithFormat:@"%@/reblog/%@/%@", TUMBLR_URL, postID, reblogKey];
	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];

	TumblrReblogDelegate * delegate = [[TumblrReblogDelegate alloc] initWithEndpoint:endpoint continuation:self];
	[delegate retain];

	NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:delegate];

	if (connection == nil) {
		[NSException raise:EXCEPTION_NAME format:@"Couldn't get Reblog form. endpoint: %@", endpoint];
	}

	return @""; /* なんとかならんかなぁ */
}

/**
 * didReceiveResponse デリゲートメソッド
 *	@param connection NSURLConnection オブジェクト
 *	@param response NSURLResponse オブジェクト
 *
 *	正常なら statusCode は 201
 *	Account 不正なら 403
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused (connection)
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response; /* この cast は正しい */

	NSInteger const httpStatus = [httpResponse statusCode];
	if (httpStatus != 201 && httpStatus != 200) {
		D(@"statusCode:%d", httpStatus);
		D(@"ResponseHeader:%@", [[httpResponse allHeaderFields] description]);
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
	[connection release];

	if (callback_ != nil) {
		[self invokeCallback:@selector(posted:) withObject:responseData_];
	}
	else {
		NSError * error = [NSError errorWithDomain:@"TumblrfulErrorDomain" code:-1 userInfo:nil];
		[self invokeCallback:@selector(failed:) withObject:error];
	}

	[responseData_ release]; /* release receive buffer */
	[self release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	D0([error description]);

	[connection release];

	[responseData_ release];	/* release receive buffer */

	[self invokeCallback:@selector(failed:) withObject:error];
	[self release];
}
@end
