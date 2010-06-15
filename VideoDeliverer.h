/**
 * @file VideoDeliverer.h
 * @brief VideoDeliverer class declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererBase.h"

/**
 * VideoDeliverer class declaration
 *	support Youtube only
 */
@interface VideoDeliverer : DelivererBase
{
	NSDictionary * clickedElement_;
}

/**
 * Make contents of Video
 *	@return dictionary following keys and values
 *	- @"source", Video URL or embed (string).
 *	- @"caption", caption text.
 */
- (NSDictionary *)videoContents;

/**
 * Name of this Deliverer class
 */
+ (NSString *)name;

@end
