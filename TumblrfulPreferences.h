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

	IBOutlet NSButton* otherCheckBox;
	IBOutlet NSBox* otherBox;
	IBOutlet NSTextField* otherURLTextField;
	IBOutlet NSTextField* otherLoginTextField;
	IBOutlet NSTextField* otherPasswordTextField;
}
- (IBAction)checkWithDelicious:(id)sender;
- (IBAction)checkUseOtherTumblog:(id)sender;
@end
