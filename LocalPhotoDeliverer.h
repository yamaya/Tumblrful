/** @file LocalPhotoDeliverer.h */
#import "PhotoDeliverer.h"

@interface LocalPhotoDeliverer : PhotoDeliverer
{
	NSImage * image_;
}

/**
 * contents for Photo post.
 *	@return contents dictionary object has following keys
 *	- @"data" - data of image
 *	- @"caption" - caption
 *	- @"throughURL" - click-through URL
 */
- (NSDictionary *)photoContents;
@end
