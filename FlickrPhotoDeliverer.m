/**
 * @file FlickrPhotoDeliverer.m
 * @brief FlickrPhotoDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "FlickrPhotoDeliverer.h"
#import "DelivererRules.h"
#import "Log.h"

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

#pragma mark -
@interface FlickrPhotoDeliverer (Private)
- (NSString*) parsePhotoID:(NSURL*)url;
- (NSString*) makeCaption:(NSString*)photoID;
- (NSString*) makeCaptionByPhotoInfoXML:(NSData*)data photoID:(NSString*)photoID;
- (void) post;
- (NSString*) anchorTag:(NSString*)uri with:(NSString*)name;
- (void) failedWith:(NSString*)photoID message:(NSString*)message;
- (void) failedWith:(NSString*)photoID error:(NSError*)error;
- (void) failedWith:(NSString*)photoID exception:(NSException*)exception;
@end

#pragma mark -
@implementation FlickrPhotoDeliverer (Private)
/**
 * DOMHTMLDocument から Flickr PhotoID を取得する
 */
- (NSString*) parsePhotoID:(NSURL*)url
{
	@try {
		/* lastPathComponent は拡張子も取り除く */
		NSString* photoID = [[url path] lastPathComponent];
		if (photoID == nil) {
			return nil;
		}
		V(@"photoID(1st):%@", photoID);

		if ([photoID isEqualToString:@"spaceball.gif"]) {
			/* オリジナルの画像にかぶせてるねぇ */
			photoID = [[context_ documentURL] lastPathComponent];
			V(@"photoID(1st retry):%@", photoID);
			[self notify:[DelivererRules errorMessageWith:@"Failed parse: PhotoID was spaceball!"]];
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
		V(@"photoID(2nd):%@", photoID);

		/* 10進数文字列である事をチェクする */
		NSString* s = [NSString stringWithFormat:@"%qi", [photoID longLongValue]];
		if ([photoID isEqualToString:s]) {
			return photoID;
		}
		V(@"PhotoID \"%@\" was invalid.", photoID);
	}
	@catch (NSException* e) {
		[self failedWithException:e];
		return nil;
	}

	[self notify:[DelivererRules errorMessageWith:@"Failed parse PhotoID by Unknown reason."]];
	return nil;
}

/**
 * Flickr "getInfo" API を使って Photo のメタ情報を得て、そこから caption を作る
 */
- (NSString*) makeCaption:(NSString*)photoID
{
	static NSString* FLICKR_API_URL_GET_INFO = @"http://api.flickr.com/services/rest/?method=flickr.photos.getInfo";
	static NSString* FLICKR_APY_KEY = @"e67c6978a3f4c079f5cd61ac3e9111ae";

	NSString* uri = [NSString stringWithFormat:@"%@&api_key=%@&photo_id=%@", FLICKR_API_URL_GET_INFO, FLICKR_APY_KEY, photoID];
	V(@"getInfoURI=%@", uri);

	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:uri]
											 cachePolicy:NSURLRequestUseProtocolCachePolicy
										 timeoutInterval:30];
	NSURLResponse* response = nil;
	NSError* error = nil;
	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (data == nil || [data length] < 1) {
		[self failedWith:photoID error:error];
		return nil;
	}

	return [self makeCaptionByPhotoInfoXML:data photoID:photoID];
}

/**
 * makeCaption の下請けメソッド
 */
