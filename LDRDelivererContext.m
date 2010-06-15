/**
 * @file LDRDelivererContext.m
 * @brief LDRDelivererContext class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "LDRDelivererContext.h"
#import "DebugLog.h"
#import <WebKit/DOM.h>
#import <WebKit/WebView.h>

@interface LDRDelivererContext (Private)
+ (DOMNode *)getItemCountElement:(DOMHTMLDocument*)document target:(NSDictionary*)element;
- (NSString *)stringForXPath:(NSString*)xpath target:(DOMNode*)targetNode debug:(NSString*)message;
- (NSString *)getAuthor:(DOMNode*)targetNode;
- (NSString *)getTitle:(DOMNode*)targetNode;
- (NSString *)getFeedName;
- (NSString *)getURI:(DOMNode*)targetNode;
+ (void)dumpXPathResult:(DOMXPathResult*)result withPrefix:(NSString*)prefix;
+ (BOOL)match:(NSURL*)url;
@end
@implementation LDRDelivererContext (Private)
/**
 * LDRのエントリに存在する item_count を持つ要素を得る
 *
 * @param [in] document HTMLドキュメント
 * @param [in] target 対象要素
 * @return DOMNode オブジェクト
 */
+ (DOMNode*) getItemCountElement:(DOMHTMLDocument*)document target:(NSDictionary*)element
{
	static NSString* xpath = @"ancestor-or-self::div[starts-with(@id,\"item_count\")]";

	DOMNode* targetNode = [element objectForKey:WebElementDOMNodeKey];
	if (targetNode == nil) {
		D(@"DOMNode not found: %@", element);
		return nil;
	}

	D(@"getItemCountElement: target: %@", SafetyDescription(targetNode));
	DOMXPathResult* result;
	result = [document evaluate:xpath
					contextNode:targetNode
					   resolver:nil /* nil for HTML document */
						   type:DOM_ANY_TYPE
					   inResult:nil];

	[self dumpXPathResult:result withPrefix:@"getItemCountElement"];

	if (result != nil) {
		if (![result invalidIteratorState]) {
			DOMNode* node;
			for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
				D(@"node: %@ id:%@", [node description], [((DOMHTMLDivElement*)node) idName]);
				return node; /* 先頭のDOMノードでOK(1ノードしか選択していないハズ) */
			}
		}
	}
	D(@"Failed XPath for targetNode: %@", [targetNode description]);
	return nil;
}

/**
 *
 */
- (NSString*) stringForXPath:(NSString*)xpath target:(DOMNode*)targetNode debug:(NSString*)message
{
#pragma unused (message)
	@try {
		DOMXPathResult* result;
		result = [self evaluateToDocument:xpath
							  contextNode:targetNode
									 type:DOM_STRING_TYPE
								 inResult:nil];
		if (result != nil && [result resultType] == DOM_STRING_TYPE) {
			return [result stringValue];
		}
	}
	@catch (NSException* e) {
		D(@"Catch exception: %@", [e description]);
	}

	return [[[NSString alloc] init] autorelease];
}

/**
 *
 */
- (NSString*) getAuthor:(DOMNode*)targetNode
{
	static NSString* xpath = @"./div[@class=\"item_info\"]/*[@class=\"author\"]/text()";

	NSString* author = nil;
	
	author = [self stringForXPath:xpath target:targetNode debug:@"getAuthor"];
	if (author != nil && [author length] > 3) {
		/* "by (.*)" */
		return [author substringFromIndex:3];
	}
	return [[[NSString alloc] init] autorelease];
}

/**
 *
 */
- (NSString*) getTitle:(DOMNode*)targetNode
{
	static NSString* xpath = @"./div[@class=\"item_header\"]//a/text()";

	NSString* title = nil;
	title = [self stringForXPath:xpath target:targetNode debug:@"getTitle"];
	if (title != nil) {
		return title;
	}

	return [[[NSString alloc] initWithString:@"no title"] autorelease];
}

/**
 * feed
 */
