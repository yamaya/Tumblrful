#import <Cocoa/Cocoa.h>

//FIXME delete me
@interface EditWindow : NSObject {
	IBOutlet NSWindow * sheetWindow;
	IBOutlet NSView * bodyView;
	IBOutlet NSTextView * captionText;
	IBOutlet NSButton * privateCheckBox;
	IBOutlet NSButton * queueCheckBox;
}

- (IBAction)didOK:(id)sender;
- (IBAction)didCancel:(id)sender;

+ (void)show;
@end