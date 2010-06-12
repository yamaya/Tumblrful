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

static const NSRange EmptyRange = {NSNotFound, 0};


#pragma mark -

@interface ReblogDelegate : NSObject
{
	NSString * endpoint_;
	TumblrPost * postman_;
	NSMutableData * data_;
}

- (id)initWithEndpoint:(NSString *)endpoint withPostman:(TumblrPost *)postman;
@end

#pragma mark -

@interface TumblrPost ()
- (void)postWithEndpoint:(NSString *)url withParams:(NSDictionary *)params;
- (void)reblogPostWithPostID:(NSString *)postID reblogKey:(NSString *)reblogKey;
- (void)callbackOnMainThread:(SEL)selector withObject:(NSObject *)param;
- (NSString *)postTypeWithElements:(NSArray *)elements;
- (NSMutableDictionary *)collectInputFieldsAsLink:(NSArray *)elements;
- (NSMutableDictionary *)collectInputFieldsAsPhoto:(NSArray *)elements;
- (NSMutableDictionary *)collectInputFieldsAsQuote:(NSArray *)elements;
- (NSMutableDictionary *)collectInputFieldsAsRegular:(NSArray *)elements;
- (NSMutableDictionary *)collectInputFieldsAsChat:(NSArray *)elements;
- (NSMutableDictionary *)collectInputFieldsAsVideo:(NSArray *)elements;
- (NSMutableDictionary *)collectInputFieldsAsAudio:(NSArray *)elements;
- (void)setFormKeyFieldIfExist:(NSXMLElement *)element fields:(NSMutableDictionary *)fields;
- (NSArray *)inputElementsWithReblogFrom:(NSData *)reblogForm;
- (void)reblogPost:(NSString *)endpoint form:(NSData *)formData;
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
		[self reblogPostWithPostID:[params objectForKey:@"pid"] reblogKey:[params objectForKey:@"rk"]];
	}
	else {
		[self postWithEndpoint:TUMBLRFUL_TUMBLR_WRITE_URL withParams:params];
	}
}

- (void)postWithEndpoint:(NSString *)url withParams:(NSDictionary *)params
{
	D_METHOD;

	NSURLRequest * request = [self createRequest:url params:params];	// request は connection に指定した時点で reatin upする
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];	// autoreleased

	if (connection == nil) {
		[self callbackOnMainThread:@selector(failed:) withObject:nil];
	}
}