- (NSString*) getFeedName
{
	static NSString* xpath = @"id(\"right_body\")/div[@class=\"channel\"]//a/text()";

	@try {
		DOMXPathResult* result;
		result = [self evaluateToDocument:xpath
										contextNode:document_
													 type:DOM_STRING_TYPE
											 inResult:nil];

		[LDRDelivererContext dumpXPathResult:result withPrefix:@"getFeedName"];

		if (result != nil && [result resultType] == DOM_STRING_TYPE) {
			return [result stringValue];
		}
	}
	@catch (NSException* e) {
		D(@"Catch exception: %@", [e description]);
	}

	return [[[NSString alloc] init] autorelease];
}

/**
 * href
 */
- (NSString*) getURI:(DOMNode*)targetNode
{
	static NSString* xpath = @"(div[@class=\"item_info\"]/a)[1]/@href";

	@try {
		DOMXPathResult* result;
		result = [self evaluateToDocument:xpath
										contextNode:targetNode
													 type:DOM_ANY_TYPE
											 inResult:nil];

		[LDRDelivererContext dumpXPathResult:result withPrefix:@"getURI"];

		if (result != nil && [result resultType] == DOM_UNORDERED_NODE_ITERATOR_TYPE) {
			if (![result invalidIteratorState]) {
				DOMNode* node = nil;
				for (node = [result iterateNext]; node != nil; node = [result iterateNext]) {
					D(@"1st node: name: %@ type: %d value: %@ textContent: %@",
							[node nodeName],
							[node nodeType],
							[node nodeValue],
							[node textContent]);
					/* s/[?&;](fr?(om)?|track|ref|FM)=(r(ss(all)?|df)|atom)([&;].*)?//g */
					return [node textContent];
				}
			}
		}
	}
	@catch (NSException* e) {
		D(@"Catch exception: %@", [e description]);
	}

	return [[[NSString alloc] init] autorelease];
}

/**
 *
 */
+ (void) dumpXPathResult:(DOMXPathResult*)result withPrefix:(NSString*)prefix
{
#pragma unused (prefix)
#define ToTypeName(t) \
					(t == DOM_NUMBER_TYPE ? @"NUMBER" : \
					 t == DOM_STRING_TYPE ? @"STRING" : \
					 t == DOM_BOOLEAN_TYPE ? @"BOOLEAN" : \
					 t == DOM_UNORDERED_NODE_ITERATOR_TYPE ? @"UNORDERED_NODE_ITERATOR" : \
					 t == DOM_ORDERED_NODE_ITERATOR_TYPE ? @"ORDERED_NODE_ITERATOR" : \
					 t == DOM_UNORDERED_NODE_SNAPSHOT_TYPE ? @"UNORDERED_NODE_SNAPSHOT" : \
					 t == DOM_ORDERED_NODE_SNAPSHOT_TYPE ? @"ORDERED_NODE_SNAPSHOT" : \
					 t == DOM_ANY_UNORDERED_NODE_TYPE ? @"ANY_UNORDERED_NODE" : \
					 t == DOM_FIRST_ORDERED_NODE_TYPE ? @"FIRST_ORDERED_NODE" : \
					 t == DOM_ANY_TYPE ? @"ANY" : @"Unknown?")

	@try {
		if (result != nil) {
			D(@"XPath: %@ {", prefix);
			D(@"  description: %@", [result description]);
			D(@"  resultType: %@", ToTypeName([result resultType]));
			switch ([result resultType]) {
			case DOM_NUMBER_TYPE:
				D(@"  numberValue: %f", [result numberValue]);
				break;
			case DOM_STRING_TYPE:
				D(@"  stringValue: %@", [result stringValue]);
				break;
			case DOM_BOOLEAN_TYPE:
				D(@"  booleanValue: %d", [result booleanValue]);
				break;
			case DOM_ORDERED_NODE_SNAPSHOT_TYPE:
			case DOM_UNORDERED_NODE_SNAPSHOT_TYPE:
				D(@"  snapshotLength: %d", [result snapshotLength]);
				D(@"  snapshotItem[0]: %@", [[result snapshotItem:0] description]);
				break;
			case DOM_ORDERED_NODE_ITERATOR_TYPE:
			case DOM_UNORDERED_NODE_ITERATOR_TYPE:
				D(@"  %@s invalidIteratorState: %d", @"NODE_ITERATOR", [result invalidIteratorState]);
				break;
			case DOM_FIRST_ORDERED_NODE_TYPE:
				D(@"  %@ invalidIteratorState: %d", @"FIRST_ORDERED_NODE", [result invalidIteratorState]);
				break;
			default:
				D(@"  resultType was invalid%@", @"!");
			}
			D(@"%@", @"}");
		}
	}
	@catch (NSException* e) {
		D(@"Catch exception: %@", [e description]);
	}
}

