//
//  main.m
//  Uni Call Basestation
//
//  Created by Guan Gui on 9/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "GCDAsyncSocket.h"
#include "NetworkSharedParameters.h"

#define CONNECTION_TIMEOUT 1 // 1 sec

@interface Main : NSObject

@end

@implementation Main

NSDate *connectionStartTime_;
NSString *query_;

-(void)execute:(NSString *)query
{
    query_ = query;
    
    if(system("killall -s \"Uni Call\" > /dev/null 2>&1")) {
        // if Uni Call is not yet launched
        if(system([[[Main workingPath] stringByAppendingString:@"/Uni\\ Call > /dev/null 2>&1 &"] UTF8String])) {
            NSLog(@"Error: cannot launch Uni Call!");
            return;
        }
        [NSThread sleepForTimeInterval:0.01];
    }
    
    GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    connectionStartTime_ = [NSDate date];
    NSError *err = nil;
    if (![socket connectToHost:@"localhost" onPort:PORT_NUM viaInterface:@"localhost" withTimeout:-1 error:&err]) {
        // If there was an error, it's likely something like "already connected" or "no delegate set"
        NSLog(@"Error: %@", err);
        return;
    }
    
    CFRunLoopRun();
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if ([[NSDate date] timeIntervalSince1970] -  [connectionStartTime_ timeIntervalSince1970] <= CONNECTION_TIMEOUT) {
        [sock disconnect];
        [NSThread sleepForTimeInterval:0.01];
        NSError *err = nil;
        if (![sock connectToHost:@"localhost" onPort:PORT_NUM viaInterface:@"localhost" withTimeout:-1 error:&err]) {
            // If there was an error, it's likely something like "already connected" or "no delegate set"
            NSLog(@"Error: %@", err);
            return;
        }
    } else {
        NSLog(@"%@", err);
        [sock disconnect];
        CFRunLoopStop(CFRunLoopGetMain());
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
//    NSLog(@"Time taken: %f", [[NSDate date] timeIntervalSince1970] -  [connectionStartTime_ timeIntervalSince1970]);
    
    NSData *messageBody = [query_ dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger messageLen = [messageBody length];
    
    [sock writeData:[NSData dataWithBytes:&messageLen length:MESSAGE_HEADER_SIZE] withTimeout:-1 tag:MESSAGE_HEADER];
    [sock writeData:messageBody withTimeout:-1 tag:MESSAGE_BODY];
    [sock readDataToLength:MESSAGE_HEADER_SIZE withTimeout:-1 tag:MESSAGE_HEADER];
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
    switch (tag) {
        case MESSAGE_HEADER: {
            NSUInteger messageLen;
            [data getBytes:&messageLen length:MESSAGE_HEADER_SIZE];
            [sender readDataToLength:messageLen withTimeout:-1 tag:MESSAGE_BODY];
            break;
        }
        case MESSAGE_BODY: {
            NSString *results= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            NSLog(@"%@", results);
            [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:[results dataUsingEncoding:NSUTF8StringEncoding]];
            CFRunLoopStop(CFRunLoopGetMain());
            [sender disconnect];
            break;
        }
    }
}

+ (NSString *)workingPath
{
    static NSString *path = nil;
    if (!path) {
        path = [[[NSBundle mainBundle] bundlePath] copy];
    }
    return path;
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
        
//        NSString *query = @"guan";
        
        Main *m = [[Main alloc] init];
        [m execute: query];
    }
    return 0;
}

