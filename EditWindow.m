//FIXME delete me
#import "EditWindow.h"

@implementation EditWindow

+ (void)show
{
	if (sheetWindow == nil) {
		[NSBundle loadNibNamed:@"EditSheet" owner:self];
	}

	NSWindow * parentWindow = nil;
	[NSApp beginSheet:sheetWindow
	   modalForWindow:parentWindow
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

@end
