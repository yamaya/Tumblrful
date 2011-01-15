/** @file AggregatorDeliverer.h */
#import "ReblogDeliverer.h"

/**
 * Tumblr post in the Aggregator to reblog
 */
@interface AggregatorReblogDeliverer : ReblogDeliverer
{
	NSMutableData * data_;
}

/**
 * return ".tumblr.com"
 *	@return site postfix
 */
+ (NSString *)sitePostfix;

/**
 * return "htpp://data.tumblr.com/"
 * @return return data site URL
 */
+ (NSString *)dataSiteURL;

@end
