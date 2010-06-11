/**
 * @file NSString+Tumblrful.m
 * @brief NSString additions
 */
#import "NSString+Tumblrful.m"

NSString * EmptyString = @"";

@implementation NSString (Tumblrful)
- (NSString *)stringByTrimmingWhitespace
{
	NSString * s = self;
	s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	s = [s stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\xE3\x80\x80"]];
	return s;
}
@end
