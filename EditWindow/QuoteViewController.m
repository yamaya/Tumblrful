/**
 * @file QuoteViewController.m
 * @brief QuoteViewController class implementation
 * @author Masayuki YAMAYA
 * @date 2010-06-01
 */
#import "QuoteViewController.h"
#import "NSString+Tumblrful.h"
#import "PostEditConstants.h"
#import "DebugLog.h"

@implementation QuoteViewController

@dynamic quote;
@dynamic source;

- (void)awakeFromNib
{
	[super awakeFromNib];

	NSFont * font =[NSFont systemFontOfSize:POSTEDIT_TEXT_FONT_SIZE];
	[[quoteTextView_ textStorage] setFont:font];
	[[sourceTextView_ textStorage] setFont:font];
	[quoteTextView_ setFont:font];
	[sourceTextView_ setFont:font];
}

- (NSString *)source
{
	return [sourceTextView_ string];
}

- (NSString *)quote
{
	return [quoteTextView_ string];
}

- (void)setContentsWithText:(NSString *)quote source:(NSString *)source
{
	[quoteTextView_ setString:Stringnize(quote)];
	[sourceTextView_ setString:Stringnize(source)];
}
@end
