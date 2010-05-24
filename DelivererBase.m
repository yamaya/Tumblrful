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
#import "Log.h"

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

@interface DelivererBase (Private)
- (NSArray*) sharedContexts;
- (NSString*) makeMenuTitle;
- (void) actionInternal:(id)sender;
@end

@implementation DelivererBase (Private)
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
- (void) actionInternal:(id)sender
{
	static NSString* SUPPORTED_CLASS_NAME = @"NSMenuItem";

	if (![[sender className] isEqualToString:SUPPORTED_CLASS_NAME]) {
		V(@"Not supported class. Must be %@", SUPPORTED_CLASS_NAME);
		return; /* 一応チェクしておく */
	}

	NSMenuItem* menuItem = (NSMenuItem*)sender;
	V(@"actionInternal) tag: 0x%x", [menuItem tag]);

	NSArray* param = [NSArray arrayWithObjects:self, [NSNumber numberWithUnsignedInteger:[menuItem tag]], nil];
	[self actionWithMask:param];
}
@end

@implementation DelivererBase
/**
 * create.
 *	@param document 現在表示しているビューの DOMHTMLDocumentオブジェクト
 *	@param targetElement 選択していた要素の情報
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)targetElement
{
	[self doesNotRecognizeSelector:_cmd]; /* _cmd はカレントセレクタ */
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

	if ((self = [super init]) != nil) {
		NSEnumerator* enumerator = [[self sharedContexts] objectEnumerator];
		id clazz;
		while (clazz = [enumerator nextObject]) {
			if ([clazz match:document target:targetElement]) {
				context_ = [[[clazz alloc] initWithDocument:document target:targetElement] retain];
				break;
			}
		}
	}
	return self;
}

/**
 * Post タイプを取得する.
 *	@return ポストの種別を返す
 */
- (NSString*) postType
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

/**
 * MenuItemを生成して自身を action target に登録して返す.
 *	@return NSMenuItemオブジェクト
 */
- (NSMenuItem*) createMenuItem
{
	NSMenuItem* rootItem = [[[NSMenuItem alloc] init] retain];

	[rootItem setTitle:[self makeMenuTitle]];
	[rootItem setTarget:self];
	[rootItem setAction:@selector(actionInternal:)];

#if 0 /* SubMenuはいまいち使いにくい */
	/* "As Private" メニューを作って SubMenu に加える */
	NSMenuItem* subItem = [[[NSMenuItem alloc] initWithTitle:@"As Private" action:nil keyEquivalent:@""] autorelease];
	[subItem setTarget:self];
	[subItem setAction:@selector(actionAsPrivate:)];
	NSMenu* subMenu = [[[NSMenu alloc] initWithTitle:@"OptionalMenu"] autorelease];
	[subMenu addItem:subItem];
	[rootItem setSubmenu:subMenu];
#endif
	return rootItem;
}

/**
 * メニューのアクション.
 *	派生クラスがオーバーライドすることが前提。
 *	@param sender メニューを送信したオブジェクト
 */
- (void) action:(id)sender
{
	[self doesNotRecognizeSelector:_cmd]; /* _cmd はカレントセレクタ */
}
#pragma mark -
/**
 * "Link" post.
 *	@param url	URL文字列
 *	@param title	タイトル文字列
 */
- (void) postLink:(NSString*)url title:(NSString*)title
{
	Anchor* anchor = [Anchor anchorWithURL:url title:title];
	NSUInteger i = 0;
	NSEnumerator* enumerator = [PostAdaptorCollection enumerator];
	Class postClass;
	while (postClass = [enumerator nextObject]) {
		if ((1 << i) & filterMask_) { /* do filter */
			PostAdaptor* adaptor = [postClass alloc];
			[adaptor initWithCallback:self];
			[adaptor postLink:anchor description:nil];
		}
		i++;
	}
}

/**
 * "Quote" post.
 *	@param text 引用テキスト
 */
- (void)postQuote:(NSString*)text
{
	Anchor* anchor = [Anchor anchorWithURL:[context_ documentURL] title:[context_ documentTitle]];
	int i = 0;
	NSEnumerator* enumerator = [PostAdaptorCollection enumerator];
	Class postClass;
	while (postClass = [enumerator nextObject]) {
		if ((1 << i) & filterMask_) { /* do filter */
			PostAdaptor* adaptor = [postClass alloc];
			[adaptor initWithCallback:self];
			[adaptor postQuote:anchor quote:text];
		}
		i++;
	}
}

/**
 * "Photo" post.
 *	@param imageURL 画像のURL
 *	@param caption 概要テキスト
 *	@param url 画像をクリックした時の飛び先となる URL
 */
- (void) postPhoto:(NSString*)imageURL caption:(NSString*)caption through:(NSString*)url
{
	V(@"postPhoto: imageURL:%@", imageURL);

	Anchor* anchor = [Anchor anchorWithURL:url title:[context_ documentTitle]];
	int i = 0;
	NSEnumerator* enumerator = [PostAdaptorCollection enumerator];
	Class postClass;

	while (postClass = [enumerator nextObject]) {
		V(@"postPhoto: %d", filterMask_);
		if ((1 << i) & filterMask_) { /* do filter */
			PostAdaptor* adaptor = [postClass alloc];
			[adaptor initWithCallback:self];
			[adaptor postPhoto:anchor image:imageURL caption:caption];
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
- (void) postVideo:(NSString*)embed title:(NSString*)title caption:(NSString*)caption
{
	Anchor* anchor = [Anchor anchorWithURL:[context_ documentURL] title:title];
	int i = 0;
	NSEnumerator* enumerator = [PostAdaptorCollection enumerator];
	Class postClass;
	while (postClass = [enumerator nextObject]) {
		if ((1 << i) & filterMask_) { /* do filter */
			PostAdaptor* adaptor = [postClass alloc];
			[adaptor initWithCallback:self];
			[adaptor postVideo:anchor embed:embed caption:caption];
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
	V(@"successed: %@", response);
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
	V(@"initial count:%d", [PostAdaptorCollection count]);

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
			V(@"%@'s mask: 0x%x", [postClass className], mask);
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
	V(@"actionWithMask: mask=0x%x", filterMask_);

	[self action:[param objectAtIndex:0]]; /* 移譲する */
}
@end
