/**
 * @file DelivererBase.m
 * @brief DelivererBase implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererBase.h"
#import "DelivererRules.h"
#import "DelivererContext.h"
#import "GoogleReaderDelivererContext.h"
#import "LDRDelivererContext.h"
#import "Anchor.h"
#import "PostAdaptorCollection.h"
#import "PostAdaptor.h"
#import "GrowlSupport.h"
#import "DebugLog.h"
#import "PostEditWindow.h"
#import "NSString+Tumblrful.h"

@interface DelivererBase ()
- (NSArray*)sharedContexts;
- (NSString*)makeMenuTitle;
- (void)actionInternal:(id)sender;
@end

@implementation DelivererBase
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
#pragma unused (document, clickedElement)
	[self doesNotRecognizeSelector:_cmd]; // _cmd はカレントセレクタ
	return nil;
}

/**
 * オブジェクトを初期化する.
 *	@param document 現在表示しているビューの DOMHTMLDocumentオブジェクト
 *	@param targetElement 選択していた要素の情報
 */
- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement
{
	context_ = nil;
	filterMask_ = 0;
	needEdit_ = NO;

	if ((self = [super init]) != nil) {
		NSEnumerator* enumerator = [[self sharedContexts] objectEnumerator];
		id clazz;
		while ((clazz = [enumerator nextObject]) != nil) {
			if ([clazz match:document target:targetElement]) {
				context_ = [[[clazz alloc] initWithDocument:document target:targetElement] retain];
				break;
			}
		}
	}
	return self;
}

- (NSString *)postType
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

/**
 * オブジェクトの解放.
 */
- (void) dealloc
{
	[context_ release];
	[super dealloc];
}

- (NSMenuItem *)createMenuItem
{
	//FIXME retainedだけど、いいんだっけ？
	NSMenuItem * rootItem = [[[NSMenuItem alloc] init] retain];

	[rootItem setTitle:[self makeMenuTitle]];
	[rootItem setTarget:self];
	[rootItem setAction:@selector(actionInternal:)];

	return rootItem;
}

- (void)action:(id)sender
{
#pragma unused (sender)
	[self doesNotRecognizeSelector:_cmd]; // _cmd はカレントセレクタ
}

- (void)invoke:(NSInvocation *)invocation withType:(PostType)type
{
	if (needEdit_) {
		PostEditWindow * window = [[PostEditWindow alloc] initWithPostType:type withInvocation:invocation];
		[window openSheet:[[NSApplication sharedApplication] keyWindow]];
	}
	else {
		[invocation invoke];
	}
}

- (NSInvocation *)typedInvocation:(SEL)selector withAdaptor:(PostAdaptor *)adaptor
{
	NSMethodSignature * signature = [adaptor.class instanceMethodSignatureForSelector:selector];
	NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setTarget:adaptor];
	[invocation setSelector:selector];

	return invocation;
}

#pragma mark -

- (void)postLink:(NSString *)url title:(NSString *)title
{
	@try {
		Anchor* anchor = [Anchor anchorWithURL:url title:title];
		NSUInteger i = 0;
		NSEnumerator * enumerator = [PostAdaptorCollection enumerator];
		Class postClass;
		while ((postClass = [enumerator nextObject]) != nil) {
			if ((1 << i) & filterMask_) { // do filter
				PostAdaptor * adaptor = [[postClass alloc] initWithCallback:self];
				NSInvocation * invocation = [self typedInvocation:@selector(postLink:description:) withAdaptor:adaptor];
				[invocation setArgument:&anchor atIndex:2];
				[invocation setArgument:&EmptyString atIndex:3];
				[invocation retainArguments];
				[self invoke:invocation withType:LinkPostType];
			}
			i++;
		}
	}
	@catch (NSException * e) {
		D0([e description]);
		[self notify:[e description]];
	}
}

- (void)postQuote:(NSString *)quote
{
	@try {
		NSString * source = [Anchor htmlWithURL:[context_ documentURL] title:[context_ documentTitle]];
		int i = 0;
		NSEnumerator * enumerator = [PostAdaptorCollection enumerator];
		Class postClass;
		while ((postClass = [enumerator nextObject]) != nil) {
			if ((1 << i) & filterMask_) {	// フィルタリング
				PostAdaptor * adaptor = [[postClass alloc] initWithCallback:self];
				NSInvocation * invocation = [self typedInvocation:@selector(postQuote:source:) withAdaptor:adaptor];
				[invocation setArgument:&quote atIndex:2];
				[invocation setArgument:&source atIndex:3];
				[invocation retainArguments];
				[self invoke:invocation withType:QuotePostType];
			}
			i++;
		}
	}
	@catch (NSException * e) {
		D0([e description]);
		[self notify:[e description]];
	}
}

