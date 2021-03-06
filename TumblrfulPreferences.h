/**
 * @file TumblrfulPreferences.h
 * @brief TumblrfulPreferences declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import <Cocoa/Cocoa.h>
#import "NSPreferenceModule.h"

@interface TumblrfulPreferences : NSPreferencesModule
{
	IBOutlet NSTextField* authorTextField;
	IBOutlet NSTextField* emailTextField;
	IBOutlet NSTextField* passwordTextField;
	IBOutlet NSButton* privateCheckBox;
	IBOutlet NSButton * queuingCheckBox;

	IBOutlet NSButton* deliciousCheckBox;
	IBOutlet NSBox* deliciousBox;
	IBOutlet NSTextField* deliciousUsernameTextField;
	IBOutlet NSTextField* deliciousPasswordTextField;
	IBOutlet NSButton* deliciousPrivateCheckBox;

	IBOutlet NSButton * instapaperCheckBox;
	IBOutlet NSBox * instapaperBox;
	IBOutlet NSTextField * instapaperUsernameTextField;
	IBOutlet NSTextField * instapaperPasswordTextField;

	IBOutlet NSButton * yammerCheckBox;
	IBOutlet NSBox * yammerBox;
	IBOutlet NSTextField * yammerNetworkTextField;

	IBOutlet NSButton* otherCheckBox;
	IBOutlet NSBox* otherBox;
	IBOutlet NSTextField* otherURLTextField;
	IBOutlet NSTextField* otherLoginTextField;
	IBOutlet NSTextField* otherPasswordTextField;
	
	IBOutlet NSButton * openInBackgroundTab;
}

/// action that select checkbox for 'Use delicious'
- (IBAction)checkWithDelicious:(id)sender;

/// action that select checkbox for 'Use Instapaper'
- (IBAction)checkWithInstapaper:(id)sender;

/// action that select checkbox for 'Use Yammer'
- (IBAction)checkWithYammer:(id)sender;

/// action that select checkbox for 'Use other tumblog'
- (IBAction)checkUseOtherTumblog:(id)sender;
@end
