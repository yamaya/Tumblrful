/**
 * @file TumblrfulPreferences.m
 * @brief TumblrfulPreferences implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "TumblrfulPreferences.h"
#import "GrowlSupport.h"
#import "Log.h"

#define V(format, ...)	Log(format, __VA_ARGS__)
//#define V(format, ...)

static NSString* BUNDLE_ID = @"com.tumblr.do-nothing.Tumblrful.bundle";

@implementation TumblrfulPreferences
/**
 * preloadImage
 */
+ (NSImage*) preloadImage:(NSString*)name
{
	NSString* imagePath = [[NSBundle bundleWithIdentifier:BUNDLE_ID] pathForImageResource:name];
	V(@"imagePath=%@", imagePath);
	if (imagePath == nil) {
		NSLog(@"imagePath for %@ is nil", name);
		return nil;
	}

	NSImage* image = [[NSImage alloc] initByReferencingFile:imagePath];
	if (image == nil) {
		NSLog(@"image for %@ is nil", name);
		return nil;
	}

	[image setName:name];
	return image;
}

/**
 * awakeFromNib
 */
- (void) awakeFromNib
{
	NSDictionary* infoDictionary = [[NSBundle bundleWithIdentifier:BUNDLE_ID] infoDictionary];

	[authorTextField setStringValue:
		[NSString stringWithFormat:[authorTextField stringValue],
			[infoDictionary objectForKey:@"CFBundleShortVersionString"],
			[infoDictionary objectForKey:@"CFBundleVersion"]]];

	NSUserDefaults* defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
	
	BOOL isNotEntered = NO;
	NSString* s;
	BOOL private = NO, queuing = NO;
	s = [defaults stringForKey:@"TumblrfulEmail"];
	if (s == nil) {
		Log(@"TumblrfulEmail is nul");
		s = @"";
		isNotEntered = YES;
	}
	[emailTextField setStringValue:s];

	s = [defaults stringForKey:@"TumblrfulPassword"];
	if (s == nil) {
		Log(@"TumblrfulPassword is nul");
		s = @"";
		isNotEntered = YES;
	}
	[passwordTextField setStringValue:s];

	if (isNotEntered) {
		[GrowlSupport notify:@"Tumblrful" description:@"Email or Password not entered."];
	}

	private = [defaults boolForKey:@"TumblrfulPrivate"];
	[privateCheckBox setState:(private ? NSOnState : NSOffState)];

	queuing = [defaults boolForKey:@"TumblrfulQueuing"];
	[queuingCheckBox setState:(queuing ? NSOnState : NSOffState)];

	/*
	 * del.icio.us
	 */
	BOOL withDelicious = [defaults boolForKey:@"TumblrfulWithDelicious"];
	[deliciousCheckBox setState:(withDelicious ? NSOnState : NSOffState)];

	isNotEntered = NO;

	s = [defaults stringForKey:@"TumblrfulDeliciousUsername"];
	if (s == nil) {
		Log(@"TumblrfulDeliciousUsername is nul");
		s = @"";
		if (withDelicious) isNotEntered = YES;		
	}
	[deliciousUsernameTextField setStringValue:s];

	s = [defaults stringForKey:@"TumblrfulDeliciousPassword"];
	if (s == nil) {
		Log(@"TumblrfulDeliciousPassword is nul");
		s = @"";
		if (withDelicious) isNotEntered = YES;		
	}
	[deliciousPasswordTextField setStringValue:s];

	if (isNotEntered) {
		[GrowlSupport notify:@"Tumblrful" description:@"Username or Password not entered for del.icio.us."];
	}

	private = [defaults boolForKey:@"TumblrfulDeliciousPrivate"];
	[deliciousPrivateCheckBox setState:(private ? NSOnState : NSOffState)];

	[self checkWithDelicious:deliciousCheckBox];

	/*
	 * other
	 */
	BOOL useOther = [defaults boolForKey:@"TumblrfulUseOtherTumblog"];
	[otherCheckBox setState:(useOther ? NSOnState : NSOffState)];

	isNotEntered = NO;
	s = [defaults stringForKey:@"TumblrfulOtherTumblogSiteURL"];
	if (s == nil) {
		Log(@"TumblrfulOtherTumblogSiteURL is nul");
		s = @"";
		if (useOther) isNotEntered = YES;		
	}
	[otherURLTextField setStringValue:s];

	s = [defaults stringForKey:@"TumblrfulOtherTumblogLogin"];
	if (s == nil) {
		Log(@"TumblrfulOtherTumblogLogin is nul");
		s = @"";
		if (useOther) isNotEntered = YES;		
	}
	[otherLoginTextField setStringValue:s];

	s = [defaults stringForKey:@"TumblrfulOtherTumblogPassword"];
	if (s == nil) {
		Log(@"TumblrfulOtherTumblogPassword is nul");
		s = @"";
		if (useOther) isNotEntered = YES;		
	}
	[otherPasswordTextField setStringValue:s];

	[self checkUseOtherTumblog:otherCheckBox];
}

