#import "TumblrfulWebHTMLView.h"
#import "DebugLog.h"

NSInvocation * invocation_ = nil;

@implementation WebHTMLView (Tumblrful)

+ (void)setMouseDownInvocation:(NSInvocation *)invocation
{
	D_METHOD;

	[self clearMouseDownInvocation];
	invocation_ = [invocation retain];
}

+ (void)clearMouseDownInvocation
{
	[invocation_ release], invocation_ = nil;
}

- (void)mouseDown_SwizzledByTumblrful:(NSEvent *)event
{
	if (invocation_ != nil) {
		[invocation_ invoke];
		[self.class clearMouseDownInvocation];
	}
	else {
		[self mouseDown_SwizzledByTumblrful:event];
	}
}
@end
