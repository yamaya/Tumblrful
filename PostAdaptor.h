/**
 * @file PostAdaptor.h
 * @brief PostAdaptor declaration.
 *          Deliverer と Post をつなぐ
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Anchor.h"
#import "PostCallback.h"
#import <Foundation/Foundation.h>

/**
 * PostAdaptor abstract class
 */
@interface PostAdaptor : NSObject
{
	id<PostCallback> callback_;
	BOOL private_;
}

@property (nonatomic, assign) BOOL privated;

- (id) initWithCallback:(id<PostCallback>)callback;

- (id) initWithCallback:(id<PostCallback>)callback private:(BOOL)private;

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

- (id<PostCallback>) callback;
- (void) setCallback:(id<PostCallback>)callback;

- (BOOL) private;
- (void) setPrivate:(BOOL)private;

- (void) callbackWith:(NSString*)response;
- (void) callbackWithError:(NSError*)error;
- (void) callbackWithException:(NSException*)exception;

/**
 * post "Link" contents
 *	@param[in] anchor	URL anchor object
 *	@param[in] description	descrition
 */
- (void)postLink:(Anchor*)anchor description:(NSString*)description;

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

- (void)postVideo:(Anchor*)anchor embed:(NSString*)embed caption:(NSString*)caption;

- (NSObject*)postEntry:(NSDictionary*)params;
@end
