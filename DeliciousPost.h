/**
 * @file DeliciousPost.h
 * @brief DeliciousPost class declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Post.h"

@interface DeliciousPost : NSObject<Post>
{
	NSMutableData * data_;
	NSObject<PostCallback> * callback_;
}

+ (BOOL)enabled;

@end
