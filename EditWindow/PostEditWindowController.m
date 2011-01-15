/**
 * @file PostEditWindowController.h
 * @brief PostEditWindowController class implementation
 * @author Masayuki YAMAYA
 * @date 2010-06-01
 */
#import "PostEditWindowController.h"
#import "QuoteViewController.h"
#import "LinkViewController.h"
#import "PhotoViewController.h"
#import "VideoViewController.h"
#import "Anchor.h"
#import "PostAdaptor.h"
#import "NSString+Tumblrful.h"
#import "GrowlSupport.h"
#import "DebugLog.h"

#define get_button_state(b)	((b) ? NSOnState : NSOffState)

@interface PostEditWindowController ()
- (void)loadNibSafety;
- (void)setContentsViewWithPostType:(PostType)postType display:(BOOL)display;
- (void)setContentsViewWithPostType:(PostType)postType contents:(NSDictionary *)contents display:(BOOL)display;
- (void)resizeWindowOnSpotWithRect:(NSRect)aRect display:(BOOL)display animate:(BOOL)animate;
- (void)updateInvocationForReblog;
- (NSImage *)imageWithURL:(NSString *)imageURL;
- (NSString *)stringWithAppendingParagraph:(NSString *)s;
@end

@implementation PostEditWindowController

@synthesize image = image_;

#pragma mark -
#pragma mark Public Methods

- (id)initWithPostType:(PostType)postType withInvocation:(NSInvocation *)invocation
{
	if ((self = [super init]) != nil) {
		postType_ = postType;
		invocation_ = [invocation retain];
		image_ = nil;
		extractedContents_ = nil;
	}
	return self;
}

- (void)dealloc
{
	D_METHOD;

	[image_ release];
	[invocation_ release];
	[extractedContents_ release];
	[super dealloc];
}

- (void)setContentsOptionWithPrivated:(BOOL)privated queued:(BOOL)queued
{
	[self loadNibSafety];

	[privateButton_ setState:get_button_state(privated)];
	[queueingButton_ setState:get_button_state(queued)];
}

