/**
 * @file NSString+Tumblrful.h
 * @brief NSString additions
 */

extern NSString * EmptyString;

#define Stringnize(s)	((s) != nil ? (s) : @"")

@interface NSString (Tumblrful)
- (NSString *)stringByTrimmingWhitespace;
@end
