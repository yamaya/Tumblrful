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

- (NSString *)stringByURLEncoding:(NSStringEncoding)encoding
{
	NSArray * escapeChars = [NSArray arrayWithObjects:@";", @"/", @"?", @":", @"@", @"&", @"=", @"+", @"$", @",", @"[", @"]", @"#", @"!", @"'", @"(", @")", @"*", nil];
	NSArray * replaceChars = [NSArray arrayWithObjects:@"%3B", @"%2F", @"%3F",@"%3A", @"%40", @"%26", @"%3D", @"%2B", @"%24", @"%2C", @"%5B", @"%5D", @"%23", @"%21", @"%27",@"%28", @"%29", @"%2A", nil];

	NSMutableString * encodedString = [[[self stringByAddingPercentEscapesUsingEncoding:encoding] mutableCopy] autorelease];

	const NSUInteger N = [escapeChars count];
	for (NSUInteger i = 0; i < N; i++) {
		[encodedString replaceOccurrencesOfString:[escapeChars objectAtIndex:i]
									   withString:[replaceChars objectAtIndex:i]
										  options:NSLiteralSearch
											range:NSMakeRange(0, [encodedString length])];
	}

	return [NSString stringWithString: encodedString];
}

- (NSString *)stripHTMLTags:(NSArray *)excludes
{
	NSScanner * scanner;
	NSString * text = nil;
	NSString * tag = nil;
	NSString * result = [self copy];

	scanner = [NSScanner scannerWithString:self];

	while ([scanner isAtEnd] == NO) {
		[scanner scanUpToString:@"<" intoString:NULL];
		[scanner scanUpToString:@">" intoString:&text];

		if ([text rangeOfString:@"</"].location != NSNotFound) {
			tag = [text substringFromIndex:2]; // remove "</"
		}
		else {
			tag = [text substringFromIndex:1]; // remove "<"
			if ([tag rangeOfString:@" "].location != NSNotFound)
				tag = [tag substringToIndex:[tag rangeOfString:@" "].location];
		}

		if (excludes == nil || [excludes containsObject:tag] == NO)
			result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
	}
	return result;
}
@end
