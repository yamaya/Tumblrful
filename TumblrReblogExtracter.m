/**
 * @file TumblrReblogExtracter.m
 * @brief TumblrReblogExtracter implementation
 * @author Masayuki YAMAYA
 * @date 2008-04-23
 */
#import "TumblrReblogExtracter.h"
#import "DebugLog.h"

static NSString* TUMBLR_URL = @"http://www.tumblr.com";

@interface TumblrReblogExtracter (Private)
- (NSString*)typeofPost:(NSArray*)inputs;
- (NSArray*)inputFields:(NSData*)form;
- (NSMutableDictionary*)inputFieldsAsLink:(NSArray*)elements;
- (NSMutableDictionary*)inputFieldsAsPhoto:(NSArray*)elements;
- (NSMutableDictionary*)inputFieldsAsQuote:(NSArray*)elements;
- (NSMutableDictionary*)inputFieldsAsRegular:(NSArray*)elements;
- (NSMutableDictionary*)inputFieldsAsChat:(NSArray*)elements;
- (NSMutableDictionary*)inputFieldsAsVideo:(NSArray*)elements;
// TODO: support "audio"
- (void)extractImpl:(NSString*)endpoint form:(NSData*)formData;
@end

@implementation TumblrReblogExtracter
/**
 * endpointから reblog form を取得して field に展開する.
 */
- (void)extract:(NSString*)pid key:(NSString*)rk
{
	if (continuation_ == nil) {
		D(@"exract: continuation_ is nil, pid=%@, rk=%@", pid, rk);
		return;
	}
	if (![continuation_ respondsToSelector:@selector(extract:)]) {
		D(@"exract: Not respond is \"extract\", continuation_=%@", [continuation_ description]);
		return;
	}

	endpoint_ = [NSString stringWithFormat:@"%@/reblog/%@/%@", TUMBLR_URL, pid, rk];
	[endpoint_ retain];

	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint_]];
	NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
	if (connection == nil) {
		D(@"Couldn't get reblog form. endpoint: %@", endpoint_);
	}
}

/**
 */
- (id)initWith:(id)continuation
{
	if ((self = [super init]) != nil) {
		continuation_ = [continuation retain];
		endpoint_ = nil;
		responseData_ = nil;
	}
	return self;
}

/**
 */
- (void)dealloc
{
	if (endpoint_ != nil) {
		[endpoint_ release];
		endpoint_ = nil;
	}
	if (continuation_ != nil) {
		[continuation_ release];
		continuation_ = nil;
	}
	if (responseData_ != nil) {
		[responseData_ release];
		responseData_ = nil;
	}
	[super dealloc];
}

/**
 * didReceiveResponse デリゲートメソッド.
 *	@param connection NSURLConnection オブジェクト
 *	@param response NSURLResponse オブジェクト
 */
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
	/* この cast は正しい */
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;

	if ([httpResponse statusCode] == 200) {
		responseData_ = [[NSMutableData data] retain];
	}
	else {
		D(@"didReceiveResponse: statusCode=%d", [httpResponse statusCode]);
	}
}

/**
 * didReceiveData デリゲートメソッド.
 *	@param connection NSURLConnection オブジェクト
 *	@param response data NSData オブジェクト
 */
- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
	if (responseData_ != nil) {
		[responseData_ appendData:data];
	}
}

/**
 * connectionDidFinishLoading
 */
- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
	D(@"didReceiveData: connectionDidFinishLoading length=%d", [responseData_ length]);

	[self extractImpl:endpoint_ form:responseData_];
	[self release];
}

/**
 * didFailWithError.
 *	@param connection
 *	@param error
 */
- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
	D(@"didFailWithError: %@", [error description]);
	[self release];
}
@end

@implementation TumblrReblogExtracter (Private)
/**
 * extractImpl.
 *	@param endpoint
 *	@param formData
 */
- (void)extractImpl:(NSString*)endpoint form:(NSData*)formData
{
	NSArray* inputs = [self inputFields:formData];
	NSString* type = [self typeofPost:inputs];

	if (type == nil) {
		return;
	}

	NSMutableDictionary* fields = nil;

	if ([type isEqualToString:@"link"]) {
		fields = [self inputFieldsAsLink:inputs];
	}
	else if ([type isEqualToString:@"photo"]) {
		fields = [self inputFieldsAsPhoto:inputs];
	}
	else if ([type isEqualToString:@"quote"]) {
		fields = [self inputFieldsAsQuote:inputs];
	}
	else if ([type isEqualToString:@"regular"]) {
		fields = [self inputFieldsAsRegular:inputs];
	}
	else if ([type isEqualToString:@"conversation"]) {
		fields = [self inputFieldsAsChat:inputs];
	}
	else if ([type isEqualToString:@"video"]) {
		fields = [self inputFieldsAsVideo:inputs];
	}
	else {
		D(@"Unknwon Reblog form. post type was invalid. type: %@", SafetyDescription(type));
		return;
	}
	if (fields == nil) {
		D(@"Unknwon Reblog form. not found post[one|two|three] fields. type: %@", SafetyDescription(type));
		return;
	}
	else if ([fields count] < 2) { /* type[post] + 1このフィールドは絶対あるはず */
		D(@"Unknwon Reblog form. too few fields. type: %@", SafetyDescription(type));
		return;
	}

	NSMutableDictionary* obj = [[[NSMutableDictionary alloc] init] autorelease];
	[obj setValue:endpoint_ forKey:@"endpoint"];
	[obj setValue:type forKey:@"type"];
	[obj addEntriesFromDictionary:fields];

	[continuation_ performSelectorOnMainThread:@selector(extract:) withObject:obj waitUntilDone:NO];
}

