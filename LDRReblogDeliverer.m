/**
 * @file LDRReblogDeliverer.m
 * @brief LDRReblogDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLDocument.h
#import "LDRReblogDeliverer.h"
#import "LDRDelivererContext.h"
#import "DebugLog.h"
#import <WebKit/WebKit.h>

@implementation LDRReblogDeliverer
+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	// Tumblr ポストかどうかのチェック
	if (![LDRDelivererContext match:document target:clickedElement]) return nil;

	// LDRDelivererContext を生成する
	LDRDelivererContext * context = [[[LDRDelivererContext alloc] initWithDocument:document target:clickedElement] autorelease];
	if (context == nil) return nil;

	NSURL * url = [NSURL URLWithString:context.documentURL];
	if (url == nil) 
		return nil;

	NSRange range;
	DOMNode * node = [clickedElement objectForKey:WebElementImageURLKey];
	if (node != nil && [[node className] isEqualToString:@"DOMHTMLImageElement"]) {
		DOMHTMLImageElement * img = (DOMHTMLImageElement *)node;
		range = [[img src] rangeOfString:[self dataSiteURL]];
		if (!(range.location == 0 && range.length >= [[self dataSiteURL] length])) {
			return nil;
		}
	}
	else {
		range = [[url host] rangeOfString:[self sitePostfix]];
		if (!(range.location > 0 && range.length == [[self sitePostfix] length])) {
			return nil;
		}
	}

	NSString * postID = [context.documentURL lastPathComponent];
	if (postID == nil) {
		D(@"Could not get PostID. element:%@", [clickedElement description]);
		return nil;
	}

	// LDR ではこの時点で ReblogKey は得られないので未指定で
	LDRReblogDeliverer * deliverer = [[LDRReblogDeliverer alloc] initWithContext:context postID:postID];
	if (deliverer == nil) {
		D(@"Could not alloc+init %@.", [LDRReblogDeliverer className]);
	}

	return deliverer;
}
@end
