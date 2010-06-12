/**
 * @file FlickrPhotoDeliverer.m
 * @brief FlickrPhotoDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "FlickrPhotoDeliverer.h"
#import "DelivererRules.h"
#import "Anchor.h"
#import "DebugLog.h"

#define TIMEOUT	(30)

#pragma mark -
@interface FlickrPhotoDeliverer ()
- (NSString *)photoIDWithURL:(NSURL *)URL;
- (NSXMLDocument *)photoInfoXMLWithPhotoID:(NSString *)photoID;
- (NSString *)captionWithXML:(NSXMLDocument *)xmlDoc withPhotoID:(NSString *)photoID;
- (void)failedWith:(NSString *)photoID message:(NSString *)message;
- (void)failedWith:(NSString *)photoID error:(NSError *)error;
- (void)failedWith:(NSString *)photoID exception:(NSException *)exception;
@end

#pragma mark -
@implementation FlickrPhotoDeliverer

+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	// URL of clicked image
	id imageURL = [clickedElement objectForKey:WebElementImageURLKey];
	if (imageURL == nil) {
		return nil;
	}

	// check URL's host
	NSURL * url = [NSURL URLWithString:[[document URL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if (![[url host] hasSuffix:@"flickr.com"]) {
		return nil;
	}

	// create a object of this class
	FlickrPhotoDeliverer * deliverer = nil;
	deliverer = [[FlickrPhotoDeliverer alloc] initWithDocument:document target:clickedElement];
	if (deliverer == nil) {
		D(@"Could not alloc+init %@.", [self className]);
	}

	return deliverer;
}

- (NSString *)titleForMenuItem
{
	return [NSString stringWithFormat:@"%@ - Flickr", [super titleForMenuItem]];
}

- (NSDictionary *)photoContents
{
	// 画像の URL
	NSURL * sourceURL = [clickedElement_ objectForKey:WebElementImageURLKey];
	NSString * source = [sourceURL absoluteString];

	// Flickr Photo ID を得る
	NSString * photoID = [self photoIDWithURL:sourceURL];
	if (photoID == nil) {
		// エラーメッセージは photoIDWithURL メソッド内部で出力しているのでここでは不要
		return nil;
	}

	// caption を作る
	NSString * caption = [self captionWithXML:[self photoInfoXMLWithPhotoID:photoID] withPhotoID:photoID];
	if (caption == nil) {
		/*
		 * ここでの nil リターンは Flickr から画像のメタ情報が取り出せなかった事
		 * を意味する。よってSuperの Photoと同じ形式で caption を作る。
		 * エラーメッセージは photoInfoXMLWithPhotoID メソッド内部で出力しているのでここでは
		 * 不要。
		 */
		 caption = [context_ anchorTagToDocument];
	}
	NSString * selection = [self selectedStringWithBlockquote];
	if (selection != nil && [selection length] > 0) {
		caption = [caption stringByAppendingFormat:@"\r%@", selection];
	}
	D(@"caption: %@", caption);

	return [NSDictionary dictionaryWithObjectsAndKeys:source, @"source", caption, @"caption", [context_ documentURL], @"throughURL", nil];
}

- (NSString *)photoIDWithURL:(NSURL *)URL
{
	@try {
		// lastPathComponent は拡張子も取り除く
		NSString * photoID = [[URL path] lastPathComponent];
		if (photoID == nil) {
			return nil;
		}
		D(@"photoID(1st):%@", photoID);

		if ([photoID isEqualToString:@"spaceball.gif"]) {
			// オリジナルの画像にかぶせてるねぇ
			photoID = [[context_ documentURL] lastPathComponent];
			D(@"photoID(1st retry):%@", photoID);
			[self notify:[DelivererRules errorMessageWith:@"This photo is spaceball!"]];
			return nil;
		}

		/* '_' が含まれるならば、それ以降、拡張子までを取り除く
			 (ex. 2336266891_e7515e01f9.jpg) */
		NSRange range = [photoID rangeOfString:@"_"];
		if (range.location != NSNotFound) {
			range.length = range.location;
			range.location = 0;
			photoID = [photoID substringWithRange:range];
		}
		D(@"photoID(2nd):%@", photoID);

		// 10進数文字列である事をチェクする
		NSString * s = [NSString stringWithFormat:@"%qi", [photoID longLongValue]];
		if ([photoID isEqualToString:s]) {
			return photoID;
		}
		D(@"PhotoID \"%@\" was invalid.", photoID);
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithException:e];
		return nil;
	}

	[self notify:[DelivererRules errorMessageWith:@"Failed parse PhotoID"]];
	return nil;
}

