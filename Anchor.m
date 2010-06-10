/**
 * @file Anchor.m
 * @brief Anchor implementation.
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Anchor.h"

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
		url_ = [components objectForKey:@"URL"];
		title_ = [components objectForKey:@"title"];
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
	NSString * text = nil;
	NSString * tag = nil;
	NSString * result = [self copy];

	NSScanner * scanner = [NSScanner scannerWithString:html];

	while ([scanner isAtEnd] == NO) {
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
			NSString * title = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];

			scanner = [NSScanner scannerWithString:text];
			NSString * url = nil;
			[scanner scanUpToString:@"href" intoString:nil];
			[scanner scanUpToString:@"\"" intoString:nil];
			[scanner scanUpToString:@"\"" intoString:&url];
			return [NSDictionary dictionaryWithObjectsAndKeys:url, @"URL", title, @"title", nil];
		}
	}
	return [NSDictionary dictionary];
}
@end
