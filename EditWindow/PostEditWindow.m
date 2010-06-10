/**
 * @file PostEditWindow.h
 * @brief PostEditWindow class implementation
 * @author Masayuki YAMAYA
 * @date 2010-06-01
 */
#import "PostEditWindow.h"
#import "QuoteViewController.h"
#import "LinkViewController.h"
#import "PhotoViewController.h"
#import "Anchor.h"
#import "PostAdaptor.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

#define get_button_state(b)	((b) ? NSOnState : NSOffState)

@interface PostEditWindow ()
- (void)loadNibSafety;
@end

@implementation PostEditWindow

#pragma mark -
#pragma mark Public Methods

- (id)initWithPostType:(PostType)postType withInvocation:(NSInvocation *)invocation
{
	if ((self = [super init]) != nil) {
		postType_ = postType;
		invocation_ = [invocation retain];
	}
	return self;
}

- (void)dealloc
{
	D_METHOD;

	[invocation_ release];
	[super dealloc];
}

- (void)setContentsOptionWithPrivated:(BOOL)privated queued:(BOOL)queued
{
#pragma unused (queued)
	[self loadNibSafety];

	[privateButton_ setState:get_button_state(privated)];
	[queueingButton_ setState:get_button_state(privated)];
}

- (void)openSheet:(NSWindow * )window
{
	[self loadNibSafety];

	NSView * contentsView = nil;

	// ディスクリプションとコンテンツビューはタイプ別に処理する
	switch (postType_) {
	case LinkPostType:
		{
			Anchor * anchor = nil;
			NSString * description = nil;
			[invocation_ getArgument:&anchor atIndex:2];
			[invocation_ getArgument:&description atIndex:3];
			D(@"URL:%@", anchor.URL);
			D(@"title:%@", anchor.title);
			D(@"description:%@", description);
			[linkViewController_ setContentsWithTitle:anchor.title URL:anchor.URL description:description];
			D0(@"YYY");
			contentsView = [linkViewController_ view];
		}
		break;
	case QuotePostType:
		{
			NSString * quote = nil;
			NSString * source = nil;
			[invocation_ getArgument:&quote atIndex:2];
			[invocation_ getArgument:&source atIndex:3];
			D(@"quote:%@", quote);
			[quoteViewController_ setContentsWithText:quote source:source];
			contentsView = [quoteViewController_ view];
		}
		break;
	case PhotoPostType:
		{
			NSString * source = nil;
			NSString * caption = nil;
			NSString * throughURL = nil;
			[invocation_ getArgument:&source atIndex:2];
			[invocation_ getArgument:&caption atIndex:3];
			[invocation_ getArgument:&throughURL atIndex:4];
			[photoViewController_ setContentsWithImageURL:source caption:caption throughURL:throughURL];
			contentsView = [photoViewController_ view];
		}
		break;
	case VideoPostType:	
		NSAssert(0, @"unimplemented yet");
		break;
	default:
		NSAssert(0, @"unimplemented yet");
		break;
	}

	NSRect const contentsBounds = [contentsView bounds];
	NSRect const baseBounds = [genericView_ bounds];
	D(@"base=%f view=%f", baseBounds.size.height, contentsBounds.size.height);

	CGFloat const delta = baseBounds.size.height - contentsBounds.size.height;
	D(@"delta=%f", delta);

	NSRect newFrame = [postEditPanel_ frame];
	newFrame.size.height -= delta;
	[postEditPanel_ setFrame:newFrame display:NO];

	[genericView_ addSubview:contentsView];
	[genericView_ setBounds:contentsBounds];

	[tagsField_ setStringValue:@""];

	[NSApp beginSheet:postEditPanel_
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
}

#pragma mark -
#pragma mark Private Methods

- (void)loadNibSafety
{
	if (postEditPanel_ == nil) {
		[NSBundle loadNibNamed:@"PostEditWindow" owner:self];
	}
}

// あるオブジェクトAが、Nibファイルのオープンにより実体化された際にawakeFromNibメッセージを一度受け取ります。
// 続いて、そのオブジェクトAが別のnibファイル（例えばダイアログとか）をオープンする際に、loadNibNamedメソッドのownerに自分自身を指定すると・・・
// 先ほど書いたようにnib内のすべてのオブジェクトに対して準備ができたよというメッセージawakeFromNibが送られるので、filesOwnerにもメッセージが送信される事になります。
// つまり、このオブジェクトAは、自信が実体化された場合のほかに、自信がオープンしたnibファイルが実態化するごとに複数回awakeFromNibメッセージを受け取る事になります。
//
// したがって、awakeFromNibメソッド内では、データの初期化などはしない方が賢明だという事です。
- (void)awakeFromNib
{
	[super awakeFromNib];
}

- (void)updateInvocation
{
	// プライベートとキューイングの設定を反映
	PostAdaptor * adaptor = [invocation_ target];
	[adaptor setPrivate:[privateButton_ state] == NSOnState];
	SEL selector = @selector(setQueueing:);
	if ([adaptor respondsToSelector:selector]) {
		[adaptor performSelector:selector withObject:(id)([queueingButton_ state] == NSOnState)];
	}

	switch (postType_) {
	case LinkPostType:
		{
			Anchor * anchor = [Anchor anchorWithURL:linkViewController_.URL title:linkViewController_.title];
			NSString * description = linkViewController_.description;
			[invocation_ setArgument:&anchor atIndex:2];
			[invocation_ setArgument:&description atIndex:3];
		}
		break;
	case QuotePostType:
		{
			NSString * quote = quoteViewController_.quote;
			NSString * source = quoteViewController_.source;
			[invocation_ setArgument:&quote atIndex:2];
			[invocation_ setArgument:&source atIndex:3];
		}
		break;
	case PhotoPostType:
		{
			NSString * caption = photoViewController_.caption;
			NSString * throughURL = photoViewController_.throughURL;
			D(@"caption:%@", caption);
			[invocation_ setArgument:&caption atIndex:3];
			[invocation_ setArgument:&throughURL atIndex:4];
		}
		break;
	case VideoPostType:	
		NSAssert(0, @"unimplemented yet");
		break;
	default:
		{
			NSString * desc = [NSString stringWithFormat:@"%@ unimplemented yet", [NSString stringWithPostType:postType_]];
			NSAssert(0, desc);
		}
		break;
	}
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
#pragma unused (contextInfo)
	[sheet orderOut:self];

	if (returnCode == NSOKButton) {
		D0(@"OK");

		@try {
			[self updateInvocation];
			[invocation_ invoke];
		}
		@catch (NSException * e) {
			D0([e description]);
		}
		D0(@"invoked");
	} else {
		D0(@"Cancel");
	}
}

- (void)traverseSubviews:(NSView *)originView withInvocation:(NSInvocation *)invocation
{
	for (NSView * view in [originView subviews]) {
		[self traverseSubviews:view withInvocation:invocation];
	}
	[invocation setArgument:&originView atIndex:1];
	[invocation invoke];
}

- (void)validateEditingIfControl:(NSView *)view
{
	if ([view isKindOfClass:[NSControl class]]) {
		NSControl * control = (NSControl *)view;
		[control validateEditing];
	}
}

#pragma mark -
#pragma mark Interface Builder Integrated

- (IBAction)pressOKButton:(id)sender
{
#pragma unused (sender)
	[tagsField_ validateEditing];
	@try {
		SEL selector = @selector(validateEditingIfControl:);
		NSMethodSignature * signature = [self.class instanceMethodSignatureForSelector:selector];
		NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setTarget:self];
		[invocation setSelector:selector];
		[self traverseSubviews:[postEditPanel_ contentView] withInvocation:invocation];
	}
	@catch (NSException * e) {
		D0([e description]);
	}

	[postEditPanel_ close];
	[NSApp endSheet:postEditPanel_ returnCode:NSOKButton];

	postEditPanel_ = nil;
}

- (IBAction)pressCancelButton:(id)sender
{
#pragma unused (sender)
	[postEditPanel_ close];
	[NSApp endSheet:postEditPanel_ returnCode:NSCancelButton];

	postEditPanel_ = nil;
}
@end
