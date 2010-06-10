#import "LinkViewController.h"
#import "NSString+Tumblrful.h"
#import "PostEditConstants.h"
#import "DebugLog.h"

@implementation LinkViewController

@dynamic title;
@dynamic URL;
@dynamic description;

- (void)awakeFromNib
{
	NSFont * font =[NSFont systemFontOfSize:POSTEDIT_TEXT_FONT_SIZE];
	[[descriptionTextView_ textStorage] setFont:font];
	[descriptionTextView_ setFont:font];
}

- (void)setContentsWithTitle:(NSString *)title URL:(NSString *)url description:(NSString *)description
{
	[titleFiled_ setStringValue:Stringnize(title)];
	[urlField_ setStringValue:Stringnize(url)];
	[descriptionTextView_ setString:Stringnize(description)];
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
	return [descriptionTextView_ string];
}
@end