- (void)postPhoto:(NSString *)imageURL caption:(NSString *)caption through:(NSString *)url
{
	D(@"imageURL:%@", [imageURL description]);
	D(@"caption:%@", [caption description]);
	D(@"url:%@", [url description]);

	NSUInteger i = 0;
	NSEnumerator * enumerator = [PostAdaptorCollection enumerator];
	Class postClass;
	while ((postClass = [enumerator nextObject]) != nil) {
		if ((1 << i) & filterMask_) { // do filter
			PostAdaptor * adaptor = [[postClass alloc] initWithCallback:self];
			NSInvocation * invocation = [self typedInvocation:@selector(postPhoto:caption:throughURL:) withAdaptor:adaptor];
			[invocation setArgument:&imageURL atIndex:2];
			[invocation setArgument:&caption atIndex:3];
			[invocation setArgument:&url atIndex:4];
			[invocation retainArguments];
			[self invoke:invocation withType:PhotoPostType];
		}
		i++;
	}
}

/**
 * "Video" post.
 *	@param embed ビデオオブジェクトの embed URL - youtube の場合 URL を指定可能
 *	@param title ビデオのタイトル
 *	@param caption ビデオの概要
 */
- (void)postVideo:(NSString*)embed title:(NSString*)title caption:(NSString*)caption
{
	Anchor* anchor = [Anchor anchorWithURL:[context_ documentURL] title:title];
	int i = 0;
	NSEnumerator* enumerator = [PostAdaptorCollection enumerator];
	Class postClass;
	while ((postClass = [enumerator nextObject]) != nil) {
		if ((1 << i) & filterMask_) { // do filter
			PostAdaptor* adaptor = [[postClass alloc] initWithCallback:self];
			NSInvocation * invocation = [self typedInvocation:@selector(postVideo:embed:caption:) withAdaptor:adaptor];
			[invocation setArgument:&anchor atIndex:2];
			[invocation setArgument:&embed atIndex:3];
			[invocation setArgument:&caption atIndex:4];
			[invocation retainArguments];
			[self invoke:invocation withType:VideoPostType];
		}
		i++;
	}
}

/**
 * "Reblog".
 *	@param entryID エントリID
 *	@return Reblog したポストのタイプを示す文字列等。
 *					何を返すかは PostAdaptor の派生クラスで決まる。
 */
- (NSObject*) postEntry:(NSDictionary*)params
{
	NSObject* result = nil;
	int i = 0;
	NSEnumerator* enumerator = [PostAdaptorCollection enumerator];
	Class postClass;
	while ((postClass = [enumerator nextObject]) != nil) {
		if ((1 << i) & filterMask_) { /* do filter */
			PostAdaptor* adaptor = [postClass alloc];
			[adaptor initWithCallback:self];
			NSObject* tmp = [adaptor postEntry:params];
			if (tmp != nil && result == nil) {
				result = tmp;
			}
		}
		i++;
	}
	return result;
}

/**
 * ポスト成功時のコールバック
 */
- (void) successed:(NSString*)response
{
	D(@"successed: %@", response);
	@try {
		NSString* message = [NSString stringWithFormat:@"%@\n--- %@", [context_ documentTitle], response];
		[self notify:message];
	}
	@catch(NSException* e) {
		Log([e description]);
	}

	[response release];
}

/**
 * ポスト失敗時のコールバック(NSError)
 */
- (void) failedWithError:(NSError*)error
{
	[self failed:error];
}

/**
 * ポスト失敗時のコールバック(NSException)
 */
- (void) failedWithException:(NSException*)exception
{
	[self notify:[DelivererRules errorMessageWith:[exception description]]];
}

/**
 * ポストが成功した時
 */
