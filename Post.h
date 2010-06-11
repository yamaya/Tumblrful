/**
 * @file Post.h
 * @brief Post protocol declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "PostCallback.h"

@protocol Post

/**
 * User-name for the service
 */
+ (NSString *)username;

/**
 * Password for the service
 */
+ (NSString *)password;

/**
 * Initialize object
 *	@param[in] callback	PostCallback object
 *	@return initialized object
 */
- (id)initWithCallback:(NSObject<PostCallback> *)callback;

/**
 * Create minimum request parameters
 *	@return parameters
 */
- (NSMutableDictionary *)createMinimumRequestParams;

/**
 * Post parameters to the service
 *	@param[in] params	parameters
 */
- (void)postWith:(NSDictionary *)params;

/**
 * privated post
 *	@return privated is YES, otherwise NO
 */
- (BOOL)privated;
@end
