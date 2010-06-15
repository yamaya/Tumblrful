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
@synthesize postID = postID_;
@synthesize reblogKey = reblogKey_;

- (void)startWithPostID:(NSString *)postID withReblogKey:(NSString *)reblogKey
{
	D(@"postid=%@ reblogkey=%@", postID, reblogKey);

	if (delegate_ == nil) {
		D0(@"delegate_ is nil");
		return;
	}

	NSAssert(postID, @"postID must be not nil");
	NSAssert(reblogKey, @"reblogKey must be not nil");
	[postID_ release];
	postID_ = [postID retain];
	[reblogKey_ release];
	reblogKey_ = [reblogKey retain];

	endpoint_ = [[TumblrReblogExtractor endpointWithPostID:postID withReblogKey:reblogKey] retain];

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

#pragma mark -
#pragma mark Delegate Methods

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
	@try {
		NSMutableDictionary * contents = nil;
		NSArray * elements = [self inputElementsWithReblogFrom:data_];
		NSString * type = [self postTypeWithElements:elements];
		D(@"type=%@", type);

		if ([type isEqualToString:@"link"])					contents = [self fieldsForLink:elements];
		else if ([type isEqualToString:@"photo"])			contents = [self fieldsForPhoto:elements];
		else if ([type isEqualToString:@"quote"])			contents = [self fieldsForQuote:elements];
		else if ([type isEqualToString:@"regular"])			contents = [self fieldsForRegular:elements];
		else if ([type isEqualToString:@"conversation"])	contents = [self fieldsForConversation:elements];
		else if ([type isEqualToString:@"video"])			contents = [self fieldsForVideo:elements];
		else if ([type isEqualToString:@"audio"])			contents = [self fieldsForAudio:elements];

		NSString * message = nil;
		if (contents == nil) {
			message = [NSString stringWithFormat:@"Unrecognized Reblog form. type:%@", SafetyDescription(type)];
			D0(message);
			// nilもデリゲートに渡す
		}
		else if ([contents count] < 2) { // type[post] + 1このフィールドは絶対あるはず
			message = [NSString stringWithFormat:@"Unrecognized Reblog form. too few contents. type:%@", SafetyDescription(type)];
			D0(message);
		}
		else {
			[contents setObject:type forKey:@"type"];
		}

		// デリゲートメソッドをメインスレッド上で呼び出す
		[self performSelectorOnMainThread:@selector(delegateDidFinishExtractMethod:) withObject:contents waitUntilDone:YES];
	}
	@catch (NSException * e) {
		D0([e description]);

		// デリゲートメソッドをメインスレッド上で呼び出す
		[self performSelectorOnMainThread:@selector(delegateDidFailExtractMethod:) withObject:e waitUntilDone:YES];
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
		[self performSelectorOnMainThread:@selector(delegateDidFailExtractMethod:) withObject:error waitUntilDone:YES];
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
	static NSString * XPath = @"//div[@id=\"container\"]/div[@id=\"content\"]/form[@id=\"edit_post\"]//(input[starts-with(@name, \"post\")] | textarea[starts-with(@name, \"post\")] | input[@id=\"form_key\"] | div[@id=\"current_photo\"]//img)";

	// UTF-8 文字列にしないと後の [attribute stringValue] で日本語がコードポイント表記になってしまう
	NSString * formString = [[[NSString alloc] initWithData:reblogForm encoding:NSUTF8StringEncoding] autorelease];

	// DOMにする
	NSError * error = nil;
	NSXMLDocument * xmlDoc = [[[NSXMLDocument alloc] initWithXMLString:formString options:NSXMLDocumentTidyHTML error:&error] autorelease];
	if (xmlDoc == nil) {
		NSString * message = [NSString stringWithFormat:@"Couldn't make DOMDocument. %@", [error description]];
		D0(message);
		[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"%@", message];
	}

	error = nil;
	NSArray * elements = [[xmlDoc rootElement] nodesForXPath:XPath error:&error];
	if (elements == nil) {
		NSString * message = [NSString stringWithFormat:@"Failed nodesForXPath. %@", [error description]];
		D0(message);
		[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"%@", message];
	}

	D(@"elements=%@", [elements description]);
	return elements;
}

/// NSXMLElementの配列から post[type] の value を得る
- (NSString *)postTypeWithElements:(NSArray *)elements
{
	NSEnumerator * enumerator = [elements objectEnumerator];
	NSXMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {
		NSString * name = [[element attributeForName:@"name"] stringValue];
		if (name == nil) continue;
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

	NSString * name;
	NSEnumerator * enumerator = [elements objectEnumerator];
	NSXMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [[element attributeForName:@"name"] stringValue];
		if (name == nil) continue;

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

/// "Photo" post type の時の input fields の抽出
- (NSMutableDictionary *)fieldsForPhoto:(NSArray *)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"photo", @"post[type]", nil];

	NSXMLNode * attribute;
	NSString * name;
	NSEnumerator * enumerator = [elements objectEnumerator];
	NSXMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {
		if ([[element name] isEqualToString:@"img"]) {
			NSString * source = [[element attributeForName:@"src"] stringValue];
			D(@"image-src=%@", source);
			[fields setObject:source forKey:@"img-src"];
			continue;
		}

		name = [[element attributeForName:@"name"] stringValue];
		if (name != nil) {
			if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
				// one は出現しない
				D0(@"post[one] is not implemented in Reblog(Photo).");
				continue;
			}
			else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
				[fields setObject:[element stringValue] forKey:@"post[two]"];
				continue;
			}
			else if (!NSEqualRanges([name rangeOfString:@"post[three]"], EmptyRange)) {
				attribute = [element attributeForName:@"value"];
				[fields setObject:[attribute stringValue] forKey:@"post[three]"];
				continue;
			}
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

	NSString * name;
	NSEnumerator * enumerator = [elements objectEnumerator];
	NSXMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [[element attributeForName:@"name"] stringValue];
		if (name == nil) continue;

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
 * "Regular" post type の時の input fields の抽出
 */
- (NSMutableDictionary *)fieldsForRegular:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"regular", @"post[type]", nil];

	NSString * name;
	NSXMLNode * attribute;
	NSEnumerator * enumerator = [elements objectEnumerator];
	NSXMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [[element attributeForName:@"name"] stringValue];
		if (name == nil) continue;

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

	NSString * name;
	NSEnumerator* enumerator = [elements objectEnumerator];
	NSXMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [[element attributeForName:@"name"] stringValue];
		if (name == nil) continue;

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

	NSString * name;
	NSEnumerator * enumerator = [elements objectEnumerator];
	NSXMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [[element attributeForName:@"name"] stringValue];
		if (name == nil) continue;

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
 * "Audio" post type の時の input fields の抽出
 */
- (NSMutableDictionary *)fieldsForAudio:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"audio", @"post[type]", nil];

	NSString * name;
	NSEnumerator * enumerator = [elements objectEnumerator];
	NSXMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [[element attributeForName:@"name"] stringValue];
		if (name == nil) continue;

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

/// elementの要素名がformKeyであれば fields に追加する.
- (void)setFormKeyFieldIfExist:(NSXMLElement *)element fields:(NSMutableDictionary *)fields
{
	NSString * name = [[element attributeForName:@"name"] stringValue];

	if (!NSEqualRanges([name rangeOfString:@"form_key"], EmptyRange)) {
		NSXMLNode * attribute = [element attributeForName:@"value"];
		[fields setObject:[attribute stringValue] forKey:@"form_key"];
	}
}

+ (NSString *)endpointWithPostID:(NSString *)postID withReblogKey:(NSString *)reblogKey
{
	return [NSString stringWithFormat:@"%@/reblog/%@/%@", TUMBLRFUL_TUMBLR_URL, postID, reblogKey];
}
@end
