#include <stdio.h>
#include "Log.h"

static bool gEnable = false;

/// enable/disable Loggging
void LogEnable(bool enable)
{
	gEnable = enable;
}

/// Log
void Log(NSString* format, ...)
{
	static FILE* fp = NULL;

	if (gEnable) {
		if (fp == NULL) {
			fp = fopen("/tmp/Tumblrful.log", "w");
		}

		va_list args;
		va_start(args, format);

		NSString* msg = [[NSString alloc] initWithFormat:format arguments:args];
		fputs([[NSString stringWithFormat:@"%@\n", msg] UTF8String], fp);
		[msg release];

		va_end(args);

		fflush(fp);
	}
}

/// SafetyDescription
NSString* SafetyDescription(NSObject* obj)
{
	return obj != nil ? [obj description] : @"(nil)";
}
