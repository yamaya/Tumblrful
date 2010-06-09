/**
 * @file QuoteViewController.m
 * @brief QuoteViewController class implementation
 * @author Masayuki YAMAYA
 * @date 2010-06-01
 */
#import "QuoteViewController.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

@implementation QuoteViewController

@dynamic quote;
@dynamic source;

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	NSFont * font = [sourceField_ font];
	[quoteTextView_ setFont:font];
}

- (NSString *)source
{
	return [sourceField_ stringValue];
}

- (NSString *)quote
{
	return [quoteTextView_ string];
}

- (void)setContentsWithText:(NSString *)quoteText source:(NSString *)source
{
	[quoteTextView_ setString:Stringnize(quoteText)];
	[sourceField_ setStringValue:Stringnize(source)];
}
@end
