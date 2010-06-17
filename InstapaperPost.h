/**
 * @file InstapaperPost.h
 */
#import "Post.h"

@interface InstapaperPost : NSObject<Post>
{
	NSMutableData * data_;
	NSObject<PostCallback> * callback_;
}

+ (BOOL)enabled;

@end
