/**
 * @file VideoViewController.h
 * @brief VideoViewController class declaration
 */
#import <Cocoa/Cocoa.h>

@interface VideoViewController : NSViewController
{
	IBOutlet NSTextView * embedTextView_;
	IBOutlet NSTextView * captionTextView_;
}

@property (nonatomic, readonly) NSString * embed;

@property (nonatomic, readonly) NSString * caption;

- (void)setContentsWithEmbed:(NSString *)embed caption:(NSString *)caption;
@end