- (void) posted:(NSData*)response
{
	@try {
		NSString* replyMessage = [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease];
		NSString* message = [NSString stringWithFormat:@"%@\n--- %@", [context_ documentTitle], replyMessage];
		[self notify:message];
	}
	@catch(NSException* e) {
		Log([e description]);
	}
}

/**
 * ポストが失敗した時
 */
- (void) failed:(NSError*)error
{
	NSString* msg = error != nil ? [error description] : @"";
	[self notify:[DelivererRules errorMessageWith:msg]];
}

/**
 * 汎用メッセージ処理
 */
- (void) notify:(NSString*)message
{
	[GrowlSupport notify:[[self postType] capitalizedString] description:message];
}

#pragma mark -
/**
 * メニューアイテムのタイトルを取得する
 *	@return タイトル
 */
- (NSString*) titleForMenuItem
{
	[self doesNotRecognizeSelector:_cmd]; /* _cmd はカレントセレクタ */
	return nil;
}

/**
 * メニューアイテム(複数)を生成する.
 *	@return メニューアイテムを格納した配列
 */
- (NSArray*) createMenuItems
{
	NSMutableArray* items = [[[NSMutableArray alloc] init] autorelease];
	int i = 0;
	NSUInteger mask = 1;
	D(@"initial count:%d", [PostAdaptorCollection count]);

	NSEnumerator* enumerator = [PostAdaptorCollection enumerator];
	Class postClass;
	while ((postClass = [enumerator nextObject]) != nil) {
		if ([postClass enableForMenuItem]) {
			NSMenuItem* menuItem = [self createMenuItem];
			NSString* suffix = [postClass titleForMenuItem];
			if (suffix != nil) {
				NSString* title = [menuItem title];
				[menuItem setTitle:[NSString stringWithFormat:@"%@ to %@", title, suffix]];
			}
			D(@"%@'s mask: 0x%x", [postClass className], mask);
			[menuItem setTag:mask];
			[items addObject:menuItem];
		}
		i++;
		mask = (1 << i);
	}
	return items;
}

/**
 * フィルタマスクを設定する.
 *
 * @param [in] param 要素0にaction:に渡すオブジェクト、要素1にマスクビットが
 *                   格納された配列
 */
- (void) actionWithMask:(NSArray*)param
{
	NSNumber* number = (NSNumber*)[param objectAtIndex:1];
	filterMask_ = [number unsignedIntegerValue];
	D(@"filterMask=0x%x", filterMask_);

	[self action:[param objectAtIndex:0]]; /* 移譲する */
}

#pragma mark -
#pragma mark Private Methods

/**
 * Deliverer の class を singleton な array にしまっておく
 */
- (NSArray*) sharedContexts
{
	static NSMutableArray* contexts = nil;

	@try {
		if (contexts == nil) {
			contexts = [NSMutableArray arrayWithObjects:
				  [GoogleReaderDelivererContext class]
				, [LDRDelivererContext class]
				, [DelivererContext class]
				, nil];
			[contexts retain]; // must
		}
	}
	@catch (NSException* e) {
		Log(@"Catch exception in sharedContexts: ", [e description]);
	}

	return contexts;
}

/**
 * メニュータイトルを作る
 */
- (NSString*) makeMenuTitle
{
	NSString* title = [NSString stringWithFormat:@"%@%@",
											[self titleForMenuItem],
											[context_ menuTitle]];
	return [DelivererRules menuItemTitleWith:title];
}

/**
 * メニューのアクション.
 *	@param sender メニューを送信したオブジェクト
 */
- (void)actionInternal:(id)sender
{
	static NSString * SUPPORTED_CLASS_NAME = @"NSMenuItem";

	 // 一応チェクしておく
	if (![[sender className] isEqualToString:SUPPORTED_CLASS_NAME]) {
		D(@"Not supported class. Must be %@", SUPPORTED_CLASS_NAME);
		return;
	}

	NSMenuItem * menuItem = (NSMenuItem*)sender;
	NSInteger tag = [menuItem tag];
	D(@"tag: 0x%x", tag);

	// タグが非ゼロならダイアログを表示する
	needEdit_ = (tag & MENUITEM_TAG_NEED_EDIT) ? YES : NO;
	tag &= MENUITEM_TAG_MASK;

	NSArray * param = [NSArray arrayWithObjects:self, [NSNumber numberWithUnsignedInteger:tag], nil];
	[self actionWithMask:param];
}
@end
