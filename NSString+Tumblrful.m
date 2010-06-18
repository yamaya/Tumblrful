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
	NSArray * escapes = [NSArray arrayWithObjects:@";", @"/", @"?", @":", @"@", @"&", @"=", @"+", @"$", @",", @"[", @"]", @"#", @"!", @"'", @"(", @")", @"*", nil];
	NSArray * replaces = [NSArray arrayWithObjects:@"%3B", @"%2F", @"%3F",@"%3A", @"%40", @"%26", @"%3D", @"%2B", @"%24", @"%2C", @"%5B", @"%5D", @"%23", @"%21", @"%27",@"%28", @"%29", @"%2A", nil];

	NSMutableString * encodedString = [[[self stringByAddingPercentEscapesUsingEncoding:encoding] mutableCopy] autorelease];

	const NSUInteger N = [escapes count];
	for (NSUInteger i = 0; i < N; i++) {
		[encodedString replaceOccurrencesOfString:[escapes objectAtIndex:i]
									   withString:[replaces objectAtIndex:i]
										  options:NSLiteralSearch
											range:NSMakeRange(0, [encodedString length])];
	}

	return encodedString;
}

static NSString * ESCAPE_CHARS[] = {
	@";",
	@"/",
	@"?",
	@":",
	@"@",
	@"&",
	@"=",
	@"+",
	@"$",
	@",",
	@"[",
	@"]",
	@"#",
	@"!",
	@"'",
	@"(",
	@")",
	@"*"
};
static NSString * REPLACE_CHARS[] = {
	@"%3B",
	@"%2F",
	@"%3F",
	@"%3A",
	@"%40",
	@"%26",
	@"%3D",
	@"%2B",
	@"%24",
	@"%2C",
	@"%5B",
	@"%5D",
	@"%23",
	@"%21",
	@"%27",
	@"%28",
	@"%29",
	@"%2A"
};

- (NSString *)stringByURLDecoding:(NSStringEncoding)encoding
{
	NSArray * escapes = [NSArray arrayWithObjects:ESCAPE_CHARS count:sizeof(ESCAPE_CHARS) / sizeof(ESCAPE_CHARS[0])];
	NSArray * replaces = [NSArray arrayWithObjects:REPLACE_CHARS count:sizeof(REPLACE_CHARS) / sizeof(REPLACE_CHARS[0])];

	NSMutableString * decoded = [[[self stringByReplacingPercentEscapesUsingEncoding:encoding] mutableCopy] autorelease];

	NSUInteger const N = [replaces count];
	for (NSUInteger i = 0; i < N; i++) {
		[decoded replaceOccurrencesOfString:[replaces objectAtIndex:i]
								 withString:[escapes objectAtIndex:i]
									options:NSLiteralSearch
									  range:NSMakeRange(0, [decoded length])];
	}

	return decoded;
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

- (NSDictionary *)dictionaryWithKVPConnector:(NSString *)connector withSeparator:(NSString *)separator
{
	NSArray * separated = [self componentsSeparatedByString:separator];

	NSInteger const count = [separated count];
	NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:count];
	for (NSInteger i = 0; i < count; i++) {
		NSArray * kvp = [(NSString *)[separated objectAtIndex:i] componentsSeparatedByString:connector];
		if ([kvp count] == 2) {
			[dict setObject:[kvp objectAtIndex:1] forKey:[kvp objectAtIndex:0]];
		}
	}

	return dict;
}
@end