- (void)reblogPostWithPostID:(NSString *)postID reblogKey:(NSString *)reblogKey
{
	D(@"postid=%@ reblogkey=%@", postID, reblogKey);

	if (postID == nil || reblogKey == nil) {
		[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"invalid PostID:%@ or ReblogKey:%@", postID, reblogKey];
	}

	NSString * endpoint = [NSString stringWithFormat:@"%@/reblog/%@/%@", TUMBLRFUL_TUMBLR_URL, postID, reblogKey];
	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];
	ReblogDelegate * delegate = [[[ReblogDelegate alloc] initWithEndpoint:endpoint withPostman:self] retain];
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:delegate];

	if (connection == nil) {
		[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"Couldn't get Reblog form. endpoint: %@", endpoint];
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
		[self callbackOnMainThread:@selector(posted:) withObject:responseData_];
	}
	else {
		NSError * error = [NSError errorWithDomain:TUMBLRFUL_ERROR_DOMAIN code:-1 userInfo:nil];
		[self callbackOnMainThread:@selector(failed:) withObject:error];
	}

	[responseData_ release]; /* release receive buffer */
	[self release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused (connection)
	D0([error description]);

	[responseData_ release], responseData_ = nil;

	[self callbackOnMainThread:@selector(failed:) withObject:error];
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

- (void)callbackOnMainThread:(SEL)selector withObject:(NSObject *)object
{
	if (callback_ != nil && [callback_ respondsToSelector:selector]) {
		[callback_ performSelectorOnMainThread:selector withObject:object waitUntilDone:NO];
	}
}

/**
 * form HTMLからfieldを得る.
 *	@param[in] reblogForm フォームデータ
 *	@return フィールド(DOM要素) autoreleased
 */
- (NSArray *)inputElementsWithReblogFrom:(NSData *)reblogForm
{
	static NSString * XPath = @"//div[@id=\"container\"]/div[@id=\"content\"]/form[@id=\"edit_post\"]//(input[starts-with(@name, \"post\")] | textarea[starts-with(@name, \"post\")] | input[@id=\"form_key\"])";

	// UTF-8 文字列にしないと後の [attribute stringValue] で日本語がコードポイント表記になってしまう
	NSString * formString = [[[NSString alloc] initWithData:reblogForm encoding:NSUTF8StringEncoding] autorelease];

	// DOMにする
	NSError * error = nil;
	NSXMLDocument * document = [[[NSXMLDocument alloc] initWithXMLString:formString options:NSXMLDocumentTidyHTML error:&error] autorelease];
	if (document == nil) {
		NSString * message = [NSString stringWithFormat:@"Couldn't make DOMDocument. %@", [error description]];
		D0(message);
		[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"%@", message];
	}

	error = nil;
	NSArray * elements = [[document rootElement] nodesForXPath:XPath error:&error];
	if (elements == nil) {
		NSString * message = [NSString stringWithFormat:@"Failed nodesForXPath. %@", [error description]];
		D0(message);
		[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"%@", message];
	}

	D(@"elements retainCount=%d", [elements retainCount]);
	return elements;
}

/**
 * NSXMLElementの配列から post[type] の value を得る
 */
- (NSString *)postTypeWithElements:(NSArray *)elements
{
	NSEnumerator * enumerator = [elements objectEnumerator];
	NSXMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {
		NSString * name = [[element attributeForName:@"name"] stringValue];
		if (!NSEqualRanges([name rangeOfString:@"post[type]"], EmptyRange)) {
			return [[element attributeForName:@"value"] stringValue];
		}
	}
	return @"not-found";
}

/**
 * "Link" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsLink:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"link", @"post[type]", nil];

	NSEnumerator * enumerator = [elements objectEnumerator];
	NSXMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString * name = [[element attributeForName:@"name"] stringValue];

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			NSXMLNode * attribute = [element attributeForName:@"value"];
			NSString * value = [attribute stringValue];
			[fields setObject:value forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[[element attributeForName:@"value"] stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], EmptyRange)) {
			[fields setObject:[element stringValue] forKey:@"post[three]"];
		}
		else {
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Photo" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsPhoto:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"photo", @"post[type]", nil];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];
		NSXMLNode* attribute;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			/* one は出現しない？ */
			D0(@"post[one] is not implemented in Reblog(Photo).");
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[element stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], EmptyRange)) {
			attribute = [element attributeForName:@"value"];
			[fields setObject:[attribute stringValue] forKey:@"post[three]"];
		}
		else {
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Quote" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsQuote:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"quote", @"post[type]", nil];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			[fields setObject:[element stringValue] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[element stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], EmptyRange)) {
			/* three は出現しない？ */
			D0(@"post[three] is not implemented in Reblog(Quote).");
		}
		else {
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Regular" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsRegular:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"regular", @"post[type]", nil];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];
		NSXMLNode* attribute;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			attribute = [element attributeForName:@"value"];
			[fields setObject:[attribute stringValue] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[element stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], EmptyRange)) {
			/* three は出現しない？ */
			D0(@"post[three] is not implemented in Reblog(Quote).");
		}
		else {
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Conversation" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) collectInputFieldsAsChat:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"conversation", @"post[type]", nil];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			NSXMLNode* attribute = [element attributeForName:@"value"];
			[fields setObject:[attribute stringValue] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[element stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], EmptyRange)) {
			/* three は出現しない？ */
			D0(@"post[three] is not implemented in Reblog(Conversation).");
		}
		else {
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Video" post type の時の input fields の抽出
 */
- (NSMutableDictionary *)collectInputFieldsAsVideo:(NSArray *)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"video", @"post[type]", nil];

	NSEnumerator* enumerator = [elements objectEnumerator];
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			[fields setObject:[element stringValue] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[element stringValue] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], EmptyRange)) {
			/* three は出現しない？ */
			D0(@"post[three] is not implemented in Reblog(Video).");
		}
		else {
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/**
 * "Audio" post type の時の input fields の抽出
 */
- (NSMutableDictionary *)collectInputFieldsAsAudio:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"audio", @"post[type]", nil];

	NSEnumerator * enumerator = [elements objectEnumerator];
	NSXMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString * name = [[element attributeForName:@"name"] stringValue];

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			[fields setObject:[element stringValue] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[element stringValue] forKey:@"post[two]"];
		}
		else {
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/**
 * elementの要素名がformKeyであれば fields に追加する.
 */
- (void)setFormKeyFieldIfExist:(NSXMLElement *)element fields:(NSMutableDictionary *)fields
{
	NSString * name = [[element attributeForName:@"name"] stringValue];

	if (!NSEqualRanges([name rangeOfString:@"form_key"], EmptyRange)) {
		NSXMLNode * attribute = [element attributeForName:@"value"];
		[fields setObject:[attribute stringValue] forKey:@"form_key"];
	}
}

/**
 * reblogPost.
 *	@param[in] endpoint ポスト先のURI
 *	@param[in] formData Reblog画面のHTML
 */
- (void)reblogPost:(NSString *)endpoint form:(NSData *)formData
{
	D_METHOD;

	NSArray * elements = [self inputElementsWithReblogFrom:formData];
	NSString * type = [self postTypeWithElements:elements];

	NSMutableDictionary * fields = nil;
	if ([type isEqualToString:@"link"])					fields = [self collectInputFieldsAsLink:elements];
	else if ([type isEqualToString:@"photo"])			fields = [self collectInputFieldsAsPhoto:elements];
	else if ([type isEqualToString:@"quote"])			fields = [self collectInputFieldsAsQuote:elements];
	else if ([type isEqualToString:@"regular"])			fields = [self collectInputFieldsAsRegular:elements];
	else if ([type isEqualToString:@"conversation"])	fields = [self collectInputFieldsAsChat:elements];
	else if ([type isEqualToString:@"video"])			fields = [self collectInputFieldsAsVideo:elements];
	else if ([type isEqualToString:@"audio"])			fields = [self collectInputFieldsAsAudio:elements];

	if (fields == nil) {
		NSString * message = [NSString stringWithFormat:@"Unrecognized Reblog form. type:%@", SafetyDescription(type)];
		D0(message);
		[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"%@", message];
	}
	else if ([fields count] < 2) { // type[post] + 1このフィールドは絶対あるはず
		NSString * message = [NSString stringWithFormat:@"Unrecognized Reblog form. too few fields. type:%@", SafetyDescription(type)];
		[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"%@", message];
		return;
	}

	NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:type, @"type", nil];
	if (queuing_) [params setObject:@"2" forKey:@"post[state]"];	// queuing post
	[params addEntriesFromDictionary:fields];

	// Tumblrへポストする
	[self postWithEndpoint:endpoint withParams:params];
}
@end // TumblrPost

