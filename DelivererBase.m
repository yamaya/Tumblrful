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
#import "InstapaperDelivererContext.h"
#import "Anchor.h"
#import "PostAdaptorCollection.h"
#import "PostAdaptor.h"
#import "GrowlSupport.h"
#import "PostEditWindowController.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

@interface DelivererBase ()
- (NSArray *)sharedContexts;
- (NSString *)makeMenuTitle;
- (void)actionInternal:(id)sender;
- (void)invoke:(NSInvocation *)invocation withType:(PostType)type;
- (void)invoke:(NSInvocation *)invocation withType:(PostType)type withImage:(NSImage *)image;
@end

@implementation DelivererBase

@synthesize webView = webView_;
@synthesize editEnabled = needEdit_;

+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
#pragma unused (document, clickedElement)
	[self doesNotRecognizeSelector:_cmd]; // _cmd はカレントセレクタ
	return nil;
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
	// targetにマッチするコンテキストを探す
	DelivererContext * context = nil;
	NSEnumerator * enumerator = [[self sharedContexts] objectEnumerator];
	id contextClass;
	while ((contextClass = [enumerator nextObject]) != nil) {
		if ([contextClass match:document target:targetElement]) {
			context = [[contextClass alloc] initWithDocument:document target:targetElement];
			break;
		}
	}

	// 初期化
	return [self initWithContext:context];
}

- (id)initWithContext:(DelivererContext *)context
{
	if ((self = [super init]) != nil) {
		context_ = [context retain];
		filterMask_ = 0;
		needEdit_ = NO;
	}
	return self;
}

- (NSString *)postType
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (void)dealloc
{
	[context_ release], context_ = nil;
	[webView_ release], webView_ = nil;

	[super dealloc];
}

- (NSMenuItem *)createMenuItem
{
	NSMenuItem * menuItem = [[[NSMenuItem alloc] init] autorelease];

	[menuItem setTitle:[self makeMenuTitle]];
	[menuItem setTarget:self];
	[menuItem setAction:@selector(actionInternal:)];

	return menuItem;
}

- (void)action:(id)sender
{
#pragma unused (sender)
	[self doesNotRecognizeSelector:_cmd]; // _cmd はカレントセレクタ
}

- (void)invoke:(NSInvocation *)invocation withType:(PostType)type
{
	if (needEdit_) {
		PostEditWindowController * controller = [[PostEditWindowController alloc] initWithPostType:type withInvocation:invocation];
		[controller openSheet:[[NSApplication sharedApplication] keyWindow]];
	}
	else {
		[invocation invoke];
	}
}

