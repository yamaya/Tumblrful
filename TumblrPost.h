/**
 * @file TumblrPost.h
 * @brief TumblrPost declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Post.h"

/**
 * TumblrPost class
 */
@interface TumblrPost : NSObject<Post>
{
	BOOL private_;
	BOOL queuing_;
	NSMutableData* responseData_;	/**< for NSURLConnection */
	NSObject<PostCallback>* callback_; /**< for Deliverer */
}

/// private post
@property (nonatomic, assign) BOOL privated;

/// queuing post enabled
@property (nonatomic, assign) BOOL queuingEnabled;

+ (NSString *)username;

+ (NSString *)password;

- (id)initWithCallback:(NSObject<PostCallback> *)callback;

- (NSMutableDictionary *)createMinimumRequestParams;

- (NSURLRequest *)createRequest:(NSString *)url params:(NSDictionary *)params;

#ifdef SUPPORT_MULTIPART_PORT
- (NSURLRequest *)createRequestForMultipart:(NSDictionary *)params withData:(NSData *)data;
#endif

- (void)postWith:(NSDictionary *)params;

- (void)postTo:(NSString *)url params:(NSDictionary *)params;

/**
 * reblog
 *	@param postID ポストのID(整数値)
 */
- (NSObject *)reblog:(NSString *)postID key:(NSString *)reblogKey;

@end
