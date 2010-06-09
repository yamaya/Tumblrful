/**
 * @file PostEditWindow.h
 * @brief PostEditWindow class declaration
 * @author Masayuki YAMAYA
 * @date 2010-06-01
 */
#import <Cocoa/Cocoa.h>
#import "PostType.h"

@class Anchor;
@class QuoteViewController;
@class LinkViewController;
@class PhotoViewController;

@interface PostEditWindow : NSObject
{
	IBOutlet NSPanel * postEditPanel_;
	IBOutlet NSTextField * postTypeLabel_;
	IBOutlet NSView * genericView_;
	IBOutlet NSTextField * tagsField_;
	IBOutlet NSButton * privateButton_;
	IBOutlet NSButton * queueingButton_;

	IBOutlet QuoteViewController * quoteViewController_;
	IBOutlet LinkViewController * linkViewController_;
	IBOutlet PhotoViewController * photoViewController_;

	PostType postType_;
	NSInvocation * invocation_;
}

- (id)initWithPostType:(PostType)postType withInvocation:(NSInvocation *)invocation;

- (IBAction)pressOKButton:(id)sender;

- (IBAction)pressCancelButton:(id)sender;

- (void)setContentsOptionWithPrivated:(BOOL)privated queued:(BOOL)queued;

- (void)openSheet:(NSWindow * )window;

@end
