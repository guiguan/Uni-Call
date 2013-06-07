//
//  main.m
//  Test
//
//  Created by Guan Gui on 16/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        CFURLRef appURL = NULL;
		OSStatus result = LSFindApplicationForInfo (
                                                    kLSUnknownCreator,         //creator codes are dead, so we don't care about it
                                                    CFSTR("com.calltrunk.CallTrunk-UK"), //you can use the bundle ID here
                                                    NULL,                      //or the name of the app here (CFSTR("Safari.app"))
                                                    NULL,                      //this is used if you want an FSRef rather than a CFURLRef
                                                    &appURL
                                                    );
		switch(result)
		{
		    case noErr:
		        NSLog(@"the app's URL is: %@",appURL);
		        break;
		    case kLSApplicationNotFoundErr:
		        NSLog(@"app not found");
		        break;
		    default:
		        NSLog(@"an error occurred: %d",result);
		        break;
		}
        
		//the CFURLRef returned from the function is retained as per the docs so we must release it
		if(appURL)
		    CFRelease(appURL);
    }
    return 0;
}

