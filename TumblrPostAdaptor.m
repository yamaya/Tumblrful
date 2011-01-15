/**
 * @file TumblrPostAdaptor.m
 * @brief TumblrPostAdaptor class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "TumblrPostAdaptor.h"
#import "TumblrPost.h"
#import "DebugLog.h"
#import <AppKit/NSBitmapImageRep.h>

#pragma mark -
@interface TumblrPostAdaptor ()
- (void)postWithType:(NSString *)type withParams:(NSDictionary *)params;
@end

#pragma mark -
@implementation TumblrPostAdaptor

- (void)postLink:(Anchor *)anchor description:(NSString *)description
{
	[self postWithType:@"link" withParams:[NSDictionary dictionaryWithObjectsAndKeys:anchor.URL, @"url", anchor.title, @"name", description, @"description", nil]];
}

- (void)postQuote:(NSString *)quote source:(NSString *)source;
{
	[self postWithType:@"quote" withParams:[NSDictionary dictionaryWithObjectsAndKeys:quote, @"quote", source, @"source", nil]];
}

- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL image:(NSImage *)image
{
	NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:caption, @"caption", throughURL, @"click-through-url", nil];
	if (source != nil && [source length] > 0) {
		[params setObject:source forKey:@"source"];
	}
	else {
		NSBitmapImageRep * imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
		NSDictionary * properties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0f], NSImageCompressionFactor, nil];
		NSData * data = [imageRep representationUsingType:NSJPEGFileType properties:properties];
		[params setObject:data forKey:@"data"];
	}
	D0([params description]);

	[self postWithType:@"photo" withParams:params];
}

- (void)postVideo:(NSString *)embed caption:(NSString*)caption
{
	[self postWithType:@"video" withParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:embed, @"embed", caption, @"caption", nil]];
}

- (void)postEntry:(NSDictionary *)params
{
	if (self.extractEnabled)
		[self postWithType:@"reblog" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[params objectForKey:@"pid"], @"pid", [params objectForKey:@"rk"], @"rk", nil]];
	else
		[self postWithType:@"reblog" withParams:params];
}

- (void)postWithType:(NSString *)type withParams:(NSDictionary *)params
{
	@try {
		// Tumblrへポストするオブジェクトを生成する
		TumblrPost * tumblr = [[TumblrPost alloc] initWithCallback:callback_];

		// プライベートとキューイングの設定をしておく
		tumblr.privated = self.privated;
		tumblr.queuingEnabled = self.queuingEnabled;
		tumblr.extractEnabled = self.extractEnabled;

		// リクエストパラメータを構築する
		/*
		if (this.value == '2') {
			$('create_post_button_label').innerHTML = 'Queue post';
			if ($('set_date')) Element.hide('set_date');
		} else if (this.value == 'on.2') {
			$('create_post_button_label').innerHTML = 'Schedule post';
			Element.show('set_publish_on_time');
			if ($('set_date')) Element.hide('set_date');
			$('post_publish_on').value = 'next tuesday, 10am';
		} else if (this.value == '1') {
			$('create_post_button_label').innerHTML = 'Save draft';
			Element.show('set_status_message');
			if ($('set_date')) Element.hide('set_date');
		} else if (this.value == 'private') {
			if ($('set_date')) Element.hide('set_date');
			Element.hide('set_slug');
			// Element.hide('set_tags');
			if ($('set_twitter')) {
				Element.hide('autopost_options');
				Element.hide('set_twitter');
			}
			$('create_post_button_label').innerHTML = 'Create post';
		} else {
			if ($('select_channel')) Element.show('select_channel');
			$('create_post_button_label').innerHTML = 'Create post';
		}
		*/
		NSMutableDictionary * requestParams = [tumblr createMinimumRequestParams];
		// private
		if (self.privated) {
			if ([type isEqualToString:@"reblog"]) {
				[requestParams setObject:@"private" forKey:@"post[state]"];
			}
			else {
				[requestParams setObject:@"1" forKey:@"private"];
			}
		}
		else {
			// twitter
			NSNumber * twitter = [self.options objectForKey:@"twitter"];
			D(@"twitter=%@", [twitter description]);
			if (twitter != nil && [twitter boolValue]) {
				[requestParams setObject:@"checked" forKey:@"send_to_twitter"];
			}
		}

		// post type
		if (![type isEqualToString:@"reblog"])
			[requestParams setObject:type forKey:@"type"];

		[requestParams addEntriesFromDictionary:params];

		// Tumblrへポストする
		[tumblr postWith:requestParams];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self callbackWithException:e];
	}
}
@end
