/**
 * @file QuoteDeliverer.m
 * @brief QuoteDeliverer class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "QuoteDeliverer.h"
#import "DelivererRules.h"
#import "GrowlSupport.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

static NSString * TYPE = @"Quote";

#pragma mark -
@interface QuoteDeliverer ()
- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement selection:(NSString *)selection;
- (void)notifyByEmptyText;
@end

#pragma mark -
@implementation QuoteDeliverer

+ (id<Deliverer>)create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	QuoteDeliverer* deliverer = nil;
	NSString * selection = nil;

	id selected = [clickedElement objectForKey:WebElementIsSelectedKey];
	D(@"selected: %@", SafetyDescription(selected));

	if (selected != nil && CFBooleanGetValue((CFBooleanRef)selected)) {
		WebFrame * frame = [clickedElement objectForKey:WebElementFrameKey];
		NSView<WebDocumentView> * view = [[frame frameView] documentView];
		if ([view respondsToSelector:@selector(selectedString)]) {
			selection = [view performSelector:@selector(selectedString)];
		}
		D0(selection);
	}

	if (selection != nil && [selection length] != 0) {
		deliverer = [[QuoteDeliverer alloc] initWithDocument:document target:clickedElement selection:selection];
		if (deliverer == nil) {
			D0(@"Could not alloc+init QuoteDeliverer");
		}
	}
	return deliverer;
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement selection:(NSString *)selection
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
		selectionText_ = [selection retain];
	}
	return self;
}

- (void)dealloc
{
	[selectionText_ release], selectionText_ = nil;

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

- (void)action:(id)sender
{
#pragma unused (sender)
	@try {
		NSString * quote = selectionText_;
		if (quote == nil) {
			[self notifyByEmptyText];
			return;
		}

		// 前後の空白を取り除く
		quote = [quote stringByTrimmingWhitespace];
		if ([quote length] < 1) {
			[self notifyByEmptyText];
			return;
		}

		[super postQuote:quote source:nil];
	}
	@catch (NSException * e) {
		[self failedWithException:e];
	}
}

- (void)notifyByEmptyText
{
	[GrowlSupport notifyWithTitle:TYPE description:[DelivererRules errorMessageWith:selectionText_]];
}
@end
