/**
 * @file TumblrPost.h
 * @brief TumblrPost class declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Post.h"
#import "PostCallback.h"
#import "TumblrReblogExtractor.h"

/**
 * TumblrPost class
 */
@interface TumblrPost : NSObject<Post, TumblrReblogExtractorDelegate>
{
	BOOL private_;
	BOOL queuing_;
	BOOL extractEnabled_;
	NSMutableData* responseData_;
	NSObject<PostCallback>* callback_; // for Deliverer
	NSDictionary * reblogParams_;	// for Reblog
}

/// private post or not
@property (nonatomic, assign) BOOL privated;

/// queuing post enabled or not
@property (nonatomic, assign) BOOL queuingEnabled;

/// Extract reblog post or not
@property (nonatomic, assign) BOOL extractEnabled;

+ (NSString *)username;

+ (NSString *)password;

- (id)initWithCallback:(NSObject<PostCallback> *)callback;

- (NSMutableDictionary *)createMinimumRequestParams;

- (NSURLRequest *)createRequest:(NSString *)url params:(NSDictionary *)params;

- (NSURLRequest *)createRequest:(NSString *)url params:(NSDictionary *)params withData:(NSData *)data;

/**
 * post to Tumblr.
 *	@param[in] params	request parameteres
 */
- (void)postWith:(NSDictionary *)params;
@end
