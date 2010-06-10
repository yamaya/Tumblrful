/**
 * @file TumblrPost.h
 * @brief TumblrPost declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Post.h"

@interface TumblrPost : NSObject<Post>
{
	BOOL private_;	/**< private post */
	BOOL queuing_;	/**< queuing post */
	NSMutableData* responseData_;	/**< for NSURLConnection */
	NSObject<PostCallback>* callback_; /**< for Deliverer */
}

+ (NSString*) username;

+ (NSString*) password;

- (id) initWithCallback:(NSObject<PostCallback>*)callback;

- (NSMutableDictionary*) createMinimumRequestParams;

- (NSURLRequest *)createRequest:(NSString *)url params:(NSDictionary *)params;

#ifdef SUPPORT_MULTIPART_PORT
- (NSURLRequest*) createRequestForMultipart:(NSDictionary*)params withData:(NSData*)data;
#endif

- (void) postWith:(NSDictionary*)params;
- (void) postTo:(NSString*)url params:(NSDictionary*)params;
- (NSObject*) reblog:(NSString*)postID key:(NSString*)reblogKey;

- (void) setPrivate:(BOOL)private;
- (BOOL) private;

- (void) setQueueing:(BOOL)queuing;
- (BOOL) queuing;

@end
