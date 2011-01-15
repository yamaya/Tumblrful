#import <WebKit/WebKit.h>
#import "WebHTMLView.h"

@interface WebHTMLView (Tumblrful)
+ (void)setMouseDownInvocation:(NSInvocation *)invocation;
+ (void)clearMouseDownInvocation;
@end
