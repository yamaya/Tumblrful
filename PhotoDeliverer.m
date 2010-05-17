/**
 * @file:   PhotoDeliverer.m
 * @brief:	PhotoDeliverer implementation
 * @author:	Masayuki YAMAYA
 * @date:   2008-03-03
 */
#import "PhotoDeliverer.h"
#import "DelivererRules.h"
#import "Log.h"
#import <WebKit/WebView.h>

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

static NSString* TYPE = @"Photo";

#pragma mark -
@interface PhotoDeliverer (Private)
- (NSString*) getSelectionText:(NSDictionary*)clickedElement;
@end

#pragma mark -
@implementation PhotoDeliverer (Private)
- (NSString*) getSelectionText:(NSDictionary*)clickedElement
{
	NSString* selection = nil;
	WebFrame* frame = [clickedElement objectForKey:WebElementFrameKey];
	if (frame != nil) {
		NSView<WebDocumentView>* view = [[frame frameView] documentView];
		if (view != nil) {
			if ([view respondsToSelector:@selector(selectedString)]) {
				selection = [view performSelector:@selector(selectedString)];
			}
		}
	}

	V(@"selection=\"%@\"", selection);
	return selection;
}
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
- (void) action:(id)sender
{
	@try {
		NSString* caption = [context_ anchorTagToDocument];
		NSString* selection = [self getSelectionText:clickedElement_];
		if (selection != nil && [selection length] > 0) {
			caption = [caption stringByAppendingFormat:@"<blockquote>%@</blockquote>", selection];
		}

		[super postPhoto:(NSString*)[clickedElement_ objectForKey:WebElementImageURLKey]
						 caption:caption
						 through:[context_ documentURL]];
	}
	@catch (NSException* e) {
		[self failedWithException:e];
	}
}
@end
