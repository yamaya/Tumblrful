/**
 * @file Anchor.m
 * @brief Anchor implementation.
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Anchor.h"

@implementation Anchor

+ (Anchor*) anchorWithURL:(NSString*)url title:(NSString*)title
{
	Anchor* anchor = [[[Anchor alloc] initWithURL:url title:title] autorelease];
	return anchor;
}

- (id) initWithURL:(NSString*)url title:(NSString*)title
{
	if ((self =	[super init]) != nil) {
		url_ = [url retain];
		title_ = [title retain];
	}
	return self;
}

- (void) dealloc
{
	if (url_ != nil) {
		[url_ release];
		url_ = nil;
	}
	if (title_ != nil) {
		[title_ release];
		title_ = nil;
	}
	[super dealloc];
}


- (NSString*) URL
{
	return url_;
}

- (void) setURL:(NSString*)url
{
	if (url_ != nil) {
		[url_ release];
	}
	url_ = [url retain];
}

- (NSString*) title
{
	return title_;
}

- (void) setTitle:(NSString*)title
{
	if (title_ != nil) {
		[title_ release];
	}
	title_ = [title retain];
}

/**
 * make HTML anchor tag
 */
- (NSString*)tag
{
	NSString* title = (title_ != nil) ? title_ : url_;

	return [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", url_, title];
}
@end
