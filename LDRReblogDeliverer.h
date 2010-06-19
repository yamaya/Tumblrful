/**
 * @file LDRReblogDeliverer.h
 * @brief LDRReblogDeliverer class declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "ReblogDeliverer.h"

@class ReblogKeyDelegate;
@class WebView;

/**
 * Tumblr post in the Livedoor Reader to reblog
 */
@interface LDRReblogDeliverer : ReblogDeliverer
{
	ReblogKeyDelegate * delegate_;
	WebView * webView_;
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
