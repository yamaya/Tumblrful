#import <Cocoa/Cocoa.h>

@class WebView;

@interface PhotoViewController : NSViewController
{
	IBOutlet WebView * webView_;
	IBOutlet NSTextField * throughURLField_;
	IBOutlet NSTextView * captionField_;
}

//@property (nonatomic, readonly) NSString * imageURL;

@property (nonatomic, readonly) NSString * caption;

@property (nonatomic, readonly) NSString * throughURL;

- (void)setContentsWithImageURL:(NSString *)imageURL caption:(NSString *)caption throughURL:(NSString *)throughURL;
@end