- (void)openSheet:(NSWindow *)window
{
	D_METHOD;

	[self loadNibSafety];

	[self setContentsViewWithPostType:postType_ display:NO];

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

- (void)setContentsViewWithPostType:(PostType)postType display:(BOOL)display
{
	D_METHOD;

	NSMutableDictionary * contents = [NSMutableDictionary dictionary];

	Anchor * anchor = nil;
	NSString * description = nil;
	NSString * quote = nil;
	NSString * source = nil;
	NSString * caption = nil;
	NSString * throughURL = nil;
	NSString * embed = nil;
	NSDictionary * reblogContents = nil;

	switch (postType) {
	case LinkPostType:
		[invocation_ getArgument:&anchor atIndex:2];
		[invocation_ getArgument:&description atIndex:3];
		[contents setObject:anchor.URL forKey:@"URL"];
		[contents setObject:anchor.title forKey:@"title"];
		[contents setObject:description forKey:@"description"];
		break;
	case QuotePostType:
		[invocation_ getArgument:&quote atIndex:2];
		[invocation_ getArgument:&source atIndex:3];
		[contents setObject:quote forKey:@"quote"];
		[contents setObject:source forKey:@"source"];
		break;
	case PhotoPostType:
		[invocation_ getArgument:&source atIndex:2];
		[invocation_ getArgument:&caption atIndex:3];
		[invocation_ getArgument:&throughURL atIndex:4];
		[contents setObject:source forKey:@"source"];
		[contents setObject:caption forKey:@"caption"];
		[contents setObject:throughURL forKey:@"throughURL"];
		break;
	case VideoPostType:	
		[invocation_ getArgument:&embed atIndex:2];
		[invocation_ getArgument:&caption atIndex:3];
		[contents setObject:embed forKey:@"embed"];
		[contents setObject:caption forKey:@"caption"];
		break;
	case ReblogPostType:	
		[invocation_ getArgument:&reblogContents atIndex:2];
		[contents setObject:reblogContents forKey:@"contents"];
		break;
	default:
		NSAssert(0, @"unimplemented yet");
		break;
	}
	[self setContentsViewWithPostType:postType contents:contents display:display];
}

- (void)setContentsViewWithPostType:(PostType)postType contents:(NSDictionary *)contents display:(BOOL)display
{
	NSView * contentsView = [[genericView_ subviews] lastObject];
	if (contentsView != nil) {
		[contentsView removeFromSuperview];
		contentsView = nil;
	}

	NSString * URL = nil;
	NSString * title = nil;
	NSString * description = nil;
	NSString * quote = nil;
	NSString * source = nil;
	NSString * caption = nil;
	NSString * throughURL = nil;
	NSString * embed = nil;
	NSDictionary * reblogContents = nil;
	NSProgressIndicator * indicator = nil;
	TumblrReblogExtractor * extractor = nil;

	// ディスクリプションとコンテンツビューはタイプ別に処理する
	switch (postType) {
	case LinkPostType:
		URL = [contents objectForKey:@"URL"];
		title = [contents objectForKey:@"title"];
		description = [contents objectForKey:@"description"];
		description = [self stringWithAppendingParagraph:description];
		[linkViewController_ setContentsWithTitle:title URL:URL description:description];
		contentsView = [linkViewController_ view];
		break;
	case QuotePostType:
		quote = [contents objectForKey:@"quote"];
		source = [contents objectForKey:@"source"];
		source = [self stringWithAppendingParagraph:source];
		[quoteViewController_ setContentsWithText:quote source:source];
		contentsView = [quoteViewController_ view];
		break;
	case PhotoPostType:
		source = [contents objectForKey:@"source"];
		caption = [contents objectForKey:@"caption"];
		caption = [self stringWithAppendingParagraph:caption];
		throughURL = [contents objectForKey:@"throughURL"];
		[photoViewController_ setContentsWithImageURL:source image:image_ caption:caption throughURL:throughURL];
		contentsView = [photoViewController_ view];
		break;
	case VideoPostType:	
		embed = [contents objectForKey:@"embed"];
		caption = [contents objectForKey:@"caption"];
		caption = [self stringWithAppendingParagraph:caption];
		[videoViewController_ setContentsWithEmbed:embed caption:caption];
		contentsView = [videoViewController_ view];
		break;
	case ReblogPostType:	
		reblogContents = [contents objectForKey:@"contents"];

		indicator = [[NSProgressIndicator alloc] initWithFrame:[genericView_ bounds]];
		[indicator setStyle:NSProgressIndicatorSpinningStyle];
		[indicator startAnimation:self];
		contentsView = [indicator autorelease];

		extractor = [[TumblrReblogExtractor alloc] initWithDelegate:self];
		{
			NSString * postID = [reblogContents objectForKey:@"pid"];
			NSString * reblogKey = [reblogContents objectForKey:@"rk"];
			SEL selector = @selector(startWithPostID:withReblogKey:);
			NSMethodSignature * signature = [extractor.class instanceMethodSignatureForSelector:selector];
			NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
			[invocation setTarget:extractor];
			[invocation setSelector:selector];
			[invocation setArgument:&postID atIndex:2];
			[invocation setArgument:&reblogKey atIndex:3];
			[NSTimer scheduledTimerWithTimeInterval:0.3 invocation:invocation repeats:NO];
		}
		break;
	default:
		NSAssert(0, @"unimplemented yet");
		break;
	}

	NSRect const contentsBounds = [contentsView bounds];
	NSRect const baseBounds = [genericView_ bounds];
	//D(@"base=%f view=%f", baseBounds.size.height, contentsBounds.size.height);

	CGFloat const delta = baseBounds.size.height - contentsBounds.size.height;
	//D(@"delta=%f", delta);

	NSRect newFrame = [postEditPanel_ frame];
	newFrame.size.height -= delta;
	[self resizeWindowOnSpotWithRect:newFrame display:display animate:YES];

	[genericView_ addSubview:contentsView];
	[genericView_ setBounds:contentsBounds];
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
	adaptor.privated = ([privateButton_ state] == NSOnState);
	adaptor.queuingEnabled = ([queueingButton_ state] == NSOnState);
	adaptor.options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:([twitterButton_ state] == NSOnState ? YES : NO)], @"twitter", nil];

	Anchor * anchor = nil;
	NSString * description = nil;
	NSString * quote = nil;
	NSString * source = nil;
	NSString * caption = nil;
	NSString * throughURL = nil;
	NSString * embed = nil;

	switch (postType_) {
	case LinkPostType:
		anchor = [Anchor anchorWithURL:linkViewController_.URL title:linkViewController_.title];
		description = linkViewController_.description;
		[invocation_ setArgument:&anchor atIndex:2];
		[invocation_ setArgument:&description atIndex:3];
		break;
	case QuotePostType:
		quote = quoteViewController_.quote;
		source = quoteViewController_.source;
		[invocation_ setArgument:&quote atIndex:2];
		[invocation_ setArgument:&source atIndex:3];
		break;
	case PhotoPostType:
		caption = photoViewController_.caption;
		throughURL = photoViewController_.throughURL;
		[invocation_ setArgument:&caption atIndex:3];
		[invocation_ setArgument:&throughURL atIndex:4];
		break;
	case VideoPostType:	
		embed = videoViewController_.embed;
		caption = videoViewController_.caption;
		[invocation_ setArgument:&embed atIndex:2];
		[invocation_ setArgument:&caption atIndex:3];
		break;
	case ReblogPostType:
		[self updateInvocationForReblog];
		break;
	default:
		{
			NSString * additionalMessage = @"";
			if (extractedContents_ != nil) {
				additionalMessage = [NSString stringWithFormat:@" %@/%@ %@"
					, [[extractedContents_ objectForKey:@"pid"] description]
					, [[extractedContents_ objectForKey:@"rk"] description]
					, [[extractedContents_ objectForKey:@"type"] description]
					];
			}
			NSString * postTypeString = [NSString stringWithPostType:postType_];
			NSString * message = [NSString stringWithFormat:@"%@ unimplemented yet.%@", postTypeString, additionalMessage];
			D0(message);
			[GrowlSupport notifyWithTitle:[NSString stringWithPostType:postType_] description:message];
		}
		return;
	}
}

