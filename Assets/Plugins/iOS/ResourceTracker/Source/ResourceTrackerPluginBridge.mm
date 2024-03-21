#import <Foundation/Foundation.h>
#include "UnityFramework/UnityFramework-Swift.h"

char* stringCopy (const char* string)
{
	char* res = (char*) malloc(strlen(string) + 1);
	strcpy(res, string);
	return res;
}

extern "C" {
    
#pragma mark - Functions
    
    const void _startTracking()
    {
        if (@available(iOS 13.0, *)) {
            [[ResourceTrackerPlugin instance] StartTracking];
        }
    }

    const char* _stopTracking()
    {
        if (@available(iOS 13.0, *)) {
            NSString *output = [[ResourceTrackerPlugin instance] StopTracking];
            return stringCopy([output UTF8String]);
        } else {
            return "Tracking plugin is only available on iOS 13.0 or newer";
        }
    }
}