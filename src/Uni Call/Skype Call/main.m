//
//  main.m
//  Skype Call
//
//  Created by Guan Gui on 13/06/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Skype/Skype.h"

#import "UniCall.h"

#define TIME_OUT 90

typedef NS_OPTIONS(NSInteger, ResponseType)
{
    RTNil,
    RTSelfOnlineStatus,
    RTUserOnlineStatus
};

NSString* const cMyApplicationName = @"Uni Call";

@interface Main : NSObject <SkypeAPIDelegate>

@end

@implementation Main

BOOL shouldKeepRunning_ = YES;
ResponseType expectResponse_ = RTNil;
NSString *query_ = nil;

- (id)init
{
    self = [super init];
    if (self) {
        [SkypeAPI setSkypeDelegate:self];
    }
    return self;
}

- (void)execute:(NSString *)query
{
    if ([query hasPrefix:@"[STATUS]"]) {
        if ([SkypeAPI isSkypeAvailable]) {
            query_ = [query substringFromIndex:8];
            expectResponse_ = RTUserOnlineStatus;
            [SkypeAPI connect];
        } else {
            printf("0");
            return;
        }
    } else {
        query_ = [[query componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"() "]] componentsJoinedByString:@""];
        expectResponse_ = RTSelfOnlineStatus;
        
        if (![SkypeAPI isSkypeRunning]) {
            shouldKeepRunning_ = [[NSWorkspace sharedWorkspace] launchApplication:@"Skype"];
        } else {
            [SkypeAPI connect];
        }
    }
    
    if (shouldKeepRunning_)
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, TIME_OUT, false);
}

- (NSString*)clientApplicationName
{
	return cMyApplicationName;
}

#pragma Optional Delegate Methods

- (void)skypeNotificationReceived:(NSString*)aNotificationString
{
    if (expectResponse_ == RTUserOnlineStatus) {
        if ([aNotificationString hasSuffix:@"ONLINESTATUS ONLINE"]) {
            printf("1");
            
            expectResponse_ = RTNil;
            [SkypeAPI disconnect];
            shouldKeepRunning_ = NO;
            CFRunLoopStop(CFRunLoopGetMain());
        } else if ([aNotificationString hasSuffix:@"ONLINESTATUS OFFLINE"]) {
            printf("0");
            
            expectResponse_ = RTNil;
            [SkypeAPI disconnect];
            shouldKeepRunning_ = NO;
            CFRunLoopStop(CFRunLoopGetMain());
        }
    } else if (expectResponse_ == RTSelfOnlineStatus) {
        if ([aNotificationString isEqualToString:@"USERSTATUS OFFLINE"]) {
            [SkypeAPI sendSkypeCommand:@"SET USERSTATUS ONLINE"];
            expectResponse_ = RTSelfOnlineStatus;
        } else if ([aNotificationString isEqualToString:@"CONNSTATUS ONLINE"]) {
            expectResponse_ = RTNil;
            
            [SkypeAPI sendSkypeCommand:[NSString stringWithFormat:@"CALL %@", query_]];
            
            [SkypeAPI disconnect];
            shouldKeepRunning_ = NO;
            CFRunLoopStop(CFRunLoopGetMain());
        }
    }
    
//    NSLog(@"%@", aNotificationString);
}


- (void)skypeAttachResponse:(unsigned)aAttachResponseCode
{
    NSString *errorType = @"Skype Call Initialisation Error";
	switch (aAttachResponseCode)
	{
		case 0:
            [UniCall pushNotificationWithTitle:cMyApplicationName andMessage:errorType andDetail:@"Failed to connect. Please make sure you have logged in and allowed Uni Call to operate from Skype>Manage API Clients..."];
            shouldKeepRunning_ = NO;
            CFRunLoopStop(CFRunLoopGetMain());
			break;
		case 1:{
            switch (expectResponse_) {
                case RTUserOnlineStatus:
                    [SkypeAPI sendSkypeCommand:[NSString stringWithFormat:@"GET USER %@ ONLINESTATUS", query_]];
                    break;
                case RTSelfOnlineStatus:
                    [SkypeAPI sendSkypeCommand:@"GET USERSTATUS"];
                    break;
                default:
                    break;
            }
			break;
        }
		default:
            [UniCall pushNotificationWithTitle:cMyApplicationName andMessage:errorType andDetail:@"Unknown response from Skype. Please contact the author of Uni Call"];
            shouldKeepRunning_ = NO;
            CFRunLoopStop(CFRunLoopGetMain());
			break;
	}
	
}

- (void)skypeBecameAvailable:(NSNotification*)aNotification
{
    [SkypeAPI connect];
}

@end

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSMutableString *query = [NSMutableString string];
        for (int i = 1; i < argc; i++) {
            [query appendFormat:@"%@ ", [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
        }
        
        if ([query isEqualToString:@""])
            return 0;
        
        Main *m = [[Main alloc] init];
        [m execute: query];
    }
    return 0;
}

