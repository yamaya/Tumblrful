/**
 * @file TumblrReblogExtractor.m
 * @brief TumblrReblogExtractor class implementation
 * @author Masayuki YAMAYA
 * @date 2008-04-23
 */
#import "TumblrReblogExtractor.h"
#import "TumblrfulConstants.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

static const NSRange EmptyRange = {NSNotFound, 0};

@interface TumblrReblogExtractor ()
- (NSString *)postTypeWithElements:(NSArray *)elements;
- (NSArray *)inputElementsWithDocument:(DOMHTMLDocument *)document;
- (NSDictionary *)contentsWithElements:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForLink:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForPhoto:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForQuote:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForRegular:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForConversation:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForVideo:(NSArray *)elements;
- (NSMutableDictionary *)fieldsForAudio:(NSArray *)elements;
- (void)setFormKeyFieldIfExist:(DOMHTMLElement *)element fields:(NSMutableDictionary *)fields;
@end

@implementation TumblrReblogExtractor

@synthesize endpoint = endpoint_;
@synthesize postID = postID_;
@synthesize reblogKey = reblogKey_;

#pragma mark -
#pragma mark Custom Methods

- (void)startWithPostID:(NSString *)postID withReblogKey:(NSString *)reblogKey
{
	D(@"postid=%@ reblogkey=%@ delegate=%p", postID, reblogKey, delegate_);
	NSAssert(postID, @"postID must be not nil");
	NSAssert(reblogKey, @"reblogKey must be not nil");

	if (delegate_ == nil) return;

	self.postID = postID;
	self.reblogKey = reblogKey;
	self.endpoint = [TumblrReblogExtractor endpointWithPostID:self.postID withReblogKey:self.reblogKey];

	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.endpoint]];

	webView_ = [[WebView alloc] initWithFrame:NSZeroRect frameName:nil groupName:nil];
	[webView_ setHidden:YES];
	[webView_ setDrawsBackground:NO];
	[webView_ setShouldUpdateWhileOffscreen:NO];
	[webView_ setFrameLoadDelegate:self];
	[[webView_ mainFrame] loadRequest:request];
}

+ (NSString *)endpointWithPostID:(NSString *)postID withReblogKey:(NSString *)reblogKey
{
	return [NSString stringWithFormat:@"%@/reblog/%@/%@", TUMBLRFUL_TUMBLR_URL, postID, reblogKey];
}

- (id)initWithDelegate:(NSObject<TumblrReblogExtractorDelegate> *)delegate
{
	if ((self = [super init]) != nil) {
		delegate_ = [delegate retain];
	}
	return self;
}

#pragma mark -
#pragma mark Override Methods

- (void)dealloc
{
	[webView_ release], webView_ = nil;
	[postID_ release], postID_ = nil;
	[reblogKey_ release], reblogKey_ = nil;
	[endpoint_ release], endpoint_ = nil;
	[delegate_ release], delegate_ = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Delegate Methods

#pragma mark -
#pragma mark WebFrameLoadDelegate Methods

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
#pragma unused (sender, error, frame)
	D(@"mainFrame=%d", ([sender mainFrame] == frame));
	D0([error description]);
	if ([sender mainFrame] != frame) return;

	[self performSelectorOnMainThread:@selector(delegateDidFailExtractMethod:) withObject:error waitUntilDone:YES];
	[self autorelease];
}

/// フレームデータ読み込みの完了
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
#pragma unused (sender, frame)
	D(@"mainFrame=%d", ([sender mainFrame] == frame));
	if ([sender mainFrame] != frame) return;

	DOMHTMLDocument * htmlDoc = (DOMHTMLDocument *)[frame DOMDocument];
	if (![htmlDoc isKindOfClass:[DOMHTMLDocument class]]) return;

	@try {
		NSDictionary * contents = [self contentsWithElements:[self inputElementsWithDocument:htmlDoc]];
		D0([contents description]);

		// デリゲートメソッドをメインスレッド上で呼び出す
		[self performSelectorOnMainThread:@selector(delegateDidFinishExtractMethod:) withObject:contents waitUntilDone:YES];
	}
	@catch (NSException * e) {
		[self performSelectorOnMainThread:@selector(delegateDidFailExtractMethodWithException:) withObject:e waitUntilDone:YES];
	}
	[self autorelease];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
