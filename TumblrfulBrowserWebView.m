/**
 * @file TumblrfulBrowserWebView.m
 * @brief TumblrfulBrowserWebView class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMNode.h
// /System/Library/Frameworks/WebKit.framework/Headers/WebView.h
#import "TumblrfulBrowserWebView.h"
#import "QuoteDeliverer.h"
#import "TwitterQuoteDeliverer.h"
#import "LinkDeliverer.h"
#import "ReblogDeliverer.h"
#import "LDRReblogDeliverer.h"
#import "GoogleReaderReblogDeliverer.h"
#import "PhotoDeliverer.h"
#import "FlickrPhotoDeliverer.h"
#import "VideoDeliverer.h"
#import "VimeoVideoDeliverer.h"
#import "SlideShareVideoDeliverer.h"
#import "CaptureDeliverer.h"
#import "TumblrPost.h"
#import "GrowlSupport.h"
#import "PostAdaptorCollection.h"
#import "TumblrPostAdaptor.h"
#import "DeliciousPostAdaptor.h"
#import "InstapaperPostAdaptor.h"
#import "YammerPostAdaptor.h"
#import "GoogleReaderDelivererContext.h"
#import "LDRDelivererContext.h"
#import "DelivererRules.h"
#import "NSObject+Supersequent.h"
#import "TumblrfulWebHTMLView.h"
#import "DebugLog.h"
#import <WebKit/DOMHTML.h>

static BOOL captureEnabled_ = NO;
static DOMHTMLElement * selectedElement_ = nil;

@interface ColoredView : NSView
{
	NSColor * color_;
	NSTrackingArea * trackingArea_;
}
-(void)setColor:(NSColor *)color;
@end

@implementation ColoredView
- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame]) != nil) {
		color_ = [NSColor windowBackgroundColor]; //初期の色は、Windowの背景色

		trackingArea_ = [[NSTrackingArea alloc] initWithRect:[self bounds] options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow) owner:self userInfo:nil];
		[self addTrackingArea:trackingArea_];
		[trackingArea_ release];
	}
	return self;
}

- (void)dealloc
{
	[self removeTrackingArea:trackingArea_];
	trackingArea_ = nil;
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	[color_ set];
	NSRectFill(rect);
}


-(void)setColor:(NSColor *)color
{
	color_ = color;
	[self display];
}

- (NSView *)hitTest:(NSPoint)point
{
#pragma unused (point)
	return nil;
}
@end

// POST先のサービスを識別するマスク値
static const NSUInteger POST_MASK_NONE = 0x0;
static const NSUInteger POST_MASK_TUMBLR = 0x1;
static const NSUInteger POST_MASK_DELICIOUS = 0x2;
static const NSUInteger POST_MASK_ALL = 0x3;

@implementation WebView (TumblrfulBrowserWebView)

- (NSArray *)webView_SwizzledByTumblrful:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems;
{
	// オリジナルのメソッドを呼ぶ
	NSArray * originals =  [self webView_SwizzledByTumblrful:sender contextMenuItemsForElement:element defaultMenuItems:defaultMenuItems];
	return [self buildMenu:[originals mutableCopy] element:element]; // add Tumblrful to originals menu
}

- (NSArray *)sharedDelivererClasses
{
	static NSMutableArray* classes = nil;

	if (classes == nil) {
		// setup PostAdaptorCollection
		[PostAdaptorCollection add:[TumblrPostAdaptor class]];
		//[PostAdaptorCollection add:[UmesuePostAdaptor class]];
		[PostAdaptorCollection add:[DeliciousPostAdaptor class]];
		[PostAdaptorCollection add:[InstapaperPostAdaptor class]];
		[PostAdaptorCollection add:[YammerPostAdaptor class]];

		classes = [NSMutableArray arrayWithObjects:
			  [GoogleReaderReblogDeliverer class]
			, [LDRReblogDeliverer class]
			, [ReblogDeliverer class]
			, [FlickrPhotoDeliverer class]
			, [PhotoDeliverer class]
			, [QuoteDeliverer class]
			, [TwitterQuoteDeliverer class]
			, [VimeoVideoDeliverer class]
			, [SlideShareVideoDeliverer class]
			, [VideoDeliverer class]
			, [LinkDeliverer class]
			, [CaptureDeliverer class]
			, nil];
		[classes retain]; // must
	}
	return classes;
}

- (BOOL)validateAccount
{
	NSString * mail = [TumblrPost username];
	NSString * pass = [TumblrPost password];

	return (mail != nil) && ([mail length] > 0) && (pass != nil) && ([pass length] > 0);
}

- (NSArray *)buildMenu:(NSMutableArray *)menus element:(NSDictionary *)clickedElement
{
	// アカウントが未設定ならメニューを追加しない
	if (![self validateAccount]) {
		[GrowlSupport notifyWithTitle:@"Tumblrful" description:@"Email or Password not entered."];
		return menus;
	}

	NSMutableArray * additionalMenus = [NSMutableArray array];
	NSMenu * subMenu = [[[NSMenu alloc] initWithTitle:@"Editting Post"] autorelease];
	BOOL preferredExist = NO;
	Class delivererClass;
	NSEnumerator * classEnumerator = [[self sharedDelivererClasses] objectEnumerator];
	while ((delivererClass = [classEnumerator nextObject]) != nil) {
		DelivererBase * deliverer = (DelivererBase *)[delivererClass create:(DOMHTMLDocument *)[self mainFrameDocument] element:clickedElement];
		if (deliverer != nil) {
			deliverer.webView = self;
			NSMenuItem * menuItem;
			NSArray * menuItems = [deliverer createMenuItems];	// autoreleased
			NSEnumerator * menuEnumerator = [menuItems objectEnumerator];
			while ((menuItem = [menuEnumerator nextObject]) != nil) {
				if (!preferredExist) {
					[additionalMenus addObject:menuItem];
					preferredExist = YES;
				}

				// サブメニューにダイアログで編集するためのメニューを追加しておく
				menuItem = [menuItem copy];
				NSString * title = [menuItem title];
				NSRange range = [title rangeOfString:[DelivererRules menuItemTitleWith:@""]];
				if (range.location != NSNotFound) {
					[menuItem setTitle:[title substringFromIndex:(range.location + range.length)]];
					NSInteger const tag = [menuItem tag] | MENUITEM_TAG_NEED_EDIT;
					[menuItem setTag:tag];
					[subMenu addItem:menuItem];
				}
			}

		}
	}

	if ([additionalMenus count] > 0) {
		NSUInteger i = 0;
		for (NSMenuItem * menuItem in additionalMenus) {
			[menus insertObject:menuItem atIndex:i++];
		}

		// ダイアログを表示してポストするためのサブメニューを作る
		NSMenuItem * menuItem = [[[NSMenuItem alloc] initWithTitle:@"Share..." action:nil keyEquivalent:@""] autorelease];
		[menuItem setSubmenu:subMenu];
		[menus insertObject:menuItem atIndex:i++];

		// セパレータを追加する
		[menus insertObject:[NSMenuItem separatorItem] atIndex:i];
	}
	else {
		[GrowlSupport notifyWithTitle:@"Tumblrful" description:@"Error - Could not detect type of post"];
	}

	return menus;
}

/**
 * aciotn: セレクタを発動する
 * @param [in] target ポスト対象要素
 * @param [in] document 評価対象となる DOMドキュメント
 * @param [in] endpoint ポスト先を示すビット値
 */