- (NSString*) makeCaptionByPhotoInfoXML:(NSData*)xmlData photoID:(NSString*)photoID
{
	NSMutableString* caption = [[[NSMutableString alloc] init] autorelease];

	@try {
		NSError* error = nil;
		NSXMLDocument* document = [[NSXMLDocument alloc] initWithData:xmlData options:NSXMLDocumentTidyXML error:&error];
		if (document == nil) {
			[self failedWith:photoID error:error];
			return nil;
		}

		NSArray* nodes = [document nodesForXPath:@"//photo/urls/url" error:&error];
		if (nodes == nil || [nodes count] < 1) {
			[self failedWith:photoID error:error];
			return nil;
		}

		/* urlsの先頭の URL を得る TODO: これ XPath でもできるな */
		NSURL* url = [NSURL URLWithString:[[nodes objectAtIndex:0] objectValue]];
		if (url == nil) {
			[self failedWith:photoID message:@"Invalid URL from //photo/urls/url."];
			return nil;
		}

		NSString* s = nil;
		/* aタグを作り caption に追加 */
		nodes = [document nodesForXPath:@"//photo/title" error:nil];
		if ([nodes count] > 0) {
			s = [self anchorTag:[url absoluteString] with:[[nodes objectAtIndex:0] stringValue]];
			[caption appendString:s];
		}

		/* description があれば blockquote して caption に追加 */
		nodes = [document nodesForXPath:@"//photo/description" error:nil];
		if ([nodes count] > 0) {
			s = [[nodes objectAtIndex:0] stringValue];
			if (s != nil && [s length] > 0) {
				[caption appendFormat:@"<blockquote>%@</blockquote>", s];
			}
		}

		/* username があれば(あるはず) ユーザーページへの aタグを作って caption に追加 */
		nodes = [document nodesForXPath:@"//photo/owner" error:nil];
		if ([nodes count] > 0) {
			NSXMLNode* node = [[nodes objectAtIndex:0] attributeForName:@"username"];
			if (node != nil) {
				NSString* username = [node stringValue];
				if (username != nil) {
					V(@"anchor=%@", [[url path] stringByDeletingLastPathComponent]);
					NSString* userURL =
						[NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [[url path] stringByDeletingLastPathComponent]];
					s = [self anchorTag:userURL with:username];
					[caption appendFormat:@" (via %@)", s];
				}
			}
		}
	}
	@catch (NSException * e) {
		[self failedWith:photoID exception:e];
		return nil;
	}

	return caption;
}

- (void) post
{
	/* 画像の URL */
	NSURL* source = [clickedElement_ objectForKey:WebElementImageURLKey];
	V(@"source: %@, class=%@", [source absoluteString], [source className]);

	/* Flickr Photo ID を得る */
	NSString* photoID = [self parsePhotoID:source];
	if (photoID == nil) {
		/* エラーメッセージは parsePhotoID メソッド内部で出力しているのでここでは不要 */
		return;
	}

	/* 画像をクリックした時の飛び先 URL */
	NSString* through = [context_ documentURL];
	V(@"click-through-URL: %@", through);

	/* caption を作る */
	NSString* caption = [self makeCaption:photoID];
	if (caption == nil) {
		/*
		 * ここでの nil リターンは Flickr から画像のメタ情報が取り出せなかった事
		 * を意味する。よってSuperの Photoと同じ形式で caption を作る。
		 * エラーメッセージは makeCaption メソッド内部で出力しているのでここでは
		 * 不要。
		 */
		 caption = [context_ anchorTagToDocument];
	}
	V(@"caption: %@", caption);
	[super postPhoto:[source absoluteString] caption:caption through:through];
}

/**
 * aタグを作る
 */
- (NSString*) anchorTag:(NSString*)uri with:(NSString*)name
{
	if (name == nil) {
		name = uri;
	}

	return [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", uri, name];
}

/**
 * エラー処理
 */
- (void) failedWith:(NSString*)photoID message:(NSString*)message
{
	NSString* s = [NSString stringWithFormat:@"%@ - PhotoID:%@", message, photoID];
	[self notify:[DelivererRules errorMessageWith:s]];
}

/**
 * エラー処理
 */
- (void) failedWith:(NSString*)photoID error:(NSError*)error
{
	[self failedWith:photoID message:[error description]];
}

/**
 * エラー処理
 */
- (void) failedWith:(NSString*)photoID exception:(NSException*)exception
{
	[self failedWith:photoID message:[exception description]];
}
@end

#pragma mark -
@implementation FlickrPhotoDeliverer
/**
 * Deliverer のファクトリ
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	id imageURL = [clickedElement objectForKey:WebElementImageURLKey];
	if (imageURL == nil) {
		return nil;
	}

	/* check URL's host */
	NSURL* url = [NSURL URLWithString:[[document URL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ([[url host] hasSuffix:@"flickr.com"] == NO) {
		return nil;
	}

	/* create object */
	FlickrPhotoDeliverer* deliverer = nil;
	deliverer = [[FlickrPhotoDeliverer alloc] initWithDocument:document element:clickedElement];
	if (deliverer != nil) {
		return [deliverer retain]; //need?
	}
	Log(@"Could not alloc+init %@.", [self className]);
	return nil;
}

/**
 * MenuItemのタイトルを返す
 */
- (NSString*) titleForMenuItem
{
	return [NSString stringWithFormat:@"%@ - Flickr", [super titleForMenuItem]];
}

/**
 * メニューのアクション
 */
- (void) action:(id)sender
{
#pragma unused (sender)
	[self post];
}
@end
