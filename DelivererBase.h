/**
 * @file DelivererBase.h
 * @brief DelivererBase declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
#import "Deliverer.h"
#import "DelivererContext.h"
#import "PostCallback.h"

/**
 * DeliverBase abstract class
 */
@interface DelivererBase : NSObject <Deliverer, PostCallback>
{
	DelivererContext* context_;
	NSUInteger filterMask_;
}

/* Deliverer protocols */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement;
- (NSMenuItem*) createMenuItem;
- (void) action:(id)sender;

/* common process for PostCallback */
- (void) posted:(NSData*)response;
- (void) failed:(NSError*)error;

- (id) initWithDocument:(DOMHTMLDocument*)document target:(NSDictionary*)clickedElement;
- (void) dealloc;
- (void) postLink:(NSString*)url title:(NSString*)title;
- (void) postQuote:(NSString*)text;
- (void) postPhoto:(NSString*)imageURL caption:(NSString*)caption through:(NSString*)url;
- (void) postVideo:(NSString*)embed title:(NSString*)title caption:(NSString*)caption;
- (NSObject*) postEntry:(NSDictionary*)params;

/* PostCallback overrides */
- (void) successed:(NSString*)response;
- (void) failedWithError:(NSError*)error;
- (void) failedWithException:(NSException*)exception;

- (NSString*) titleForMenuItem;
- (void) notify:(NSString*)message;
- (void) failedWithException:(NSException*)exception;

- (NSArray*) createMenuItems;

- (void) actionWithMask:(NSArray*)param;
@end