- (NSXMLDocument *)photoInfoXMLWithPhotoID:(NSString *)photoID
{
	static NSString * FLICKR_API_URL_GET_INFO = @"http://api.flickr.com/services/rest/?method=flickr.photos.getInfo";
	static NSString * FLICKR_APY_KEY = @"e67c6978a3f4c079f5cd61ac3e9111ae";

	NSString * apiURL = [NSString stringWithFormat:@"%@&api_key=%@&photo_id=%@", FLICKR_API_URL_GET_INFO, FLICKR_APY_KEY, photoID];
	D(@"getInfoURI=%@", apiURL);

	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:apiURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TIMEOUT];
	NSURLResponse * response = nil;
	NSError * error = nil;
	NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (data == nil || [data length] < 1) {
		[self failedWith:photoID error:error];
		return nil;
	}

	error = nil;
	NSXMLDocument * xmlDoc = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
	if (xmlDoc == nil) {
		[self failedWith:photoID error:error];
	}
	return xmlDoc;
}

- (NSString *)captionWithXML:(NSXMLDocument *)xmlDoc withPhotoID:(NSString*)photoID
{
	NSMutableString * caption = [NSMutableString string];

	@try {
		NSError * error = nil;
		NSArray * nodes = [xmlDoc nodesForXPath:@"//photo/urls/url" error:&error];
		if (nodes == nil || [nodes count] < 1) {
			[self failedWith:photoID error:error];
			return nil;
		}

		// urlsの先頭の URL を得る
		NSURL * url = [NSURL URLWithString:[[nodes objectAtIndex:0] objectValue]];
		if (url == nil) {
			[self failedWith:photoID message:@"Invalid URL from //photo/urls/url."];
			return nil;
		}

		// aタグを作り caption に追加
		NSString * s = nil;
		nodes = [xmlDoc nodesForXPath:@"//photo/title" error:nil];
		if ([nodes count] > 0) {
			s = [Anchor htmlWithURL:[url absoluteString] title:[[nodes objectAtIndex:0] stringValue]];
			[caption appendString:s];
		}

		// description があれば blockquote して caption に追加
		nodes = [xmlDoc nodesForXPath:@"//photo/description" error:nil];
		if ([nodes count] > 0) {
			s = [[nodes objectAtIndex:0] stringValue];
			if (s != nil && [s length] > 0) {
				[caption appendFormat:@"<blockquote>%@</blockquote>", s];
			}
		}

		// username があれば(あるはず) ユーザーページへの aタグを作って caption に追加
		nodes = [xmlDoc nodesForXPath:@"//photo/owner" error:nil];
		if ([nodes count] > 0) {
			NSXMLNode * node = [[nodes objectAtIndex:0] attributeForName:@"username"];
			if (node != nil) {
				NSString * username = [node stringValue];
				if (username != nil) {
					D(@"anchor=%@", [[url path] stringByDeletingLastPathComponent]);
					NSString * userURL = [NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [[url path] stringByDeletingLastPathComponent]];
					s = [Anchor htmlWithURL:userURL title:username];
					[caption appendFormat:@" (via %@)", s];
				}
			}
		}
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWith:photoID exception:e];
		return nil;
	}

	return caption;
}

- (void)failedWith:(NSString*)photoID message:(NSString*)message
{
	NSString* s = [NSString stringWithFormat:@"%@ - PhotoID:%@", message, photoID];
	[self notify:[DelivererRules errorMessageWith:s]];
}

- (void)failedWith:(NSString*)photoID error:(NSError*)error
{
	[self failedWith:photoID message:[error description]];
}

- (void)failedWith:(NSString*)photoID exception:(NSException*)exception
{
	[self failedWith:photoID message:[exception description]];
}
@end
