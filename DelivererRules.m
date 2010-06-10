/**
 * @file DelivererRules.m
 * @brief DelivererRules implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "DelivererRules.h"
#import "Log.h"

@implementation DelivererRules
/**
 * MenueItemのタイトルを作成する
 */
+ (NSString*) menuItemTitleWith:(NSString*)suffix
{
	return [NSString stringWithFormat:@"Share - %@", suffix];
}

/**
 * エラーメッセーを作成する
 */
+ (NSString*) errorMessageWith:(NSString*)message
{
	return [NSString stringWithFormat:@"Error - %@", message];
}

/**
 * aタグを作る
 */
+ (NSString *)anchorTag:(DOMHTMLDocument *)document
{
	return [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", [document URL], [document title]];
}

/**
 * aタグを作る
 */
+ (NSString*) anchorTagWithName:(NSString*)url name:(NSString*)name
{
	if (name == nil) {
		name = url;
	}
	return [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", url, name];
}
@end