- (void)updateInvocationForReblog
{
	NSMutableDictionary * contents = [NSMutableDictionary dictionaryWithDictionary:extractedContents_]; 

	// サイトから取得したりブログコンテンツを編集された内容で上書きする
	switch ([[extractedContents_ objectForKey:@"type"] postType]) {
	case LinkPostType:
		[contents setObject:linkViewController_.URL forKey:@"post[one]"];
		[contents setObject:linkViewController_.title forKey:@"post[two]"];
		[contents setObject:linkViewController_.description forKey:@"post[three]"];
		break;
	case QuotePostType:
		[contents setObject:quoteViewController_.quote forKey:@"post[one]"];
		[contents setObject:quoteViewController_.source forKey:@"post[two]"];
		break;
	case PhotoPostType:
		[contents setObject:photoViewController_.caption forKey:@"post[two]"];
		[contents setObject:photoViewController_.throughURL forKey:@"post[three]"];
		break;
	case VideoPostType:	
		[contents setObject:videoViewController_.embed forKey:@"post[one]"];
		[contents setObject:videoViewController_.caption forKey:@"post[two]"];
		break;
	default:
		D(@"why?: %@", [contents description]);
		return;
	}
	[contents removeObjectForKey:@"type"];

	D0([contents description]);
	PostAdaptor * adaptor = [invocation_ target];
	D(@"extractEnabled: %d to %d", adaptor.extractEnabled, NO);
	adaptor.extractEnabled = NO;
	[invocation_ setArgument:&contents atIndex:2];
	[invocation_ retainArguments];
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
			D0(@"invoked");
		}
		@catch (NSException * e) {
			D0([e description]);
		}
	} else {
		D0(@"Cancel");
	}
}

