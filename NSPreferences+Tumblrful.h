/**
 * @file NSPreferences_Tumblrful.h
 * @brief NSPreferences_Tumblrful declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import <Cocoa/Cocoa.h>
#import "NSPreferenceModule.h"

@interface NSPreferences (Tumblrful)
+ sharedPreferences_SwizzledByTumblrful;
@end
