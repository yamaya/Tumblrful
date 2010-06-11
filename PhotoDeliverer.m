/**
 * @file:   PhotoDeliverer.m
 * @brief:	PhotoDeliverer implementation
 * @author:	Masayuki YAMAYA
 * @date:   2008-03-03
 */
#import "PhotoDeliverer.h"
#import "DebugLog.h"
#import <WebKit/WebView.h>

static NSString * TYPE = @"Photo";

#pragma mark -
@interface PhotoDeliverer ()
- (NSString *)selectedString;
@end

#pragma mark -
@implementation PhotoDeliverer
+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	PhotoDeliverer * deliverer = nil;

	id imageURL = [clickedElement objectForKey:WebElementImageURLKey];
	if (imageURL != nil) {
		deliverer = [[PhotoDeliverer alloc] initWithDocument:document element:clickedElement];
		if (deliverer != nil) {
			[deliverer retain]; //need? FIXME ここでretainするんじゃなくて呼び出し側でやるようにする
		}
		else {
			D(@"Could not alloc+init %@Deliverer.", TYPE);
		}
	}
	return deliverer;
}

- (id)initWithDocument:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	if ((self = [super initWithDocument:document target:clickedElement]) != nil) {
		clickedElement_ = [clickedElement retain];
	}
	return self;
}

- (void)dealloc
{
	[clickedElement_ release];

	[super dealloc];
}

- (NSString *)postType
{
	return [TYPE lowercaseString];
}

- (NSString *)titleForMenuItem
{
	return TYPE;
}

/**
 * メニューのアクション
 */
- (void)action:(id)sender
{
#pragma unused (sender)
	@try {
		// コンテンツを得る
		NSDictionary * contents = [self photoContents];

		// 画像
		NSImage * image = [clickedElement_ objectForKey:WebElementImageKey];

		// ポストする
		[super postPhoto:[contents objectForKey:@"source"]
				 caption:[contents objectForKey:@"caption"]
				 through:[contents objectForKey:@"throughURL"]
				   image:image];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithException:e];
	}
}

- (NSDictionary *)photoContents
{
	// 画像のソースURL
	NSString * source = [[clickedElement_ objectForKey:WebElementImageURLKey] absoluteString];

	// キャプション - セレクションがあればそれを blockquoteで囲って追加する
	NSString * caption = [context_ anchorTagToDocument];
	NSString * selection = [self selectedStringWithBlockquote];
	if (selection != nil && [selection length] > 0) {
		caption = [caption stringByAppendingFormat:@"\r%@", selection];
	}

	return [NSDictionary dictionaryWithObjectsAndKeys:source, @"source", caption, @"caption", [context_ documentURL], @"throughURL", nil];
}

- (NSString *)selectedStringWithBlockquote
{
	NSString * s = [self selectedString];
	if (s != nil && [s length] > 0) {
		s = [s stringByAppendingFormat:@"<blockquote>%@</blockquote>", s];
	}
	return s;
}

- (NSString *)selectedString
{
	NSString * selection = nil;

	if (clickedElement_ != nil) {
		SEL selector = @selector(selectedString);
		WebFrame * frame = [clickedElement_ objectForKey:WebElementFrameKey];
		if (frame != nil) {
			NSView<WebDocumentView> * view = [[frame frameView] documentView];
			if (view != nil && [view respondsToSelector:selector]) {
				selection = [view performSelector:selector];
			}
		}
	}

	D0(selection);
	return selection;
}
@end