- (void)traverseSubviews:(NSView *)originView withInvocation:(NSInvocation *)invocation
{
	for (NSView * view in [originView subviews]) {
		[self traverseSubviews:view withInvocation:invocation];
	}
	[invocation setArgument:&originView atIndex:2];
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
		// コンテンツビューに含まれる全てのコントロールに対して validateEditingを実行する
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

#pragma mark -
#pragma mark Delegate Methods

- (void)extractor:(TumblrReblogExtractor *)extractor didFinishExtract:(NSDictionary *)contents
{
	extractedContents_ = [NSMutableDictionary dictionaryWithDictionary:contents];
	[extractedContents_ setObject:extractor.postID forKey:@"pid"];
	[extractedContents_ setObject:extractor.reblogKey forKey:@"rk"];
	[extractedContents_ retain];

	PostType const postType = [[contents objectForKey:@"type"] postType];

	NSMutableDictionary * newContents = [NSMutableDictionary dictionary];
	NSString * message = nil;
	NSString * caption = nil;

	switch (postType) {
	case LinkPostType:
		[newContents setObject:[contents objectForKey:@"post[one]"] forKey:@"URL"];
		[newContents setObject:[contents objectForKey:@"post[two]"] forKey:@"title"];
		caption = [contents objectForKey:@"post[three]"];
		caption = [self stringWithAppendingParagraph:caption];
		[newContents setObject:caption forKey:@"description"];
		break;
	case QuotePostType:
		[newContents setObject:[contents objectForKey:@"post[one]"] forKey:@"quote"];
		caption = [contents objectForKey:@"post[two]"];
		caption = [self stringWithAppendingParagraph:caption];
		[newContents setObject:caption forKey:@"source"];
		break;
	case PhotoPostType:
		caption = [contents objectForKey:@"post[two]"];
		caption = [self stringWithAppendingParagraph:caption];
		[newContents setObject:caption forKey:@"caption"];
		[newContents setObject:[contents objectForKey:@"post[three]"] forKey:@"throughURL"];
		self.image = [self imageWithURL:[contents objectForKey:@"img-src"]];
		break;
	case VideoPostType:	
		[newContents setObject:[contents objectForKey:@"post[one]"] forKey:@"embed"];
		caption = [contents objectForKey:@"post[two]"];
		caption = [self stringWithAppendingParagraph:caption];
		[newContents setObject:caption forKey:@"caption"];
		break;
	default:
		message = @"unimplemented yet";
		D0(message);
		[GrowlSupport notifyWithTitle:[NSString stringWithPostType:postType] description:message];
		break;
	}

	[self setContentsViewWithPostType:postType contents:newContents display:YES];
}

- (void)extractor:(TumblrReblogExtractor *)extractor didFailExtractWithError:(NSError *)error
{
#pragma unused (extractor, error)

	D0([error description]);
}

- (void)extractor:(TumblrReblogExtractor *)extractor didFailExtractWithException:(NSException *)exception
{
#pragma unused (extractor, exception)

	D0([exception description]);
}

- (void)resizeWindowOnSpotWithRect:(NSRect)aRect display:(BOOL)display animate:(BOOL)animate
{
	NSRect const frame = [postEditPanel_ frame];
    NSRect r = NSMakeRect(frame.origin.x - (aRect.size.width - frame.size.width), frame.origin.y - (aRect.size.height - frame.size.height), aRect.size.width, aRect.size.height);
    [postEditPanel_ setFrame:r display:display animate:animate];
}

- (NSImage *)imageWithURL:(NSString *)imageURL
{
	if (imageURL == nil) return nil;

	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURL]];
	NSURLResponse * response = nil;
	NSError * error = nil;
	NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	D0([response description]);
	D0([error description]);

	if (error != nil || data == nil) return nil;

	return [[[NSImage alloc] initWithData:data] autorelease];
}

- (NSString *)stringWithAppendingParagraph:(NSString *)s
{
	if (s == nil) s = @"";

	if (postType_ == ReblogPostType) {
		return [NSString stringWithFormat:@"%@<p></p>", s];
	}
	return s;
}
@end
