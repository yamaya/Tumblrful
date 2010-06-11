/**
 * @file DelivererContext.m
 * @brief DelivererContext implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLDocument.h
// /System/Library/Frameworks/WebKit.framework/Headers/DOMDocument.h
#import "DelivererContext.h"
#import "DelivererRules.h"
#import "Log.h"
#import <WebKit/DOMHTMLDocument.h>

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

@implementation DelivererContext
/**
 * 自分が処理すべき HTML ドキュメントかどうかを判定する
 * @param [in] document 評価対象となる DOMドキュメント
 * @param [in] targetElement ポスト対象要素
 * @return 処理すべき HTMLドキュメントの場合 true
 */
+ (BOOL) match:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement
{
#pragma unused (document, targetElement)
	return YES; /* 常に真 */
}

/**
 * 自分が処理すべき HTML ドキュメントかどうかを判定する - 要素自動判定
 * @param [in] document 評価対象となる DOMドキュメント
 * @param [in] window Window スクリプトオブジェクト
 * @return 処理すべき HTMLドキュメントの場合、ポスト対象となる要素
 */
+ (DOMHTMLElement*) matchForAutoDetection:(DOMHTMLDocument*)document windowScriptObject:(WebScriptObject*)window;
{
#pragma unused (document, window)
	return FALSE; /* 常に偽 */
}

/**
 * XPath の評価
 * @param [in] expressions XPath 式(文字列の配列)
 * @param [in] document 評価対象となる DOMドキュメント
 * @return 評価結果の要素
 */
+ (DOMHTMLElement*) evaluate:(NSArray*)expressions document:(DOMHTMLDocument*)document contextNode:(DOMNode*)cnode
{
	DOMHTMLElement* element = nil;

	@try {
		// とりあえず photo優先で調べてみる
		// img で失敗したら reblogにまわしてみるために item-body までの XPath
		// DOMHTMLEmement を得てみる
		size_t N = [expressions count];
		size_t i;
		for (i = 0; i < N && element == nil; ++i) {
			NSString* expr = [expressions objectAtIndex:i];
			DOMXPathResult* xpresult = [document evaluate:expr contextNode:cnode resolver:nil type:DOM_ANY_TYPE inResult:nil];
			V(@"XPathResult: %@ %d/%d", SafetyDescription(xpresult), i, N);
			if (xpresult != nil) {
				DOMNode* node = nil;
				while (![xpresult invalidIteratorState]) {
					node = [xpresult iterateNext];
					V(@"XPathResult's node: %@ %d/%d", SafetyDescription(node), i, N);
					if (node != nil) {
						if ([node isKindOfClass:[DOMHTMLElement class]]) {
							element = (DOMHTMLElement*)node;
							break;
						}
					}
					else {
						break;
					}
				}
			}
		}
	}
	@catch (NSException* e) {
		V(@"Exception: %@", [e description]);
		element = nil;
	}

	return element;
}

/**
 * オブジェクトの初期化
 * @param [in] document URL を含む DOM ドキュメント
 * @param [in] targetElement 選択している要素 - このクラスでは未使用
 * @return 自身のオブジェクト
 */
- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
#pragma unused (document, targetElement)
	if ((self = [super init]) != nil) {
		document_ = [document retain];
	}
	return self;
}

/**
 * オブジェクトの解放
 */
- (void) dealloc
{
	[document_ release];
	[super dealloc];
}

/**
 * ドキュメントを取得する
 * @return ドキュメント
 */
- (DOMHTMLDocument*) document
{
	return document_;
}

/**
 * ドキュメントのタイトルを取得する
 * @return タイトル文字列
 */
- (NSString*) documentTitle
{
	return [document_ title];
}

/**
 * ドキュメントの URL取得する
 * @return URL文字列
 */
- (NSString*) documentURL
{
	return [document_ URL];
}

/**
 * ドキュメントへのアンカータグを取得する
 * @return アンカータグ
 */
- (NSString*) anchorTagToDocument
{
	return [DelivererRules anchorTagWithName:[self documentURL]
										name:[self documentTitle]];
}

/**
 * メニュータイトルを取得する
 * @return タイトル文字列 - このクラスでは常に空文字列
 */
- (NSString*) menuTitle
{
	return @"";
}

/**
 * XPath を評価する
 * @param expression XPath式
 * @param contextNode コンテキストノード
 * @param type タイプ
 * @param inResult 評価対象に含めるXPath評価結果
 * @return DOMXPathResult XPath評価の結果
 */
- (DOMXPathResult*) evaluateToDocument:(NSString*)expression
						   contextNode:(DOMNode*)contextNode
								  type:(unsigned short)type
							  inResult:(DOMXPathResult*)inResult
{
	return [document_ evaluate:expression
				   contextNode:contextNode
					  resolver:nil /* nil for HTML document */
						  type:type
					  inResult:inResult];
}
@end
