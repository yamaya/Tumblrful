/**
 * @file:   PhotoDeliverer.m
 * @brief:	PhotoDeliverer implementation
 * @author:	Masayuki YAMAYA
 * @date:   2008-03-03
 */
#import "PhotoDeliverer.h"
#import "DelivererRules.h"
#import "DebugLog.h"
#import <WebKit/WebView.h>

static NSString * TYPE = @"Photo";

#pragma mark -
@interface PhotoDeliverer ()
- (NSString *)selectionText:(NSDictionary *)clickedElement;
@end

#pragma mark -
@implementation PhotoDeliverer
/**
 * Deliverer のファクトリ
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	PhotoDeliverer* deliverer = nil;

	id imageURL = [clickedElement objectForKey:WebElementImageURLKey];
	if (imageURL != nil) {
		deliverer = [[PhotoDeliverer alloc] initWithDocument:document element:clickedElement];
		if (deliverer != nil) {
			[deliverer retain]; //need?
		}
		else {
			Log(@"Could not alloc+init %@Deliverer.", TYPE);
		}
	}
	return deliverer;
}

/**
 * オブジェクトを初期化する
 */
- (id) initWithDocument:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	if ((self = [super initWithDocument:document target:clickedElement]) != nil) {
		clickedElement_ = [clickedElement retain];
	}
	return self;
}

/**
 * オブジェクトの解放
 */
- (void) dealloc
{
	[clickedElement_ release];
	[super dealloc];
}

/**
 * Tumblr APIが規定するポストのタイプ
 */
- (NSString*) postType
{
	return [TYPE lowercaseString];
}

/**
 * MenuItemのタイトルを返す
 */
- (NSString*) titleForMenuItem
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
		NSString * imageURL = (NSString *)[clickedElement_ objectForKey:WebElementImageURLKey];
		NSString * caption = [context_ anchorTagToDocument];

		// セレクションはキャプションとして設定する
		NSString * selection = [self selectionText:clickedElement_];
		if (selection != nil && [selection length] > 0) {
			caption = [caption stringByAppendingFormat:@"<blockquote>%@</blockquote>", selection];
		}

		[super postPhoto:imageURL caption:caption through:[context_ documentURL]];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithException:e];
	}
}

- (NSString *)selectionText:(NSDictionary *)clickedElement
{
	SEL selector = @selector(selectedString);

	NSString * text = nil;
	WebFrame * frame = [clickedElement objectForKey:WebElementFrameKey];
	if (frame != nil) {
		NSView<WebDocumentView> * view = [[frame frameView] documentView];
		if (view != nil) {
			if ([view respondsToSelector:selector]) {
				text = [view performSelector:selector];
			}
		}
	}

	D0(text);
	return text;
}
@end
