/**
 * @file PostEditWindow.h
 * @brief PostEditWindow class declaration
 * @author Masayuki YAMAYA
 * @date 2010-06-01
 */
#import <Cocoa/Cocoa.h>
#import "PostType.h"
#import "TumblrReblogExtractor.h"

@class QuoteViewController;
@class LinkViewController;
@class PhotoViewController;
@class VideoViewController;
@class TumblrReblogExtractor;

// TODO 改名すべき PostEditWindowController
/**
 * Post editting window controller class
 */
@interface PostEditWindow : NSObject<TumblrReblogExtractorDelegate>
{
	IBOutlet NSPanel * postEditPanel_;
	IBOutlet NSView * genericView_;
	IBOutlet NSTextField * tagsField_;
	IBOutlet NSButton * privateButton_;
	IBOutlet NSButton * queueingButton_;
	IBOutlet NSButton * twitterButton_;

	IBOutlet QuoteViewController * quoteViewController_;
	IBOutlet LinkViewController * linkViewController_;
	IBOutlet PhotoViewController * photoViewController_;
	IBOutlet VideoViewController * videoViewController_;

	PostType postType_;
	NSInvocation * invocation_;
	NSImage * image_;
	NSMutableDictionary * extractedContents_;
}

/// 画像(オプショナル)
@property (nonatomic, retain) NSImage * image;

- (IBAction)pressOKButton:(id)sender;

- (IBAction)pressCancelButton:(id)sender;

/**
 * Initialize object
 *	@param[in] postType type of post
 *	@param[in] invocation invocation when OK button of sheet
 *	@return initialized object
 */
- (id)initWithPostType:(PostType)postType withInvocation:(NSInvocation *)invocation;

/**
 * set contents options
 *	@param[in] privated	private post is YES
 *	@param[in] queued queuing post is YES
 */
- (void)setContentsOptionWithPrivated:(BOOL)privated queued:(BOOL)queued;

/**
 * open Post editting window as sheet
 *	@param[in] window	parent window
 */
- (void)openSheet:(NSWindow *)window;

@end