#pragma unused (sender, error, frame)
	D0([error description]);

	if ([sender mainFrame] != frame) return;
	[self performSelectorOnMainThread:@selector(delegateDidFailExtractMethod:) withObject:error waitUntilDone:YES];
	[self autorelease];
}

- (void)delegateDidFinishExtractMethod:(NSDictionary *)fields
{
	[delegate_ extractor:self didFinishExtract:fields];
}

- (void)delegateDidFailExtractMethod:(NSError *)error
{
	[delegate_ extractor:self didFailExtractWithError:error];
}

- (void)delegateDidFailExtractMethodWithException:(NSException *)exception
{
	[delegate_ extractor:self didFailExtractWithException:exception];
}

#pragma mark -
#pragma mark Private Methods
/**
 * Reblog formからinput要素を得る.
 *	@param[in] document を含む DOMDocument
 *	@return フィールド(DOM要素) autoreleased
 */
- (NSArray *)inputElementsWithDocument:(DOMHTMLDocument *)document
{
	static NSString * XPath = @"//div[@id='container']/div[@id='content']/form[@id='edit_post']//input[starts-with(@name, 'post')] | //textarea[starts-with(@name, 'post')] | //input[@id='form_key'] | //div[@id='current_photo']//img";

	DOMXPathResult * result = [document evaluate:XPath contextNode:document resolver:nil type:DOM_ANY_TYPE inResult:nil];
	D0([result description]);

	if (result == nil || [result invalidIteratorState]) {
		[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"%@", @"Failed evaluate XPath."];
		return nil;
	}

	NSMutableArray * elements = [NSMutableArray array];
	for (DOMHTMLElement * element; (element = (DOMHTMLElement *)[result iterateNext]) != nil; ) {
		//D(@"%@ id=%@", [element description], [element idName]);
		[elements addObject:element];
	}
	return elements;
}

- (NSDictionary *)contentsWithElements:(NSArray *)elements
{
	NSMutableDictionary * contents = nil;
	NSString * type = [self postTypeWithElements:elements];
	//D(@"type=%@ elements=%@", type, [elements description]);

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
	return contents;
}

/// DOMHTMLElementの配列から post[type] の value を得る
- (NSString *)postTypeWithElements:(NSArray *)elements
{
	NSEnumerator * enumerator = [elements objectEnumerator];
	DOMHTMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {
		NSString * name = [element getAttribute:@"name"];
		if (name == nil) continue;
		if (!NSEqualRanges([name rangeOfString:@"post[type]"], EmptyRange)) {
			return [element getAttribute:@"value"];
		}
	}
	return @"not-found";
}

