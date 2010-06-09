/**
 * @file QuoteViewController.h
 * @brief QuoteViewController class declaration
 * @author Masayuki YAMAYA
 * @date 2010-06-01
 */
#import <Cocoa/Cocoa.h>

@interface QuoteViewController : NSViewController
{
	IBOutlet NSTextView * quoteTextView_;
	IBOutlet NSTextField * sourceField_;
}

@property (nonatomic, readonly) NSString * source;

@property (nonatomic, readonly) NSString * quote;

- (void)setContentsWithText:(NSString *)quoteText source:(NSString *)source;

@end
