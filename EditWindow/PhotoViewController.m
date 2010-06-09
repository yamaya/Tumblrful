#import "PhotoViewController.h"
#import <WebKit/WebKit.h>

#define TEMPLATE	@"<html><body><div align=\"center\"><img src=\"%@\" width=\"%dpx\"></img></div></body></html>"
#define SCROLLBAR_WIDTH	(20)

@implementation PhotoViewController

#if 0
@dynamic imageURL;
#endif
@dynamic caption;
@dynamic throughURL;

- (void)setContentsWithImageURL:(NSString *)imageURL caption:(NSString *)caption throughURL:(NSString *)throughURL
{
	NSRect const bounds = [webView_ bounds];
	NSString * html = [NSString stringWithFormat:TEMPLATE, imageURL, (NSInteger)bounds.size.width - SCROLLBAR_WIDTH];
	[[webView_ mainFrame] loadHTMLString:html baseURL:nil];

	[captionField_ setString:caption];
	[throughURLField_ setStringValue:throughURL];
}
#if 0
- (NSString *)imageURL
{
	return nil;
}
#endif
- (NSString *)caption
{
	return [captionField_ string];
}

- (NSString *)throughURL
{
	return [throughURLField_ stringValue];
}
@end
