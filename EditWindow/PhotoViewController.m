#import "PhotoViewController.h"
#import "DebugLog.h"
#if 0
#import <WebKit/WebKit.h>

#define TEMPLATE	@"<html><body><div align=\"center\"><img src=\"%@\" width=\"%dpx\"></img></div></body></html>"
#define SCROLLBAR_WIDTH	(20)
#endif

@implementation PhotoViewController

@dynamic caption;
@dynamic throughURL;

- (void)setContentsWithImageURL:(NSString *)imageURL image:(NSImage *)image caption:(NSString *)caption throughURL:(NSString *)throughURL
{
#if 1
#pragma unused (imageURL)
	D_METHOD;

	[imageView_ setImage:image];
#else
	NSRect const bounds = [webView_ bounds];
	NSString * html = [NSString stringWithFormat:TEMPLATE, imageURL, (NSInteger)bounds.size.width - SCROLLBAR_WIDTH];
	[[webView_ mainFrame] loadHTMLString:html baseURL:nil];
#endif
	[captionField_ setString:caption];
	[throughURLField_ setStringValue:throughURL];
}

- (NSString *)caption
{
	return [captionField_ string];
}

- (NSString *)throughURL
{
	return [throughURLField_ stringValue];
}
@end
