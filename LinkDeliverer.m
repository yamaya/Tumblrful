/**
 * @file LinkDeliverer.m
 * @brief LinkDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "LinkDeliverer.h"
#import "DelivererRules.h"
#import "Anchor.h"
#import "Log.h"

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

static NSString* TYPE = @"Link";

@implementation LinkDeliverer
/**
 * Deliverer のファクトリ
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	LinkDeliverer* deliverer = nil;

	deliverer = [[LinkDeliverer alloc] initWithDocument:document element:clickedElement];
	if (deliverer != nil) {
		[deliverer retain];
	}
	else {
		Log(@"Could not alloc+init %@Deliverer.", TYPE);
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
#pragma unused (sender)
	@try {
		/* <a> を選択している場合は WebElementLinkURL にURLが入っている */
		NSString* url = (NSString*)[clickedElement_ objectForKey:WebElementLinkURLKey];
		NSString* name = (NSString*)[clickedElement_ objectForKey:WebElementLinkLabelKey];

		if (url == nil) url = [context_ documentURL];
		if (name == nil) name = [context_ documentTitle];

		[super postLink:url title:name];
	}
	@catch (NSException* e) {
		[self failedWithException:e];
	}
}
@end