/// "Link" post type の時の input fields の抽出
- (NSMutableDictionary *)fieldsForLink:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"link", @"post[type]", nil];

	NSString * name;
	NSEnumerator * enumerator = [elements objectEnumerator];
	DOMHTMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [element getAttribute:@"name"];
		if (name == nil) continue;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			[fields setObject:[element getAttribute:@"value"] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[element getAttribute:@"value"] forKey:@"post[two]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[three]"], EmptyRange)) {
			[fields setObject:[[element innerHTML] stringByUnescapingFromHTML] forKey:@"post[three]"];
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

	NSString * name;
	for (DOMHTMLElement * element in elements) {
		if ([element.tagName isCaseInsensitiveEqualToString:@"img"]) {
			NSString * source = [element getAttribute:@"src"];
			[fields setObject:source forKey:@"img-src"];
			continue;
		}

		name = [element getAttribute:@"name"];
		if (name != nil) {
			if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
				// one は出現しない
				D0(@"post[one] is not implemented in Reblog(Photo).");
				continue;
			}
			else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
				[fields setObject:[[element innerHTML] stringByUnescapingFromHTML] forKey:@"post[two]"];
				continue;
			}
			else if (!NSEqualRanges([name rangeOfString:@"post[three]"], EmptyRange)) {
				[fields setObject:[element getAttribute:@"value"] forKey:@"post[three]"];
				continue;
			}
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/// "Quote" post type の時の input fields の抽出
- (NSMutableDictionary *)fieldsForQuote:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"quote", @"post[type]", nil];

	NSString * name;
	NSEnumerator * enumerator = [elements objectEnumerator];
	DOMHTMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [element getAttribute:@"name"];
		if (name == nil) continue;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			[fields setObject:[[element innerHTML] stringByUnescapingFromHTML] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[[element innerHTML] stringByUnescapingFromHTML] forKey:@"post[two]"];
		}
		else {
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/// "Regular" post type の時の input fields の抽出
- (NSMutableDictionary *)fieldsForRegular:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"regular", @"post[type]", nil];

	NSString * name;
	NSEnumerator * enumerator = [elements objectEnumerator];
	DOMHTMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [element getAttribute:@"name"];
		if (name == nil) continue;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			[fields setObject:[element getAttribute:@"value"] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[[element innerHTML] stringByUnescapingFromHTML] forKey:@"post[two]"];
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

/// "Conversation" post type の時の input fields の抽出
- (NSMutableDictionary *)fieldsForConversation:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"conversation", @"post[type]", nil];

	NSString * name;
	NSEnumerator* enumerator = [elements objectEnumerator];
	DOMHTMLElement* element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [element getAttribute:@"name"];
		if (name == nil) continue;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			[fields setObject:[element getAttribute:@"value"] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[[element innerHTML] stringByUnescapingFromHTML] forKey:@"post[two]"];
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

/// "Video" post type の時の input fields の抽出
- (NSMutableDictionary *)fieldsForVideo:(NSArray *)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"video", @"post[type]", nil];

	NSString * name;
	NSEnumerator * enumerator = [elements objectEnumerator];
	DOMHTMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [element getAttribute:@"name"];
		if (name == nil) continue;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			[fields setObject:[[element innerHTML] stringByUnescapingFromHTML] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[[element innerHTML] stringByUnescapingFromHTML] forKey:@"post[two]"];
		}
		else {
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/// "Audio" post type の時の input fields の抽出
- (NSMutableDictionary *)fieldsForAudio:(NSArray*)elements
{
	NSMutableDictionary * fields = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"audio", @"post[type]", nil];

	NSString * name;
	NSEnumerator * enumerator = [elements objectEnumerator];
	DOMHTMLElement * element;
	while ((element = [enumerator nextObject]) != nil) {

		name = [element getAttribute:@"name"];
		if (name == nil) continue;

		if (!NSEqualRanges([name rangeOfString:@"post[one]"], EmptyRange)) {
			[fields setObject:[[element innerHTML] stringByUnescapingFromHTML] forKey:@"post[one]"];
		}
		else if (!NSEqualRanges([name rangeOfString:@"post[two]"], EmptyRange)) {
			[fields setObject:[[element innerHTML] stringByUnescapingFromHTML] forKey:@"post[two]"];
		}
		else {
			[self setFormKeyFieldIfExist:element fields:fields];
		}
	}

	return fields;
}

/// elementの要素名がformKeyであれば fields に追加する.
- (void)setFormKeyFieldIfExist:(DOMHTMLElement *)element fields:(NSMutableDictionary *)fields
{
	NSString * name = [element getAttribute:@"name"];

	if (!NSEqualRanges([name rangeOfString:@"form_key"], EmptyRange)) {
		[fields setObject:[element getAttribute:@"value"] forKey:@"form_key"];
	}
}
@end