/**
 * Image to display in the preferences toolbar
 */
- (NSImage*) imageForPreferenceNamed:(NSString *)name
{
	NSImage* image = [NSImage imageNamed:@"Tumblrful.png"];
	if (image == nil)
		image = [TumblrfulPreferences preloadImage:@"Tumblrful.png"];

	V(@"image: %@", [image description]);
	return image;
}

/**
 * Override to return the name of the relevant nib
 */
- (NSString*) preferencesNibName
{
	return @"TumblrfulPreferences";
}

#if 0
- (void) didChange
{
	[super didChange];
}
#endif

- (NSView*) viewForPreferenceNamed:(NSString*)aName
{
	return [super viewForPreferenceNamed:aName];
}

#if 0
/**
 * Called when switching preference panels.
 */
- (void) willBeDisplayed
{
}
#endif

/**
 * Called when window closes or "save" button is clicked.
 */
- (void) saveChanges
{
	NSUserDefaults* defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];

	[defaults setObject:[emailTextField stringValue] forKey:@"TumblrfulEmail"];
	[defaults setObject:[passwordTextField stringValue] forKey:@"TumblrfulPassword"];
	[defaults setBool:[privateCheckBox state] forKey:@"TumblrfulPrivate"];
	[defaults setBool:[queuingCheckBox state] forKey:@"TumblrfulQueuing"];
	// del.icio.us
	[defaults setBool:[deliciousCheckBox state] forKey:@"TumblrfulWithDelicious"];
	[defaults setObject:[deliciousUsernameTextField stringValue] forKey:@"TumblrfulDeliciousUsername"];
	[defaults setObject:[deliciousPasswordTextField stringValue] forKey:@"TumblrfulDeliciousPassword"];
	[defaults setBool:[deliciousPrivateCheckBox state] forKey:@"TumblrfulDeliciousPrivate"];
	// other
	[defaults setBool:[otherCheckBox state] forKey:@"TumblrfulUseOtherTumblog"];
	[defaults setObject:[otherURLTextField stringValue] forKey:@"TumblrfulOtherTumblogSiteURL"];
	[defaults setObject:[otherLoginTextField stringValue] forKey:@"TumblrfulOtherTumblogLogin"];
	[defaults setObject:[otherPasswordTextField stringValue] forKey:@"TumblrfulOtherTumblogPassword"];

	[defaults synchronize];

	Log(@"saveChanges");
}

/**
 * Not sure how useful this is, so far always seems to return YES.
 */
- (BOOL) hasChangesPending
{
	return [super hasChangesPending];
}

/**
 * Called when we relinquish ownership of the preferences panel.
 */
- (void)moduleWillBeRemoved
{
	[super moduleWillBeRemoved];
}

/**
 * Called after willBeDisplayed, once we "own" the preferences panel.
 */
- (void)moduleWasInstalled
{
	[super moduleWasInstalled];
}

/**
 */
- (IBAction)checkWithDelicious:(id)sender
{
	if (sender == deliciousCheckBox) {
		NSInteger state = [deliciousCheckBox state];
		BOOL enabled = (state == NSOnState ? YES : NO);
		[deliciousUsernameTextField setEnabled:enabled];
		[deliciousPasswordTextField setEnabled:enabled];
	}
}

/**
 * action that select checkbox for 'Use other tumblog'
 */
- (IBAction)checkUseOtherTumblog:(id)sender
{
	if (sender == otherCheckBox) {
		NSInteger state = [otherCheckBox state];
		BOOL enabled = (state == NSOnState ? YES : NO);
		[otherURLTextField setEnabled:enabled];
		[otherLoginTextField setEnabled:enabled];
		[otherPasswordTextField setEnabled:enabled];
	}
}
@end