/**
 * form HTMLからfieldを得る
 */
- (NSArray *)inputFields:(NSData *)formData
{
	static NSString* xpath = @"//div[@id=\"container\"]/div[@id=\"content\"]/form[@id=\"edit_post\"]//(input[starts-with(@name, \"post\")] | textarea[starts-with(@name, \"post\")] | (div[starts-with(@style, \"text-align:center;\")]/img))";

	/* UTF-8 文字列にしないと後の [attribute stringValue] で日本語がコードポイント表記になってしまう */
	NSString* html = [[[NSString alloc] initWithData:formData encoding:NSUTF8StringEncoding] autorelease];

	/* DOMにする */
	NSError* error = nil;
	NSXMLDocument* document = [[NSXMLDocument alloc] initWithXMLString:html options:NSXMLDocumentTidyHTML error:&error];
	if (document == nil) {
		D(@"Couldn't make DOMDocument. error: %@", [error description]);
		return nil;
	}

	NSArray* inputs = [[document rootElement] nodesForXPath:xpath error:&error];
	if (inputs == nil) {
		D(@"Failed nodesForXPath. error: %@", [error description]);
	}

	return inputs;
}

/**
 * input(NSXMLElement) array から post[type] の value を得る
 */
- (NSString *)typeofPost:(NSArray *)inputs
{
	NSRange empty = NSMakeRange(NSNotFound, 0);

	NSEnumerator* enumerator = [inputs objectEnumerator];
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		NSString* name = [[element attributeForName:@"name"] stringValue];
		if (name != nil) {
			if (!NSEqualRanges([name rangeOfString:@"post[type]"], empty)) {
				return [[element attributeForName:@"value"] stringValue];
			}
		}
	}
	return nil;
}

/**
 * "Link" post type の時の input fields の抽出
 */
- (NSMutableDictionary *)inputFieldsAsLink:(NSArray *)elements
{
	NSMutableDictionary * fields = [[[NSMutableDictionary alloc] init] autorelease];
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
	}

	return fields;
}

/**
 * "Photo" post type の時の input fields の抽出
 */
- (NSMutableDictionary *)inputFieldsAsPhoto:(NSArray *)elements
{
	NSMutableDictionary * fields = [[[NSMutableDictionary alloc] init] autorelease];
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

		name = [element name];
		if (!NSEqualRanges([name rangeOfString:@"img"], empty)) {
			/* photo だけ特殊処理 */
			attribute = [element attributeForName:@"src"];
			[fields setValue:[attribute stringValue] forKey:@"imgsrc"];
		}
	}

	return fields;
}

/**
 * "Quote" post type の時の input fields の抽出
 */
- (NSMutableDictionary*) inputFieldsAsQuote:(NSArray*)elements
{
	NSMutableDictionary * fields = [[[NSMutableDictionary alloc] init] autorelease];
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
		else if (!NSEqualRanges([name rangeOfString:@"form_key"], empty)) {
			[fields setValue:[element stringValue] forKey:@"form_key"];
		}
	}

	return fields;
}

/**
 * "Regular" post type の時の input fields の抽出
 */
- (NSMutableDictionary *)inputFieldsAsRegular:(NSArray *)elements
{
	NSMutableDictionary * fields = [[[NSMutableDictionary alloc] init] autorelease];
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
	}

	return fields;
}

/**
 * "Conversation" post type の時の input fields の抽出
 */
- (NSMutableDictionary *)inputFieldsAsChat:(NSArray *)elements
{
	NSMutableDictionary * fields = [[[NSMutableDictionary alloc] init] autorelease];
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
	}

	return fields;
}

/**
 * "Video" post type の時の input fields の抽出
 */
- (NSMutableDictionary *)inputFieldsAsVideo:(NSArray *)elements
{
	NSMutableDictionary * fields = [[[NSMutableDictionary alloc] init] autorelease];
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
		else if (!NSEqualRanges([name rangeOfString:@"form_key"], empty)) {
			[fields setValue:[element stringValue] forKey:@"form_key"];
		}
	}
	return fields;
}
@end
