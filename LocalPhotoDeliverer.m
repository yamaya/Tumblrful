/**
 * @file:   LocalPhotoDeliverer.m
 * @brief:	LocalPhotoDeliverer class implementation
 * @author:	Masayuki YAMAYA
 * @date:   2008-03-03
 */
#import "LocalPhotoDeliverer.h"
#import "DebugLog.h"
#import <WebKit/WebView.h>


static NSString * TumblrfulWebElementImageKey = @"TumblrfulWebElementImage"
static NSString * TYPE = @"Local Photo";

@interface LocalPhotoDeliverer ()
- (NSString *)selectedString;
@end

@implementation LocalPhotoDeliverer
+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	LocalPhotoDeliverer * deliverer = nil;

	id image = [clickedElement objectForKey:TumblrfulWebElementImageKey];
	if (image != nil) {
		deliverer = [[LocalPhotoDeliverer alloc] initWithDocument:document target:clickedElement];
		if (deliverer == nil) {
			D(@"Could not alloc+init %@Deliverer.", TYPE);
		}
	}

	return deliverer;
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
		clickedElement_ = [targetElement retain];
	}
	return self;
}

- (NSString *)titleForMenuItem
{
	return [NSString stringWithFormat:@"%@ (Local)", [self postType]];
}

- (void)action:(id)sender
{
#pragma unused (sender)
	@try {
		// コンテンツを得る
		NSDictionary * contents = [self photoContents];

		// ポストする
		[super postPhoto:@""
				 caption:[contents objectForKey:@"caption"]
				 through:[contents objectForKey:@"throughURL"]
				   image:[contents objectForKey:@"data"]];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithException:e];
	}
}

- (NSDictionary *)photoContents
{
	NSData * data = [clickedElement_ objectForKey:TumblrfulWebElementImageKey];

	// キャプション - セレクションがあればそれを blockquoteで囲って追加する
	NSString * caption = context_.anchorToDocument;
	NSString * selection = [self selectedStringWithBlockquote];
	if (selection != nil && [selection length] > 0) {
		caption = [caption stringByAppendingFormat:@"\r%@", selection];
	}

	return [NSDictionary dictionaryWithObjectsAndKeys:data, @"data", caption, @"caption", context_.documentURL, @"throughURL", nil];
}
@end
