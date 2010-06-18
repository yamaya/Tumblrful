/**
 * @file AggregatorDelivererContext.m
 */
#import "AggregatorDelivererContext.h"
#import "DebugLog.h"

@interface AggregatorDelivererContext ()
- (NSDictionary *)propertiesWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement;
@end

@implementation AggregatorDelivererContext

+ (NSString *)name
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

+ (NSString *)entryNodeExpression
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
		NSDictionary * properties = [self propertiesWithDocument:document target:targetElement];
		if (properties != nil) {
			title_ = [[properties objectForKey:@"title"] retain];
			source_ = [[properties objectForKey:@"source"] retain];
			URL_ = [[properties objectForKey:@"URL"] retain];
		}
	}
	return self;
}

- (void)dealloc
{
	[title_ release], title_ = nil;
	[source_ release], source_ = nil;
	[URL_ release], URL_ = nil;

	[super dealloc];
}

- (NSString *)titleWithNode:(DOMNode *)targetNode;
{
#pragma unused (targetNode)
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSString *)sourceWithNode:(DOMNode *)targetNode
{
#pragma unused (targetNode)
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSString *)URLWithNode:(DOMNode *)targetNode
{
#pragma unused (targetNode)
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSDictionary *)propertiesWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
	NSMutableDictionary * properties = [NSMutableDictionary dictionary];
	NSString * value;

	DOMNode * node = [[self class] entryNodeWithDocument:document target:targetElement];
	D0([node description]);
	if (node != nil) {
		value = [self titleWithNode:node];
		if (value != nil) [properties setObject:value forKey:@"title"];

		value = [self sourceWithNode:node];
		if (value != nil) [properties setObject:value forKey:@"source"];

		value = [self URLWithNode:node];
		if (value != nil) [properties setObject:value forKey:@"URL"];
	}

	D0([properties description]);
	return properties;
}

+ (DOMNode *)entryNodeWithDocument:(DOMHTMLDocument *)document target:(NSDictionary*)targetElement
{
	NSString * xpath = [self entryNodeExpression];
	D0(xpath);

	DOMNode * targetNode = [targetElement objectForKey:WebElementDOMNodeKey];
	if (targetNode == nil) return nil;

	DOMXPathResult * result = [document evaluate:xpath contextNode:targetNode resolver:nil type:DOM_ANY_TYPE inResult:nil];

	[self dump:result];

	if (result != nil && ![result invalidIteratorState]) {
		for (DOMNode * node = [result iterateNext]; node != nil; node = [result iterateNext]) {
			D(@"%@ id=%@", [node description], [((DOMHTMLDivElement*)node) idName]);
			return node; // 先頭のDOMノードでOK(1ノードしか選択していないハズ)
		}
	}

	D(@"Failed XPath. targetNode=%@", [targetNode description]);
	return nil;
}

- (NSString *)documentTitle
{
	// フィード名とフィードタイトルを連結したものをドキュメントタイトルとする
	NSMutableString * result = [NSMutableString stringWithString:source_];

	if (title_ != nil && [title_ length] > 0) {
		[result appendFormat:@" - %@", title_];
	}

	return result;
}

- (NSString *)documentURL
{
	return URL_;
}

- (NSString *)menuTitle
{
	return [NSString stringWithFormat:@" - %@", [self.class name]];
}

- (NSString *)evaluateWithXPathExpression:(NSString *)expression target:(DOMNode *)targetNode
{
	SEL selector = @selector(idName);
	if ([targetNode respondsToSelector:selector]) {
		D(@"targetNode's id=%@", [targetNode performSelector:selector]);
	}

	@try {
		DOMXPathResult * result = [self evaluateToDocument:expression contextNode:targetNode type:DOM_STRING_TYPE inResult:nil];

		[[self class] dump:result];

		if (result != nil && [result resultType] == DOM_STRING_TYPE) {
			return [result stringValue];
		}
	}
	@catch (NSException * e) {
		D0([e description]);
	}

	return nil;
}

+ (void)dump:(DOMXPathResult *)result
{
#ifdef DEBUG
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
		if (result == nil) {
			D0(@"result is nil.");
			return;
		}
		D(@"XPath={");
		D(@"  description=%@", [result description]);
		D(@"  resultType=%@", ToTypeName([result resultType]));
		switch ([result resultType]) {
		case DOM_NUMBER_TYPE:
			D(@"  numberValue=%f", [result numberValue]);
			break;
		case DOM_STRING_TYPE:
			D(@"  stringValue=%@", [result stringValue]);
			break;
		case DOM_BOOLEAN_TYPE:
			D(@"  booleanValue=%d", [result booleanValue]);
			break;
		case DOM_ORDERED_NODE_SNAPSHOT_TYPE:
		case DOM_UNORDERED_NODE_SNAPSHOT_TYPE:
			D(@"  snapshotLength=%d", [result snapshotLength]);
			D(@"  snapshotItem[0]=%@", [[result snapshotItem:0] description]);
			break;
		case DOM_ORDERED_NODE_ITERATOR_TYPE:
		case DOM_UNORDERED_NODE_ITERATOR_TYPE:
			D(@"  %@s invalidIteratorState=%d", @"NODE_ITERATOR", [result invalidIteratorState]);
			break;
		case DOM_FIRST_ORDERED_NODE_TYPE:
			D(@"  %@ invalidIteratorState=%d", @"FIRST_ORDERED_NODE", [result invalidIteratorState]);
			break;
		default:
			D(@"%@", "  resultType was invalid");
		}
		D(@"%@", @"}");
	}
	@catch (NSException * e) {
		D0([e description]);
	}
#else
#pragma unused (result)
#endif
}
@end
