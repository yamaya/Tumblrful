/**
 * @file PostAdaptor.h
 * @brief PostAdaptor class declaration.
 *          Deliverer と Post をつなぐ
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Anchor.h"
#import "PostType.h"
#import "PostCallback.h"
#import <Foundation/Foundation.h>

/**
 * PostAdaptor abstract class
 */
@interface PostAdaptor : NSObject
{
	id<PostCallback> callback_;
	BOOL privated_;
	BOOL queuingEnabled_;
	BOOL extractEnabled_;
	NSDictionary * options_;
}

/// コールバックオブジェクト
@property (nonatomic, retain) id<PostCallback>	callback;

/// プライベートポストかどうか - サブクラスの実装による
@property (nonatomic, assign) BOOL privated;

/// キューイングポストかどうか - サブクラスの実装による
@property (nonatomic, assign) BOOL queuingEnabled;

/// Reblogポストにて展開するかどうか
@property (nonatomic, assign) BOOL extractEnabled;

/// Options for subclass - TODO 上の３つもサブクラスに入れるかなぁ
@property (nonatomic, retain) NSDictionary * options;

/**
 * Initialize object
 *	@param[in] callback PostCallback object
 *	@return Initialized object
 */
- (id)initWithCallback:(id<PostCallback>)callback;

/**
 * title for Contextual menu item
 *	@return title string
 */
+ (NSString *)titleForMenuItem;

/**
 * enable for Contextual menu item
 *	@return enable is YES
 */
+ (BOOL)enableForMenuItem;

/**
 * Callback when successed post.
 *	@param[in] response	response data
 */
- (void)callbackWith:(NSString *)response;

/**
 * Callback when failed post with NSError.
 *	@param[in] error NSError object
 */
- (void)callbackWithError:(NSError *)error;

/**
 * Callback when failed post with NSException.
 *	@param[in] error NSException object
 */
- (void)callbackWithException:(NSException *)exception;

/**
 * post "Link" contents
 *	@param[in] anchor	URL anchor object
 *	@param[in] description	descrition
 */
- (void)postLink:(Anchor *)anchor description:(NSString *)description;

/**
 * post "Quote" contents
 *	@param[in] quote	text
 *	@param[in] source	source of quote
 */
- (void)postQuote:(NSString *)quote source:(NSString *)source;

/**
 * post "Photo" contents
 *	@param[in] source	URL to image
 *	@param[in] caption	caption
 *	@param[in] throughURL	click-through URL
 */
- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL;

/**
 * post "Video" contents
 *	@param[in] embed	emebd tag or URL
 *	@param[in] caption	caption
 */
- (void)postVideo:(NSString *)embed caption:(NSString*)caption;

/**
 * "Reblog" post.
 *	@param[in] params	contents of Reblog. Determined by the target service.
 */
- (void)postEntry:(NSDictionary *)params;

/**
 * Make NSInvocation object for some post method by post type.
 *	The argument of NSInvocation object has not been set.
 *	@param[in] postType post type
 *	@return NSInvocation object
 */
- (NSInvocation *)invocationWithPostType:(PostType)postType;
@end