- (BOOL)invokeAction:(DOMHTMLElement *)target document:(DOMHTMLDocument *)document endpoint:(NSUInteger)endpoint
{
	if (target == nil) {
		return NO;
	}

	SEL sel = @selector(actionWithMask:);
	Class photoClass = [PhotoDeliverer class];
	Class reblogClass = [ReblogDeliverer class];

	@try {
		// 対象要素が Imageなら WebElementImageURLKey で ImageのソースURLを抽出する
		NSMutableDictionary * elements = [NSMutableDictionary dictionaryWithObjectsAndKeys:target, WebElementDOMNodeKey, nil];
		if ([target isKindOfClass:[DOMHTMLImageElement class]]) {
			[elements setObject:[(DOMHTMLImageElement *)target src] forKey:WebElementImageURLKey];
		}

		for (Class delivererClass in [[self sharedDelivererClasses] objectEnumerator]) {
			id<Deliverer> maybeDeliver = [delivererClass create:document element:elements];
			if (maybeDeliver == nil) {
				continue;
			}

			// Deliverer が Photo か Reblog の場合のみキー入力によるポストを有効にするものとする
			// Quote はセレクションが出来ないと不可だし、Link は使用頻度が低いので
			DelivererBase * deliverer = (DelivererBase *)maybeDeliver;
			if ([deliverer respondsToSelector:sel] && ([deliverer isKindOfClass:photoClass] || [deliverer isKindOfClass:reblogClass])) {
				NSBeep();

				// セレクタに渡す引数を作成して実行する
				NSArray * param = [NSArray arrayWithObjects:self, [NSNumber numberWithUnsignedInteger:endpoint], nil];
				[deliverer performSelectorOnMainThread:sel withObject:param waitUntilDone:YES];

				[deliverer release];
				return YES;
			}
		}
	}
	@catch (NSException * e) {
		D0([e description]);
	}

	return NO;
}

