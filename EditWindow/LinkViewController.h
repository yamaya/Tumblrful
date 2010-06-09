#import <Cocoa/Cocoa.h>

@interface LinkViewController : NSViewController
{
	IBOutlet NSTextField * titleFiled_;
	IBOutlet NSTextField * urlField_;
	IBOutlet NSTextField * descriptionField_;
}

@property (nonatomic, readonly) NSString * title;

@property (nonatomic, readonly) NSString * URL;

@property (nonatomic, readonly) NSString * description;

- (void)setContentsWithTitle:(NSString *)title URL:(NSString *)url description:(NSString *)description;

@end