- (void)invoke:(NSInvocation *)invocation withType:(PostType)type withImage:(NSImage *)image
{
	D(@"needEdit=%d", needEdit_);

	if (needEdit_) {
		PostEditWindowController * controller = [[PostEditWindowController alloc] initWithPostType:type withInvocation:invocation];
		controller.image = image;
		[controller openSheet:[[NSApplication sharedApplication] keyWindow]];
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
		Anchor * anchor = [Anchor anchorWithURL:url title:title];
		NSUInteger i = 0;
		NSEnumerator * enumerator = [PostAdaptorCollection enumerator];
		Class adaptorClass;
		while ((adaptorClass = [enumerator nextObject]) != nil) {
			if ((1 << i) & filterMask_) { // do filter
				PostAdaptor * adaptor = [[[adaptorClass alloc] initWithCallback:self] autorelease];
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

- (void)postQuote:(NSString *)quote source:(NSString *)source
{
	@try {
		if (source == nil || [source length] == 0)
			source = context_.anchorToDocument;

		NSUInteger i = 0;
		NSEnumerator * enumerator = [PostAdaptorCollection enumerator];
		Class adaptorClass;
		while ((adaptorClass = [enumerator nextObject]) != nil) {
			if ((1 << i) & filterMask_) {	// フィルタリング
				PostAdaptor * adaptor = [[[adaptorClass alloc] initWithCallback:self] autorelease];
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

- (void)postPhoto:(NSString *)source caption:(NSString *)caption through:(NSString *)url image:(NSImage *)image
{
	D(@"source:%@", [source description]);
	D(@"caption:%@", [caption description]);
	D(@"url:%@", [url description]);
	D(@"image:%@", [image description]);

	NSUInteger i = 0;
	NSEnumerator * enumerator = [PostAdaptorCollection enumerator];
	Class adaptorClass;
	while ((adaptorClass = [enumerator nextObject]) != nil) {
		if ((1 << i) & filterMask_) {	// do filter
			PostAdaptor * adaptor = [[[adaptorClass alloc] initWithCallback:self] autorelease];
			NSInvocation * invocation = [self typedInvocation:@selector(postPhoto:caption:throughURL:image:) withAdaptor:adaptor];
			[invocation setArgument:&source atIndex:2];
			[invocation setArgument:&caption atIndex:3];
			[invocation setArgument:&url atIndex:4];
			[invocation setArgument:&image atIndex:5];
			[invocation retainArguments];
			[self invoke:invocation withType:PhotoPostType withImage:image];
		}
		i++;
	}
}

- (void)postVideo:(NSString *)embed caption:(NSString *)caption
{
	NSUInteger i = 0;
	NSEnumerator * enumerator = [PostAdaptorCollection enumerator];
	Class adaptorClass;
	while ((adaptorClass = [enumerator nextObject]) != nil) {
		if ((1 << i) & filterMask_) {	// do filter
			PostAdaptor * adaptor = [[[adaptorClass alloc] initWithCallback:self] autorelease];
			NSInvocation * invocation = [self typedInvocation:@selector(postVideo:caption:) withAdaptor:adaptor];
			[invocation setArgument:&embed atIndex:2];
			[invocation setArgument:&caption atIndex:3];
			[invocation retainArguments];
			[self invoke:invocation withType:VideoPostType];
		}
		i++;
	}
}

- (void)postEntry:(NSDictionary *)params
{
	NSUInteger i = 0;
	NSEnumerator * enumerator = [PostAdaptorCollection enumerator];
	Class adaptorClass;
	while ((adaptorClass = [enumerator nextObject]) != nil) {
		if ((1 << i) & filterMask_) {	// do filter
			PostAdaptor * adaptor = [[adaptorClass alloc] initWithCallback:self];
			NSInvocation * invocation = [adaptor invocationWithPostType:ReblogPostType];
			[invocation setArgument:&params atIndex:2];
			[invocation retainArguments];
			[self invoke:invocation withType:ReblogPostType];
		}
		i++;
	}
}

- (void)successed:(NSString *)response
{
	D0(response);
	D(@"self.retainCount=%x", [self retainCount]);

	@try {
		NSString * addition = @"";
		if (response != nil && [response length] > 0) {
			addition = [NSString stringWithFormat:@"\n--- %@", response];
		}
		[self notify:[NSString stringWithFormat:@"%@%@", context_.documentTitle, addition]];
	}
	@catch (NSException * e) {
		D0([e description]);
	}
}

/**
 * ポスト失敗時のコールバック(NSError)
 */
- (void)failedWithError:(NSError *)error
{
	NSString* msg = error != nil ? [error description] : @"";
	[self notify:[DelivererRules errorMessageWith:msg]];
}

/**
 * ポスト失敗時のコールバック(NSException)
 */
- (void)failedWithException:(NSException *)exception
{
	[self notify:[DelivererRules errorMessageWith:[exception description]]];
}

/**
 * 汎用メッセージ処理
 */
- (void)notify:(NSString*)message
{
	[GrowlSupport notifyWithTitle:[[self postType] capitalizedString] description:message];
}

#pragma mark -
- (NSString *)titleForMenuItem
{
	[self doesNotRecognizeSelector:_cmd]; // _cmd はカレントセレクタ
	return nil;
}

- (NSArray *)createMenuItems
{
	NSMutableArray * items = [NSMutableArray array];
	NSUInteger i = 0;
	NSUInteger mask = 1;

	NSEnumerator * enumerator = [PostAdaptorCollection enumerator];
	Class adaptorClass;
	while ((adaptorClass = [enumerator nextObject]) != nil) {
		if ([adaptorClass enableForMenuItem:[self postType]]) {
			NSMenuItem * menuItem = [self createMenuItem];
			NSString * suffix = [adaptorClass titleForMenuItem];
			if (suffix != nil) {
				NSString * title = [menuItem title];
				[menuItem setTitle:[NSString stringWithFormat:@"%@ to %@", title, suffix]];
			}
			D(@"%@'s mask: 0x%x", [adaptorClass className], mask);
			[menuItem setTag:mask];
			[items addObject:menuItem];
		}
		i++;
		mask = (1 << i);
	}
	return items;
}

- (void)actionWithMask:(NSArray *)param
{
	NSNumber * number = (NSNumber *)[param objectAtIndex:1];
	filterMask_ = [number unsignedIntegerValue];
	D(@"filterMask=0x%x", filterMask_);

	[self action:[param objectAtIndex:0]]; // 移譲する
}

#pragma mark -
#pragma mark Private Methods

- (NSArray *)sharedContexts
{
	static NSMutableArray * contexts = nil;

	@try {
		if (contexts == nil) {
			contexts = [NSMutableArray arrayWithObjects:
				  [GoogleReaderDelivererContext class]
				, [LDRDelivererContext class]
				, [InstapaperDelivererContext class]
				, [DelivererContext class]
				, nil];
			[contexts retain]; // must
		}
	}
	@catch (NSException * e) {
		D0([e description]);
	}

	return contexts;
}

// メニュータイトルを作る
- (NSString *)makeMenuTitle
{
	NSString * title = [NSString stringWithFormat:@"%@%@", [self titleForMenuItem], context_.menuTitle];
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

	NSMenuItem * menuItem = (NSMenuItem *)sender;
	NSInteger tag = [menuItem tag];
	D(@"tag: 0x%x", tag);

	// タグが非ゼロならダイアログを表示する
	needEdit_ = (tag & MENUITEM_TAG_NEED_EDIT) ? YES : NO;
	tag &= MENUITEM_TAG_MASK;

	NSArray * param = [NSArray arrayWithObjects:self, [NSNumber numberWithUnsignedInteger:tag], nil];
	[self actionWithMask:param];
}
@end
