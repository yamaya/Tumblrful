/**
 * @file YammerPost.h
 */
#import "Post.h"
#import <WebKit/WebKit.h>

@interface YammerPost : NSObject<Post>
{
	NSObject<PostCallback> * callback_;
	WebView * webView_;
	BOOL releasable_;
}

+ (BOOL)enabled;

@end
