/**
 * @file PhotoDeliverer.h
 * @brief PhotoDeliverer declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererBase.h"

@interface PhotoDeliverer : DelivererBase
{
	NSDictionary * clickedElement_;
}

//TODO これ DeliverBaseに持ち上げられないの？
//できる clickedElement_を DeliverBaseに持たせればいい
- (id)initWithDocument:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement;

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
