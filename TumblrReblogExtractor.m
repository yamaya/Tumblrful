/**
 * @file TumblrReblogExtractor.m
 * @brief TumblrReblogExtractor class implementation
 * @author Masayuki YAMAYA
 * @date 2008-04-23
 */
#import "TumblrReblogExtractor.h"
#import "TumblrfulConstants.h"
#import "DebugLog.h"

static const NSRange EmptyRange = {NSNotFound, 0};

@interface TumblrReblogExtractor ()
- (NSString *)postTypeWithElements:(NSArray *)elements;
- (NSArray *)inputElementsWithReblogFrom:(NSData *)reblogForm;
- (NSMutableDictionary *)fieldsForLink:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForPhoto:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForQuote:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForRegular:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForConversation:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForVideo:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForAudio:(NSArray *)elements;
- (void)setFormKeyFieldIfExist:(NSXMLElement *)element fields:(NSMutableDictionary *)fields;
@end

@implementation TumblrReblogExtractor

@synthesize endpoint = endpoint_;

/**
 * endpointから reblog form を取得して field に展開する.
 */
- (void)startWithPostID:(NSString*)postID withReblogKey:(NSString*)reblogKey
{
	D(@"postid=%@ reblogkey=%@", postID, reblogKey);

	if (delegate_ == nil) {
		D0(@"delegate_ is nil");
		return;
	}
	if (![delegate_ respondsToSelector:@selector(extractor:didFinishExtract:)]) {
		D(@"failed respondsToSelector. delegate_=%@", [delegate_ description]);
		return;
	}

	endpoint_ = [NSString stringWithFormat:@"%@/reblog/%@/%@", TUMBLRFUL_TUMBLR_URL, postID, reblogKey];
	[endpoint_ retain];

	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint_]];
	NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
	if (connection == nil) {
		D(@"Couldn't get reblog form. endpoint: %@", endpoint_);
	}
}

- (id)initWithDelegate:(NSObject<TumblrReblogExtractorDelegate> *)delegate
{
	if ((self = [super init]) != nil) {
		delegate_ = [delegate retain];
		endpoint_ = nil;
		data_ = nil;
	}
	return self;
}

- (void)dealloc
{
	[endpoint_ release], endpoint_ = nil;
	[delegate_ release], delegate_ = nil;
	[data_ release], data_ = nil;
	[super dealloc];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused (connection)
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
	D(@"HTTP status=%d", [httpResponse statusCode]);

	if ([httpResponse statusCode] == 200) {
		data_ = [[NSMutableData data] retain];
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
	D(@"data.length=%d", [data_ length]);

	@try {
		NSMutableDictionary * fields = nil;
		NSArray * elements = [self inputElementsWithReblogFrom:data_];
		NSString * type = [self postTypeWithElements:elements];
		if ([type isEqualToString:@"link"])					fields = [self fieldsForLink:elements];
		else if ([type isEqualToString:@"photo"])			fields = [self fieldsForPhoto:elements];
		else if ([type isEqualToString:@"quote"])			fields = [self fieldsForQuote:elements];
		else if ([type isEqualToString:@"regular"])			fields = [self fieldsForRegular:elements];
		else if ([type isEqualToString:@"conversation"])	fields = [self fieldsForConversation:elements];
		else if ([type isEqualToString:@"video"])			fields = [self fieldsForVideo:elements];
		else if ([type isEqualToString:@"audio"])			fields = [self fieldsForAudio:elements];

		if (fields == nil) {
			NSString * message = [NSString stringWithFormat:@"Unrecognized Reblog form. type:%@", SafetyDescription(type)];
			D0(message);
			// nilもデリゲートに渡す
		}
		else if ([fields count] < 2) { // type[post] + 1このフィールドは絶対あるはず
			NSString * message = [NSString stringWithFormat:@"Unrecognized Reblog form. too few fields. type:%@", SafetyDescription(type)];
			D0(message);
		}
		else {
			[fields setObject:endpoint_ forKey:@"endpoint"];
			[fields setObject:type forKey:@"type"];
		}

		// デリゲートメソッドをメインスレッド上で呼び出す
		[self performSelectorOnMainThread:@selector(delegateDidFinishExtractMethod:) withObject:fields waitUntilDone:NO];
	}
	@catch (NSException * e) {
		D0([e description]);
	}
	@finally {
		[self release];
	}
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
#pragma unused (connection)
	@try {
		D0([error description]);

		// デリゲートメソッドをメインスレッド上で呼び出す
		[self performSelectorOnMainThread:@selector(delegateDidFailExtractMethod:) withObject:error waitUntilDone:NO];
	}
	@finally {
		[self release];
	}
}

- (void)delegateDidFinishExtractMethod:(NSDictionary *)fields
{
	[delegate_ extractor:self didFinishExtract:fields];
}

- (void)delegateDidFailExtractMethod:(NSError *)error
{
	[delegate_ extractor:self didFailExtractWithError:error];
}

#pragma mark -
#pragma mark Private Methods

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
- (NSMutableDictionary *)fieldsForLink:(NSArray*)elements
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
- (NSMutableDictionary *)fieldsForPhoto:(NSArray*)elements
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
- (NSMutableDictionary *)fieldsForQuote:(NSArray*)elements
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
- (NSMutableDictionary *)fieldsForRegular:(NSArray*)elements
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
- (NSMutableDictionary *)fieldsForConversation:(NSArray*)elements
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
- (NSMutableDictionary *)fieldsForVideo:(NSArray *)elements
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
- (NSMutableDictionary *)fieldsForAudio:(NSArray*)elements
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

@end
