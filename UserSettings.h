/**
 * @file UserSettings.h
 * @brief UserSetting class declaration
 */
#import <Cocoa/Cocoa.h>

@interface UserSettings : NSObject
{
	NSMutableDictionary* dictionary_;
}

+ (UserSettings *)sharedInstance;

- (void)synchronize;

- (NSString *)stringForKey:(NSString *)defaultName;

- (BOOL)boolForKey:(NSString *)defaultName;

- (void)setObject:(id)value forKey:(NSString *)defaultName;

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
@end
