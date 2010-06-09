/**
 * @file VideoViewController.h
 * @brief VideoViewController class declaration
 */
#import <Cocoa/Cocoa.h>

@class WebView;

@interface VideoViewController : NSViewController
{
	IBOutlet WebView * webView_;
	IBOutlet NSTextView * embedTextView_;
	IBOutlet NSTextView * captionField_;
}

@property (nonatomic, readonly) NSString * caption;

@property (nonatomic, readonly) NSString * embed;

- (void)setContentsWithEmbedTag:(NSString *)embed caption:(NSString *)caption;
@end
