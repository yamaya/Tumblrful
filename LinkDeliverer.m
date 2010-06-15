/**
 * @file LinkDeliverer.m
 * @brief LinkDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "LinkDeliverer.h"
#import "Anchor.h"
#import "DebugLog.h"

static NSString* TYPE = @"Link";

@implementation LinkDeliverer
+ (id<Deliverer>)create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	LinkDeliverer * deliverer = [[LinkDeliverer alloc] initWithDocument:document target:clickedElement];
	if (deliverer == nil) {
		D(@"Could not alloc+init %@Deliverer.", TYPE);
	}
	return deliverer;
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
		clickedElement_ = [targetElement retain];
	}
	return self;
}

- (void)dealloc
{
	[clickedElement_ release], clickedElement_ = nil;

	[super dealloc];
}

- (NSString *)postType
{
	return [TYPE lowercaseString];
}

- (NSString*) titleForMenuItem
{
	return TYPE;
}

- (void)action:(id)sender
{
#pragma unused (sender)
	@try {
		// <a> を選択している場合は WebElementLinkURL にURLが入っている
		NSString * url = (NSString *)[clickedElement_ objectForKey:WebElementLinkURLKey];
		NSString * name = (NSString *)[clickedElement_ objectForKey:WebElementLinkLabelKey];

		if (url == nil) url = context_.documentURL;
		if (name == nil) name = context_.documentTitle;

		[super postLink:url title:name];
	}
	@catch (NSException * e) {
		[self failedWithException:e];
	}
}
@end
