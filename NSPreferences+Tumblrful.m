/**
 * @file	NSPreferences_Tumblrful.h
 * @brief	NSPreferences_Tumblrful implementation
 * @author	Masayuki YAMAYA
 * @date	2008-03-03
 */
#import "NSPreferences+Tumblrful.h"
#import "TumblrfulPreferences.h"

@implementation NSPreferences (Tumblrful)

+ sharedPreferences_SwizzledByTumblrful
{
	static BOOL	added = NO;

	// オリジナルのメソッドを呼び出す
	id preferences = [self sharedPreferences_SwizzledByTumblrful];

	// Preference 上部にボタンを追加する
	if (preferences != nil && !added) {
		added = YES;
		[preferences addPreferenceNamed:@"Tumblrful" owner:[TumblrfulPreferences sharedInstance]];
	}

	return preferences;
}
@end
