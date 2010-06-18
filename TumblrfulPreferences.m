/**
 * @file TumblrfulPreferences.m
 * @brief TumblrfulPreferences implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "TumblrfulPreferences.h"
#import "GrowlSupport.h"
#import "TumblrfulConstants.h"
#import "UserSettings.h"
#import "DebugLog.h"

@implementation TumblrfulPreferences

+ (NSImage *)preloadImage:(NSString *)name
{
	NSString * imagePath = [[NSBundle bundleWithIdentifier:TUMBLRFUL_BUNDLE_ID] pathForImageResource:name];
	if (imagePath == nil) {
		D(@"imagePath for %@ is nil", name);
		return nil;
	}

	NSImage * image = [[NSImage alloc] initByReferencingFile:imagePath];
	if (image == nil) {
		D(@"image for %@ is nil", name);
		return nil;
	}

	[image setName:name];
	return image;
}

- (void)awakeFromNib
{
	NSDictionary * info = [[NSBundle bundleWithIdentifier:TUMBLRFUL_BUNDLE_ID] infoDictionary];
	D0([info description]);

	[authorTextField setStringValue:
		[NSString stringWithFormat:[authorTextField stringValue],
			[info objectForKey:@"CFBundleShortVersionString"],
			[info objectForKey:@"CFBundleVersion"]]];

	UserSettings * settings = [UserSettings sharedInstance];

	BOOL isNotEntered = NO;
	NSString* s;
	BOOL private = NO, queuing = NO;
	s = [settings stringForKey:@"tumblrEmail"];
	if (s == nil) {
		D0(@"tumblrEmail is nul");
		s = @"";
		isNotEntered = YES;
	}
	[emailTextField setStringValue:s];

	s = [settings stringForKey:@"tumblrPassword"];
	if (s == nil) {
		D0(@"tumblrPassword is nul");
		s = @"";
		isNotEntered = YES;
	}
	[passwordTextField setStringValue:s];

	if (isNotEntered) {
		[GrowlSupport notifyWithTitle:@"Tumblrful" description:@"Email or Password not entered."];
	}

	private = [settings boolForKey:@"tumblrPrivateEnabled"];
	[privateCheckBox setState:(private ? NSOnState : NSOffState)];

	queuing = [settings boolForKey:@"tumblrQueuingEnabled"];
	[queuingCheckBox setState:(queuing ? NSOnState : NSOffState)];

	/*
	 * delicious
	 */
	BOOL withDelicious = [settings boolForKey:@"deliciousEnabled"];
	[deliciousCheckBox setState:(withDelicious ? NSOnState : NSOffState)];

	isNotEntered = NO;

	s = [settings stringForKey:@"deliciousUsername"];
	if (s == nil) {
		D0(@"deliciousUsername is nul");
		s = @"";
		if (withDelicious) isNotEntered = YES;
	}
	[deliciousUsernameTextField setStringValue:s];

	s = [settings stringForKey:@"deliciousPassword"];
	if (s == nil) {
		D0(@"deliciousPassword is nul");
		s = @"";
		if (withDelicious) isNotEntered = YES;
	}
	[deliciousPasswordTextField setStringValue:s];

	if (isNotEntered) {
		[GrowlSupport notifyWithTitle:@"Tumblrful" description:@"Username or Password not entered for del.icio.us."];
	}

	private = [settings boolForKey:@"deliciousPrivateEnabled"];
	[deliciousPrivateCheckBox setState:(private ? NSOnState : NSOffState)];

	[self checkWithDelicious:deliciousCheckBox];

	/*
	 * Instapaper
	 */
	BOOL const instapaperEnabled = [settings boolForKey:@"instapaperEnabled"];
	[instapaperCheckBox setState:(instapaperEnabled ? NSOnState : NSOffState)];
	isNotEntered = NO;
	s = [settings stringForKey:@"instapaperUsername"];
	if (s == nil) {
		D0(@"instapaperUsername is nul");
		s = @"";
		if (instapaperEnabled) isNotEntered = YES;
	}
	[instapaperUsernameTextField setStringValue:s];
	s = [settings stringForKey:@"instapaperPassword"];
	if (s == nil) {
		D0(@"instapaperPassword is nul");
		s = @"";
		if (instapaperEnabled) isNotEntered = YES;
	}
	[instapaperPasswordTextField setStringValue:s];
	if (isNotEntered) {
		[GrowlSupport notifyWithTitle:@"Tumblrful" description:@"Username or Password not entered for Instapaper"];
	}
	[self checkWithInstapaper:instapaperCheckBox];

	/*
	 * Yammer
	 */
	BOOL const yammerEnabled = [settings boolForKey:@"yammerEnabled"];
	[yammerCheckBox setState:(yammerEnabled ? NSOnState : NSOffState)];
	isNotEntered = NO;
	s = [settings stringForKey:@"yammerNetwork"];
	if (s == nil) {
		D0(@"yammerNetwork is nul");
		s = @"";
		if (yammerEnabled) isNotEntered = YES;
	}
	[yammerNetworkTextField setStringValue:s];
	if (isNotEntered) {
		[GrowlSupport notifyWithTitle:@"Tumblrful" description:@"Network not entered for Yammer"];
	}

	[self checkWithYammer:yammerCheckBox];
