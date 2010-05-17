/**
 * @file Post.h
 * @brief Post protocol declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "PostCallback.h"

@protocol Post
+ (NSString*) username;
+ (NSString*) password;
- (id) initWithCallback:(NSObject<PostCallback>*)callback;
- (NSMutableDictionary*) createMinimumRequestParams;
- (void) postWith:(NSDictionary*)params;
- (BOOL) private;
@end
