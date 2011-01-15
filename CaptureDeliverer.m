/** @file CaptureDeliverer.m */
#import "CaptureDeliverer.h"
#import "DebugLog.h"

static NSString * TYPE = @"Capture";

@implementation CaptureDeliverer

+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	return [[CaptureDeliverer alloc] initWithDocument:document target:clickedElement];
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
	D_METHOD;

	SEL selector = @selector(setCaptureEnabledByTumblrful:);
	@try {
		if ([self.webView respondsToSelector:selector]) {
			[self.webView performSelector:selector withObject:[NSNumber numberWithBool:YES]];
		}
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithException:e];
	}
}
@end
