/**
 * @file TumblrReblogExtractor.h
 * @brief TumblrReblogExtractor class declaration
 * @author Masayuki YAMAYA
 * @date 2008-04-23
 */
#import <Foundation/Foundation.h>
#import "PostType.h"

@class TumblrReblogExtractor;

/**
 * TumblrReblogExtractorDelegate protocol declaration
 */
@protocol TumblrReblogExtractorDelegate <NSObject>
- (void)extractor:(TumblrReblogExtractor *)extractor didFinishExtract:(NSDictionary *)contents;
- (void)extractor:(TumblrReblogExtractor *)extractor didFailExtractWithError:(NSError *)error;
- (void)extractor:(TumblrReblogExtractor *)extractor didFailExtractWithException:(NSException *)exception;
@end

/**
 * Extract the necessary information from the Tumblr reblog post.
 */
@interface TumblrReblogExtractor : NSObject
{
	NSObject<TumblrReblogExtractorDelegate> * delegate_;
	NSMutableData * data_;
	NSString * postID_;
	NSString * reblogKey_;
	NSString * endpoint_;
}

/// URL for endpoint to post
@property (nonatomic, readonly) NSString * endpoint;

/// Post ID
@property (nonatomic, readonly) NSString * postID;

/// Reblog key
@property (nonatomic, readonly) NSString * reblogKey;

/**
 * Initialize object
 *	@param[in] delegate TumblrReblogExtractorDelegate object
 *	@return Initialized object
 */
- (id)initWithDelegate:(NSObject<TumblrReblogExtractorDelegate> *)delegate;

/**
 * Start Reblog form getting
 *	@param[in] postID	Post ID
 *	@param[in] reblogKey	Reblog key
 */
- (void)startWithPostID:(NSString *)postID withReblogKey:(NSString *)reblogKey;

/**
 * URL for endpoint to post
 *	@param[in] postID	Post ID
 *	@param[in] reblogKey	Reblog key
 *	@return URL for endpoint
 */
+ (NSString *)endpointWithPostID:(NSString *)postID withReblogKey:(NSString *)reblogKey;
@end
