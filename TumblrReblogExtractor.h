/**
 * @file TumblrReblogExtractor.h
 * @brief TumblrReblogExtractor class declaration
 * @author Masayuki YAMAYA
 * @date 2008-04-23
 */
#include <Foundation/Foundation.h>

@class TumblrReblogExtractor;

/**
 * TumblrReblogExtractorDelegate protocol declaration
 */
@protocol TumblrReblogExtractorDelegate <NSObject>
- (void)extractor:(TumblrReblogExtractor *)extracter didFinishExtract:(NSDictionary *)contents;
@end

/**
 * Extract the necessary information from the Tumblr reblog post.
 */
@interface TumblrReblogExtractor : NSObject
{
	NSObject<TumblrReblogExtractorDelegate> * delegate_;
	NSMutableData * responseData_;
	NSString * endpoint_;
}

/**
 * Initialize object
 *	@param[in] delegate TumblrReblogExtractorDelegate object
 */
- (id)initWithDelegate:(NSObject<TumblrReblogExtractorDelegate> *)delegate;

- (void)startWithPID:(NSString*)pid withReblogKey:(NSString*)rk;
@end
