/**
 * @file DeliciousPost.h
 * @brief DeliciousPost declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Post.h"

@interface DeliciousPost : NSObject<Post>
{
	NSMutableData* responseData_;	/* for NSURLConnection */
	NSObject<PostCallback>* callback_;
	BOOL private_;
}
+ (NSString*) username;
+ (NSString*) password;
+ (BOOL) isEnabled;
- (id) initWithCallback:(NSObject<PostCallback>*)callback;
- (void) dealloc;
- (NSMutableDictionary*) createMinimumRequestParams;
- (void) postWith:(NSDictionary*)params;
- (BOOL) private;
@end