#pragma mark -
#pragma mark Delegate class implementation

@implementation ReblogDelegate

- (id)initWithEndpoint:(NSString *)endpoint withPostman:(TumblrPost *)postman
{
	if ((self = [super init]) != nil) {
		endpoint_ = [endpoint retain];
		postman_ = [postman retain];
		data_ = nil;
	}
	return self;
}

- (void)dealloc
{
	[endpoint_ release], endpoint_ = nil;
	[postman_ release], postman_ = nil;
	[data_ release], data_ = nil;

	[super dealloc];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused (connection)
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;

	D(@"HTTP status=%d", [httpResponse statusCode]);;

	if ([httpResponse statusCode] == 200) {
		data_ = [[NSMutableData data] retain];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#pragma unused (connection)
	D_METHOD;

	if (data_ != nil) {
		[data_ appendData:data];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#pragma unused (connection)
	D_METHOD;

	if (postman_ != nil) {
		[postman_ reblogPost:endpoint_ form:data_];
	}
	else {
		NSError * error = [NSError errorWithDomain:TUMBLRFUL_ERROR_DOMAIN code:-1 userInfo:nil];
		[postman_ callbackOnMainThread:@selector(failed:) withObject:error];
	}

	[self release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused (connection, error)
	D0([error description]);

	[self release];
}
@end // ReblogDelegate
