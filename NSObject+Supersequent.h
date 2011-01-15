#import <Foundation/Foundation.h>

extern IMP impOfCallingMethod(id lookupObject, SEL selector);

@interface NSObject (SupersequentAdditional)
- (IMP)getImplementationOf:(SEL)lookup after:(IMP)skip;
@end

#define invokeSupersequent(...) \
	([self getImplementationOf:_cmd after:impOfCallingMethod(self, _cmd)]) \
	(self, _cmd, ##__VA_ARGS__)

#define invokeSupersequentNoParameters() \
	([self getImplementationOf:_cmd after:impOfCallingMethod(self, _cmd)]) \
	(self, _cmd)

