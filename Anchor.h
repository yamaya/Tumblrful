/**
 * @file Anchor.h
 * @brief Anchor declaration.
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import <Foundation/Foundation.h>

@interface Anchor : NSObject
{
	NSString* url_;
	NSString* title_;
}
+ (Anchor*) anchorWithURL:(NSString*)url title:(NSString*)title;

- (id) initWithURL:(NSString*)url title:(NSString*)title;
- (void) dealloc;

- (NSString*) URL;
- (void) setURL:(NSString*)url;
- (NSString*) title;
- (void) setTitle:(NSString*)title;

- (NSString*)tag;
@end
