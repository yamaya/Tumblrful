/**
 * @file DeliciousPost.h
 * @brief DeliciousPost declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Post.h"

@interface DeliciousPost : NSObject<Post>
{
	NSMutableData * responseData_;	/* for NSURLConnection */
	NSObject<PostCallback> * callback_;
	BOOL private_;
}

+ (BOOL) isEnabled;

@end
