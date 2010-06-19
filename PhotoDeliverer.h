/**
 * @file PhotoDeliverer.h
 * @brief PhotoDeliverer class declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererBase.h"

@interface PhotoDeliverer : DelivererBase
{
	NSDictionary * clickedElement_;
	BOOL covered_;
}

/**
 * contents for Photo post.
 *	@return contents dictionary object has following keys
 *	- @"source" - URL of image
 *	- @"caption" - caption
 *	- @"throughURL" - click-through URL
 */
- (NSDictionary *)photoContents;

/**
 * selected string with <blockquote> tag
 *	@return string
 */
- (NSString *)selectedStringWithBlockquote;
@end
