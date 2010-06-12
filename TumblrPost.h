/**
 * @file TumblrPost.h
 * @brief TumblrPost class declaration
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
	NSMutableData* responseData_;
	NSObject<PostCallback>* callback_; // for Deliverer
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

/**
 * post to Tumblr.
 *	@param[in] params	request parameteres
 */
- (void)postWith:(NSDictionary *)params;
#if 0
/**
 * post reblog contents to Tumblr.
 *	@param[in] postID	ID of Post
 *	@param[in] reblogKey	ReblogKey
 */
- (void)reblogPostWithPostID:(NSString *)postID reblogKey:(NSString *)reblogKey;
#endif
@end
