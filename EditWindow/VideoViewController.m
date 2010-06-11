/**
 * @file VideoViewController.m
 * @brief VideoViewController class implementation
 */
#import "VideoViewController.h"
#import "NSString+Tumblrful.h"
#import "PostEditConstants.h"
#import "DebugLog.h"

@implementation VideoViewController

@dynamic embed;
@dynamic caption;

- (void)awakeFromNib
{
	NSFont * font = [NSFont systemFontOfSize:POSTEDIT_TEXT_FONT_SIZE];
	[[captionTextView_ textStorage] setFont:font];
	[captionTextView_ setFont:font];
	[[embedTextView_ textStorage] setFont:font];
	[embedTextView_ setFont:font];
}

- (void)setContentsWithEmbed:(NSString *)embed caption:(NSString *)caption
{
	[embedTextView_ setString:Stringnize(embed)];
	[captionTextView_ setString:Stringnize(caption)];
}

- (NSString *)embed
{
	return [embedTextView_ string];
}

- (NSString *)caption
{
	return [captionTextView_ string];
}
@end