/**
 * ポスト先サービス(エンドポイント)を示すビット値を組み立てる
 * @param [in] event NSEvent object for Event.
 * @return ビット値
 */
- (NSUInteger)endpointByKeyPress:(NSEvent *)event
{
	NSUInteger endpoint = POST_MASK_NONE;

	// Ctrlキーが押されたかをチェック(オートリピート時は無視)
	if ([event type] == NSKeyDown && ([event modifierFlags] & NSControlKeyMask) == NSControlKeyMask && ![event isARepeat]) {
		// キー毎にビットマスクを決める
		NSString* c = [event charactersIgnoringModifiers];
		if ([c isEqualToString:@"t"]) {
			// Tumblr にポストしたら無条件に Umesue にもポストする
			endpoint = POST_MASK_TUMBLR;
		}
		else if ([c isEqualToString:@"d"]) {
			// delicious もそれだけ
			endpoint = POST_MASK_DELICIOUS;
		}
	}

	return endpoint;
}

- (BOOL)performKeyEquivalent_SwizzledByTumblrful:(NSEvent *)event
{
	// ESCキーの場合 captureをキャンセル
	if ([event type] == NSKeyDown && [event keyCode] == 0x1b) {
		[selectedElement_ release], selectedElement_ = nil;
		[[self sharedSelectionView] setHidden:YES];
		[WebHTMLView clearMouseDownInvocation];
		captureEnabled_ = NO;
	}

	// キー入力に対応するエンドポイントを得る。
	// 無ければオリジナルのメソッドを呼び出して終わり
	NSUInteger endpoint = [self endpointByKeyPress:event];
	if ((endpoint & POST_MASK_ALL) == 0) {
		return [self performKeyEquivalent_SwizzledByTumblrful:event];
	}

	// このビューに関する HTMLドキュメントの URL を得る
	// 無ければオリジナルのメソッドを呼び出して終わり
	DOMHTMLDocument * document = (DOMHTMLDocument *)[self mainFrameDocument];
	if (document == nil) {
		return [self performKeyEquivalent_SwizzledByTumblrful:event];
	}

	// 処理すべき HTMLドキュメントかどうかを判定させる
	// アクションを実行を試みる
	// 実行できたら処理終了
	// 無ければオリジナルのメソッドを呼び出す
	BOOL processed = NO;
	NSArray * ccs = [NSArray arrayWithObjects:[GoogleReaderDelivererContext class], [LDRDelivererContext class], nil];
	for (Class cc in ccs) {
		DOMHTMLElement * element = [cc matchForAutoDetection:document windowScriptObject:[self windowScriptObject]];
		processed = [self invokeAction:element document:document endpoint:endpoint];
		if (processed) {
			break;
		}
	}
	if (!processed) {
		processed = [self performKeyEquivalent_SwizzledByTumblrful:event];
	}

	return processed;
}

- (NSView *)sharedSelectionView
{
	static ColoredView * view = nil;
	if (view == nil) {
		view = [[ColoredView alloc] initWithFrame:NSZeroRect];
		[view setAlphaValue:0.5];
		[view setColor:[NSColor redColor]];
	}
	if (![self isDescendantOf:view]) {
		[view setFrame:NSZeroRect];
		[view setHidden:YES];
		[self addSubview:view];
	}
	return view;
}

