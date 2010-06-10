/**
 * @file UserSettings.m
 * @brief UserSetting class declaration
 */
#import "UserSettings.h"
#import "TumblrfulConstants.h"
#import "DebugLog.h"

#define PLIST_FILENAME	@"Settings.plist"

@interface UserSettings ()
- (void)load;
- (NSString *)pathForPropertyList;
- (void)migrateToSettingsPlistFromSafariUserDefaults;
@end

static UserSettings * instance = nil;

@implementation UserSettings

+ (UserSettings *)sharedInstance
{
	if (instance == nil) {
		instance = [[UserSettings alloc] init];
		[instance load];
	}
	return instance;
}

- (id)init
{
	if ((self = [super init]) != nil) {
		dictionary_ = nil;
	}
	return self;
}

- (void)dealloc
{
	[dictionary_ release];

	[super dealloc];
}

- (void)load
{
	if (dictionary_ == nil) {
		D0([self pathForPropertyList]);
		NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:[self pathForPropertyList]];
		if (dict != nil) {
			dictionary_ = [dict mutableCopy];
		}
		else {
			dictionary_ = [[NSMutableDictionary dictionary] retain];
			[self migrateToSettingsPlistFromSafariUserDefaults];
		}
		D0([dictionary_ description]);
	}
}

- (void)synchronize
{
	D0([dictionary_ description]);

	if (dictionary_ != nil) {
		NSString * filePath = [self pathForPropertyList];

		NSFileManager * fileManager = [NSFileManager defaultManager];
		D(@"fileExistsAtPath:%d",[fileManager fileExistsAtPath:filePath]); 
		if (![fileManager fileExistsAtPath:filePath]) {
			NSMutableArray * pathComponents = [NSMutableArray arrayWithArray:[filePath pathComponents]];
			D0([pathComponents description]);
			[pathComponents removeLastObject];

			NSString * directoryPath = [NSString pathWithComponents:pathComponents];
			D0(directoryPath);

			NSError * error = nil;
			BOOL const result = [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error];
			D(@"result: %d, %@", result, [error description]);
		}

		BOOL result = [dictionary_ writeToFile:filePath atomically:YES];
		D(@"result:%d", result);
	}
}

- (void)setObject:(id)value forKey:(NSString *)defaultName;
{
	if (value != nil)
		[dictionary_ setObject:value forKey:defaultName];
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName
{
	D(@"%@ => %@", defaultName, [[NSNumber numberWithBool:value] stringValue]);
	[dictionary_ setObject:[[NSNumber numberWithBool:value] stringValue] forKey:defaultName];
}

- (NSString *)stringForKey:(NSString *)defaultName
{
	return [dictionary_ objectForKey:defaultName];
}

- (BOOL)boolForKey:(NSString *)defaultName
{
	NSString * value = [dictionary_ objectForKey:defaultName];
	if (value != nil)
		return [value boolValue];
	return NO;
}

- (NSString *)pathForPropertyList
{
	NSString * bundleName = [[NSBundle bundleWithIdentifier:TUMBLRFUL_BUNDLE_ID] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
	NSString * plist = [NSString stringWithFormat:@"%@/%@", bundleName, PLIST_FILENAME];

    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:plist];
}

- (void)migrateToSettingsPlistFromSafariUserDefaults
{
	NSUserDefaults* defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];

	static struct {
		NSString * source;
		NSString * destination;
	} keyPair[] = {
		{@"TumblrfulEmail",					@"tumblrEmail"},
		{@"TumblrfulPassword",				@"tumblrPassword"},
		{@"TumblrfulPrivate",				@"tumblrPrivateEnabled"},
		{@"TumblrfulQueuing",				@"tumblrQueuingEnabled"},
		{@"TumblrfulWithDelicious",			@"deliciousEnabled"},
		{@"TumblrfulDeliciousUsername", 	@"deliciousUsername"},
		{@"TumblrfulDeliciousPassword", 	@"deliciousPassword"},
		{@"TumblrfulDeliciousPrivate",		@"deliciousPrivateEnabled"},
		{@"TumblrfulUseOtherTumblog",		@"otherTumblogEnabled"},
		{@"TumblrfulOtherTumblogSiteURL", 	@"otherTumblogSiteURL"},
		{@"TumblrfulOtherTumblogLogin", 	@"otherTumblogLoginName"},
		{@"TumblrfulOtherTumblogPassword", 	@"otherTumblogPassword"},
	};

	BOOL migrated = NO;
	for (NSUInteger i = 0; i < sizeof(keyPair) / sizeof(keyPair[0]); ++i) {
		id value = [defaults objectForKey:keyPair[i].source];
		if (value != nil) {
			[dictionary_ setObject:value forKey:keyPair[i].destination];
			[defaults removeObjectForKey:keyPair[i].source];
			migrated = YES;
		}
	}

	if (migrated) {
		[self synchronize];
	}
}

@end
