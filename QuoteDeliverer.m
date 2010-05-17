/**
 * @file QuoteDeliverer.m
 * @brief QuoteDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "QuoteDeliverer.h"
#import "DelivererRules.h"
#import "GrowlSupport.h"
#import "Log.h"

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

static NSString* TYPE = @"Quote";

#pragma mark -
@interface QuoteDeliverer (Private)
- (void) notifyByEmptyText;
@end

#pragma mark -
@implementation QuoteDeliverer (Private)
/**
 * エラー処理
 */
- (void) notifyByEmptyText
{
	[GrowlSupport notify:TYPE
					 description:[DelivererRules errorMessageWith:selectionText_]];
}
@end

#pragma mark -
@implementation QuoteDeliverer
/**
 * factory for QuoteDeliverer
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	QuoteDeliverer* deliverer = nil;
	NSString* selection = nil;

	id selected = [clickedElement objectForKey:WebElementIsSelectedKey];
	V(@"selected: %@", SafetyDescription(selected));
	if (selected != nil && CFBooleanGetValue((CFBooleanRef)selected)) {
		WebFrame* frame = [clickedElement objectForKey:WebElementFrameKey];
		NSView<WebDocumentView>* view = [[frame frameView] documentView];
		if ([view respondsToSelector:@selector(selectedString)]) {
			selection = [view performSelector:@selector(selectedString)];
		}
		V(@"selection=\"%@\"", selection);
	}

	if (selection != nil && [selection length] > 0) {
		deliverer = [[QuoteDeliverer alloc] initWithDocument:document target:clickedElement selection:selection];
		if (deliverer == nil) {
			Log(@"Could not alloc+init QuoteDeliverer");
		}
	}
	return deliverer;
}

/**
 * オブジェクトを初期化する
 */
- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)targetElement selection:(NSString*)selection
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
		selectionText_ = [selection retain];
	}
	return self;
}

/**
 * オブジェクトの解放
 */
- (void) dealloc
{
	[selectionText_ release];
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
	V(@"action) QuoteDeliverer.retain=%x", [self retainCount]);

	NSString* text = selectionText_;
	if (text == nil) {
		[self notifyByEmptyText];
		return;
	}

	/* 前後の空白を取り除く */
	text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	text = [text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\xE3\x80\x80"]];

	if ([text length] < 1) {
		[self notifyByEmptyText];
		return;
	}

	@try {
		[super postQuote:text];
	}
	@catch (NSException* e) {
		[self failedWithException:e];
	}
}
@end