+ (BOOL)match:(NSURL *)url
{
	/* host をチェック */
	NSString* host = [url host];
	return [host isEqualToString:@"reader.livedoor.com"] || [host isEqualToString:@"fastladder.com"];
}
@end

@implementation LDRDelivererContext

+ (BOOL)match:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
	NSURL* url = [NSURL URLWithString:[document URL]];
	if ([LDRDelivererContext match:url]) {
		return [self getItemCountElement:document target:targetElement] != nil;
	}
	return NO;
}

+ (DOMHTMLElement*) matchForAutoDetection:(DOMHTMLDocument*)document windowScriptObject:(WebScriptObject*)wso;
{
	if ([LDRDelivererContext match:[NSURL URLWithString:[document URL]]] == NO) {
		return nil;
	}

	DOMHTMLElement* element = nil;

	@try {
		DOMHTMLElement* itemBody = nil;
		// window.get_active_item メソッドを利用して、フォーカスしているアイテムを得る
		// このメソッドは LDR から供給されている
		NSArray* args = [NSArray arrayWithObjects:[NSNumber numberWithBool:YES], nil];
		id item = [wso callWebScriptMethod:@"get_active_item" withArguments:args];
		D(@"get_active_item result=%@", SafetyDescription(item));
		if (item != nil) {
			// id を得る
			NSString* idno = [item valueForKey:@"id"];
			D(@"  id=%@", idno);
			if (idno != nil) {
				// item_body_XXX な要素を DOMNode オブジェクトとして得るため
				// に '$' メソッドを通す
				args = [NSArray arrayWithObjects:
					    [NSString stringWithFormat:@"item_body_%@", idno]
					  , nil];
				itemBody = [wso callWebScriptMethod:@"$" withArguments:args];
				D(@"itemBody result=%@", SafetyDescription(itemBody));
				D(@"  className=%@", [itemBody className]);
				D(@"  idName=%@", [itemBody idName]);
			}
		}

		if (itemBody != nil) {
			// @class=item_body な div からの相対
			NSArray* expressions = [NSArray arrayWithObjects:
				  @"./div[@class=\"body\"]/img"
				, @"./div[@class=\"body\"]"
				, nil];
			element = [DelivererContext evaluate:expressions document:document contextNode:itemBody];
			D(@"element=%@", SafetyDescription(element));
			D(@"  idName=%@", [element idName]);
		}
	}
	@catch (NSException* e) {
		D(@"Catch exception: %@", [e description]);
	}

	return element;
}

- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
		DOMNode* target = [LDRDelivererContext getItemCountElement:document target:targetElement];
		if (target != nil) {
			author_ = [[self getAuthor:target] retain];
			title_ = [[self getTitle:target] retain];
			feedName_ = [[self getFeedName] retain];
			uri_ = [[self getURI:target] retain];
		}
		else {
			/* 通常はあり得ない - match で同じ事を実行して成功しているはずだから*/
			D(@"Failed getItemCountElement. element: %@", SafetyDescription(targetElement));
		}
	}
	return self;
}

- (void)dealloc
{
	[author_ release], author_ = nil;
	[title_ release], title_ = nil;
	[feedName_ release], feedName_ = nil;
	[uri_ release], uri_ = nil;

	[super dealloc];
}

- (NSString *)titleOfDocument
{
	// フィード名とフィードタイトルを連結したものをドキュメントタイトルとする
	NSMutableString* title = [[[NSMutableString alloc] initWithString:feedName_] autorelease];

	if (title_ != nil && [title_ length] > 0) {
		[title appendFormat:@" - %@", title_];
	}

	return title;
}

- (NSString *)URLOfDocument
{
	return uri_;
}

- (NSString *)titleOfMenuItem
{
	return @" - LDR";
}
@end
