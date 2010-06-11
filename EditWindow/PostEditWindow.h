/**
 * @file PostEditWindow.h
 * @brief PostEditWindow class declaration
 * @author Masayuki YAMAYA
 * @date 2010-06-01
 */
#import <Cocoa/Cocoa.h>
#import "PostType.h"

@class QuoteViewController;
@class LinkViewController;
@class PhotoViewController;
@class VideoViewController;

@interface PostEditWindow : NSObject
{
	IBOutlet NSPanel * postEditPanel_;
	IBOutlet NSView * genericView_;
	IBOutlet NSTextField * tagsField_;
	IBOutlet NSButton * privateButton_;
	IBOutlet NSButton * queueingButton_;

	IBOutlet QuoteViewController * quoteViewController_;
	IBOutlet LinkViewController * linkViewController_;
	IBOutlet PhotoViewController * photoViewController_;
	IBOutlet VideoViewController * videoViewController_;

	PostType postType_;
	NSInvocation * invocation_;
	NSImage * image_;
}

/// 画像(オプショナル)
@property (nonatomic, retain) NSImage * image;

- (IBAction)pressOKButton:(id)sender;

- (IBAction)pressCancelButton:(id)sender;

/**
 * Initialize object
 *	@param[in] postType type of post
 *	@param[in] invocation invocation when OK button of sheet
 */
- (id)initWithPostType:(PostType)postType withInvocation:(NSInvocation *)invocation;

- (void)setContentsOptionWithPrivated:(BOOL)privated queued:(BOOL)queued;

- (void)openSheet:(NSWindow *)window;

@end
