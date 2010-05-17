/**
 * @file UmesuePost.h
 * @brief UmesuePost declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Post.h"

@interface UmesuePost : NSObject<Post>
{
	NSMutableData* responseData_;	/* for NSURLConnection */
	NSObject<PostCallback>* callback_;
}
+ (NSString*) username;
+ (NSString*) password;
+ (NSString*) endpoint;
+ (BOOL) isEnabled;
- (id) initWithCallback:(NSObject<PostCallback>*)callback;
- (void) dealloc;
- (NSMutableDictionary*) createMinimumRequestParams;
- (void) postWith:(NSDictionary*)params;
- (BOOL) private;
@end
