#import <Cocoa/Cocoa.h>

@interface PhotoViewController : NSViewController
{
	IBOutlet NSImageView * imageView_;
	IBOutlet NSTextField * throughURLField_;
	IBOutlet NSTextView * captionField_;
}

/// caption text
@property (nonatomic, readonly) NSString * caption;

/// click-through URL
@property (nonatomic, readonly) NSString * throughURL;

/**
 * set Post contents
 *	@param[in] imageURL	URL of image
 *	@param[in] image	NSImage object
 *	@param[in] caption	caption
 *	@param[in] throughURL	click-through URL
 */
- (void)setContentsWithImageURL:(NSString *)imageURL image:(NSImage *)image caption:(NSString *)caption throughURL:(NSString *)throughURL;
@end