#if 0
	/*
	 * other
	 */
	BOOL useOther = [settings boolForKey:@"otherTumblogEnabled"];
	[otherCheckBox setState:(useOther ? NSOnState : NSOffState)];

	isNotEntered = NO;
	s = [settings stringForKey:@"otherTumblogSiteURL"];
	if (s == nil) {
		D0(@"otherTumblogSiteURL is nul");
		s = @"";
		if (useOther) isNotEntered = YES;
	}
	[otherURLTextField setStringValue:s];
	s = [settings stringForKey:@"otherTumblogLoginName"];
	if (s == nil) {
		D0(@"otherTumblogLoginName is nul");
		s = @"";
		if (useOther) isNotEntered = YES;
	}
	[otherLoginTextField setStringValue:s];

	s = [settings stringForKey:@"otherTumblogPassword"];
	if (s == nil) {
		D0(@"otherTumblogPassword is nul");
		s = @"";
		if (useOther) isNotEntered = YES;
	}
	[otherPasswordTextField setStringValue:s];

	[self checkUseOtherTumblog:otherCheckBox];
#endif

	// openInBackgroundTab
	BOOL boolValue = [settings boolForKey:@"openInBackgroundTab"];
	[openInBackgroundTab setState:(boolValue ? NSOnState : NSOffState)];
}

/// Image to display in the preferences toolbar
- (NSImage *)imageForPreferenceNamed:(NSString *)name
{
#pragma unused (name)
	NSImage * image = [NSImage imageNamed:@"Tumblrful.png"];
	if (image == nil)
		image = [TumblrfulPreferences preloadImage:@"Tumblrful.png"];

	D(@"image: %@", [image description]);
	return image;
}

/// Override to return the name of the relevant nib
- (NSString *) preferencesNibName
{
	return @"TumblrfulPreferences";
}

- (NSView *)viewForPreferenceNamed:(NSString *)aName
{
	return [super viewForPreferenceNamed:aName];
}

/// Called when window closes or "save" button is clicked.
- (void)saveChanges
{
	UserSettings * settings = [UserSettings sharedInstance];

	// Tumblr
	[settings setObject:[emailTextField stringValue] forKey:@"tumblrEmail"];
	[settings setObject:[passwordTextField stringValue] forKey:@"tumblrPassword"];
	[settings setBool:([privateCheckBox state] == NSOnState) forKey:@"tumblrPrivateEnabled"];
	[settings setBool:([queuingCheckBox state] == NSOnState) forKey:@"tumblrQueuingEnabled"];

	// delicious
	[settings setBool:([deliciousCheckBox state] == NSOnState) forKey:@"deliciousEnabled"];
	[settings setObject:[deliciousUsernameTextField stringValue] forKey:@"deliciousUsername"];
	[settings setObject:[deliciousPasswordTextField stringValue] forKey:@"deliciousPassword"];
	[settings setBool:([deliciousPrivateCheckBox state] == NSOnState) forKey:@"deliciousPrivateEnabled"];

	// Instapaper
	[settings setBool:([instapaperCheckBox state] == NSOnState) forKey:@"instapaperEnabled"];
	[settings setObject:[instapaperUsernameTextField stringValue] forKey:@"instapaperUsername"];
	[settings setObject:[instapaperPasswordTextField stringValue] forKey:@"instapaperPassword"];

	// Yammer
	[settings setBool:([yammerCheckBox state] == NSOnState) forKey:@"yammerEnabled"];
	[settings setObject:[yammerNetworkTextField stringValue] forKey:@"yammerNetwork"];

#if 0
	// other
	[settings setBool:([otherCheckBox state] == NSOnState) forKey:@"otherTumblogEnabled"];
	[settings setObject:[otherURLTextField stringValue] forKey:@"otherTumblogSiteURL"];
	[settings setObject:[otherLoginTextField stringValue] forKey:@"otherTumblogLoginName"];
	[settings setObject:[otherPasswordTextField stringValue] forKey:@"otherTumblogPassword"];
#endif

	[settings setBool:([openInBackgroundTab state] == NSOnState) forKey:@"openInBackgroundTab"];

	[settings synchronize];
}

/// Not sure how useful this is, so far always seems to return YES.
- (BOOL)hasChangesPending
{
	return [super hasChangesPending];
}

/// Called when we relinquish ownership of the preferences panel.
- (void)moduleWillBeRemoved
{
	[super moduleWillBeRemoved];
}

/// Called after willBeDisplayed, once we "own" the preferences panel.
- (void)moduleWasInstalled
{
	[super moduleWasInstalled];
}

- (IBAction)checkWithDelicious:(id)sender
{
	if (sender == deliciousCheckBox) {
		NSInteger const state = [deliciousCheckBox state];
		BOOL const enabled = (state == NSOnState ? YES : NO);
		[deliciousUsernameTextField setEnabled:enabled];
		[deliciousPasswordTextField setEnabled:enabled];
		[deliciousPrivateCheckBox setEnabled:enabled];
	}
}

- (IBAction)checkWithInstapaper:(id)sender
{
	if (sender == instapaperCheckBox) {
		NSInteger const state = [instapaperCheckBox state];
		BOOL const enabled = (state == NSOnState ? YES : NO);
		[instapaperUsernameTextField setEnabled:enabled];
		[instapaperPasswordTextField setEnabled:enabled];
	}
}

- (IBAction)checkWithYammer:(id)sender
{
	if (sender == yammerCheckBox) {
		NSInteger const state = [yammerCheckBox state];
		BOOL const enabled = (state == NSOnState ? YES : NO);
		[yammerNetworkTextField setEnabled:enabled];
	}
}

- (IBAction)checkUseOtherTumblog:(id)sender
{
	if (sender == otherCheckBox) {
		NSInteger const state = [otherCheckBox state];
		BOOL const enabled = (state == NSOnState ? YES : NO);
		[otherURLTextField setEnabled:enabled];
		[otherLoginTextField setEnabled:enabled];
		[otherPasswordTextField setEnabled:enabled];
	}
}
@end
