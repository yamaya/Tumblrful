#import "Log.h"

#ifdef DEBUG
/**
 * @macro D
 */
#define D(fmt, ...)	Log((@"%s[line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define D0(ns)		Log((@"%s[line %d] %@"), __PRETTY_FUNCTION__, __LINE__, ns)

/**
 * @macro D_METHOD
 */
#define D_METHOD		Log(@"%s", __func__)

/**
 * @macro D_ELAPSE_BEGIN
 */
#define D_ELAPSE_BEGIN(var) \
		NSDate * var##_start = [NSDate new]

/**
 * @macro D_ELAPSE_END
 */
#define D_ELAPSE_END(var)	\
		NSDate * var##_end = [NSDate new]; \
		Log(@"%s elapse time(sec): %f", #var, [var##_end timeIntervalSinceDate:var##_start]); \
		[var##_start release];\
		[var##_end release]

/**
 * @macro D_ASSERT_NIL
 */
#define D_ASSERT_NIL(exp)	NSAssert(exp, @"must be not nil");

#else
#define D(fmt, ...)
#define D0(ns)
#define D_METHOD
#define D_ELAPSE_BEGIN(var)
#define D_ELAPSE_END(var)
#define D_ASSERT_NIL(exp)
#endif /* DEBUG */
