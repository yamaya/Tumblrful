/**
 * @file LDRReblogDeliverer.h
 * @brief LDRReblogDeliverer class declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "ReblogDeliverer.h"

/**
 * Tumblr post in the Livedoor Reader to reblog
 */
@interface LDRReblogDeliverer : ReblogDeliverer

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
