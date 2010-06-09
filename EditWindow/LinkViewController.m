#import "LinkViewController.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

@implementation LinkViewController

@dynamic title;
@dynamic URL;
@dynamic description;

- (void)setContentsWithTitle:(NSString *)title URL:(NSString *)url description:(NSString *)description
{
	[titleFiled_ setStringValue:Stringnize(title)];
	[urlField_ setStringValue:Stringnize(url)];
	[descriptionField_ setStringValue:Stringnize(description)];
}

- (NSString *)title
{
	return [titleFiled_ stringValue];
}

- (NSString *)URL
{
	return [urlField_ stringValue];
}

- (NSString *)description
{
	return [descriptionField_ stringValue];
}
@end
