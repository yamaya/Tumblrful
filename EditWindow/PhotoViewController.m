#import "PhotoViewController.h"
#import "DebugLog.h"

@implementation PhotoViewController

@dynamic caption;
@dynamic throughURL;

- (void)setContentsWithImageURL:(NSString *)imageURL image:(NSImage *)image caption:(NSString *)caption throughURL:(NSString *)throughURL
{
#pragma unused (imageURL)
	D_METHOD;

	[imageView_ setImage:image];
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