- (void)setCaptureEnabledByTumblrful:(NSNumber *)enabled
{
	captureEnabled_ = [enabled boolValue];
	D(@"captureEnabled_=%d", captureEnabled_);

	SEL selector = @selector(imageCaptureOfDOMElement);
	NSMethodSignature * signature = [self.class instanceMethodSignatureForSelector:selector];
	NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setTarget:self];
	[invocation setSelector:selector];
	[WebHTMLView setMouseDownInvocation:invocation];
}

- (DOMHTMLElement *)deepElementAtPoint:(NSPoint)point withOrigin:(DOMHTMLElement *)parentNode
{
	DOMNodeList * children = parentNode.childNodes;
	if (children != nil) {
		unsigned int const N = children.length;
		for (unsigned int i = 0; i < N; i++) {
			DOMHTMLElement * child = (DOMHTMLElement *)[children item:i];
			NSRect const boundingBox = [child boundingBox];
			if (NSPointInRect(point, boundingBox)) {
				return [self deepElementAtPoint:point withOrigin:child];
			}
		}
	}
	return parentNode;
}

// このメソッドが呼ばれた時の firstResponderは WebHTMLViewになっている。
- (void)mouseMoved_SwizzledByTumblrful:(NSEvent *)event
{
	if (!captureEnabled_) return;
	@try {
		NSPoint const pt0 = [self convertPoint:[event locationInWindow] fromView:nil];
		NSDictionary * elementInfo = [self elementAtPoint:pt0];
		if (elementInfo != nil) {
			DOMHTMLElement * element = [elementInfo objectForKey:WebElementDOMNodeKey];
			if (element != nil) {
				NSView * docView = [[[[element ownerDocument] webFrame] frameView] documentView];
				NSPoint const pt1 = [self convertPoint:pt0 toView:docView];
				element = [self deepElementAtPoint:pt1 withOrigin:element];
				if (element != nil) {
					if (selectedElement_ != element) {
						[selectedElement_ release];
						selectedElement_ = [element retain];
						NSRect box = [self convertRect:[selectedElement_ boundingBox] fromView:docView];
						NSView * view = [self sharedSelectionView];
						if (!NSEqualRects([view frame], box)) {
							[view setFrame:box];
						}
						[view setHidden:NO];
					}
				}
			}
		}
	}
	@catch (NSException * e) {
		D0([e description]);
		[WebHTMLView clearMouseDownInvocation];
	}
	@finally {
		invokeSupersequent(event);
	}
}

- (void)imageCaptureOfDOMElement
{
	if (!(captureEnabled_ && selectedElement_ != nil)) return;

	captureEnabled_ = NO;
	[[self sharedSelectionView] setHidden:YES];

	DOMHTMLDocument * document = (DOMHTMLDocument *)[selectedElement_ ownerDocument];

	NSRect const boundingBox =
		[self convertRect:[selectedElement_ boundingBox]
				 fromView:[[[document webFrame] frameView] documentView]];
	NSBitmapImageRep * imageRep = [self bitmapImageRepForCachingDisplayInRect:boundingBox];
	[self cacheDisplayInRect:boundingBox toBitmapImageRep:imageRep];
	NSImage * image = [[[NSImage alloc] initWithSize:boundingBox.size] autorelease];
	[image addRepresentation:imageRep];

	NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:
		selectedElement_, WebElementDOMNodeKey,
		image, WebElementImageKey,
		nil];
	PhotoDeliverer * deliverer = (PhotoDeliverer *)[PhotoDeliverer create:document element:info];
	if (deliverer != nil) {
		// FIXME ここ、ぐだぐだー
		NSUInteger const tag = 0x1 | MENUITEM_TAG_NEED_EDIT;
		deliverer.editEnabled = YES;
		[deliverer actionWithMask:
			[NSArray arrayWithObjects:
				deliverer,
				[NSNumber numberWithUnsignedInteger:tag],
				nil]];
	}

	[selectedElement_ release], selectedElement_ = nil;
	NSBeep();
}
@end
