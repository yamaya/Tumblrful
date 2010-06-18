/**
 * @file Anchor.m
 * @brief Anchor implementation.
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Anchor.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

@interface Anchor ()
+ (NSDictionary *)componentsAnchorTag:(NSString *)html;
@end

@implementation Anchor

@synthesize URL = url_;
@synthesize title = title_;
@dynamic html;

- (id)initWithURL:(NSString *)url title:(NSString *)title
{
	if ((self =	[super init]) != nil) {
		url_ = [url retain];
		title_ = [title retain];
	}
	return self;
}

- (id)initWithHTML:(NSString *)html
{
	if ((self =	[super init]) != nil) {
		NSDictionary * components = [Anchor componentsAnchorTag:html];
		D0([components description]);
		url_ = [[components objectForKey:@"URL"] retain];
		title_ = [[components objectForKey:@"title"] retain];
	}
	return self;
}

- (void)dealloc
{
	[url_ release];
	[title_ release];

	[super dealloc];
}

- (NSString *)html
{
	NSString * title = (title_ != nil) ? title_ : url_;
	return [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", url_, title];
}

+ (Anchor *)anchorWithURL:(NSString *)url title:(NSString *)title
{
	return [[[Anchor alloc] initWithURL:url title:title] autorelease];
}

+ (Anchor *)anchorWithHTML:(NSString *)html
{
	return [[[Anchor alloc] initWithHTML:html] autorelease];
}

+ (NSString *)htmlWithURL:(NSString *)URL title:(NSString *)title
{
	Anchor * anchor = [[[Anchor alloc] initWithURL:URL title:title] autorelease];
	return anchor.html;
}

+ (NSDictionary *)componentsAnchorTag:(NSString *)html
{
	NSString * result = [html copy];

	NSScanner * scanner = [NSScanner scannerWithString:html];

	while ([scanner isAtEnd] == NO) {
		NSString * text = nil;
		NSString * tag = nil;

		[scanner scanUpToString:@"<" intoString:nil];
		[scanner scanUpToString:@">" intoString:&text];

		if ([text rangeOfString:@"</"].location != NSNotFound) {
			tag = [text substringFromIndex:2];
		}
		else {
			tag = [text substringFromIndex:1];
			if ([tag rangeOfString:@" "].location != NSNotFound) {
				tag = [tag substringToIndex:[tag rangeOfString:@" "].location];
			}
		}

		if ([tag isEqualToString:@"a"]) {
			D(@"text=%@", text);
			NSString * title = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
			title = [title stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"</%@>", tag] withString:@""];
			title = [title stringByTrimmingWhitespace];

			NSRange range = [text rangeOfString:@"href"];
			range.location += range.length;
			range.length = [text length] - range.location - 1;

			range = [text rangeOfString:@"\"" options:NSLiteralSearch range:range];
			range.location += range.length;
			range.length = [text length] - range.location - 1;

			NSString * url = [text substringWithRange:range];
			range = [url rangeOfString:@"\""];
			range.length = [url length] - range.length;
			if (range.location != NSNotFound)
				url = [url substringWithRange:range];

			return [NSDictionary dictionaryWithObjectsAndKeys:url, @"URL", title, @"title", nil];
		}
	}
	return [NSDictionary dictionary];
}
@end
