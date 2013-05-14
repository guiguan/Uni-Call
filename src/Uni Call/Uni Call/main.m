//
//  main.m
//  Uni Call
//
//  Created by Guan Gui on 14/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#include "UniCall.h"
#include "GCDAsyncSocket.h"
#include "NetworkSharedParameters.h"

#define IDLE_TIMEOUT 300 // 5 min

@interface Main : NSObject
    
@end

@implementation Main

CFRunLoopTimerRef idleTimer_ = nil;
GCDAsyncSocket *socket_;

-(void)execute
{
    GCDAsyncSocket *listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    if (![listenSocket acceptOnInterface:@"localhost" port:PORT_NUM error:&error])
    {
        NSLog(@"Error: %@", error);
    }
    
    [self refreshIdleTimer];
    CFRunLoopRun();
    [listenSocket disconnect];
}

void idleTimeout (CFRunLoopTimerRef timer, void *info) {
    CFRunLoopStop(CFRunLoopGetMain());
}

- (void)refreshIdleTimer
{
    CFAbsoluteTime nextFireTime = CFDateGetAbsoluteTime((CFDateRef)[NSDate dateWithTimeIntervalSinceNow:IDLE_TIMEOUT]);
    
    if (idleTimer_) {
        CFRunLoopTimerSetNextFireDate(idleTimer_, nextFireTime);
    } else {
        idleTimer_ = CFRunLoopTimerCreate(NULL, nextFireTime, 0, 0, 0, idleTimeout, NULL);
        CFRunLoopAddTimer(CFRunLoopGetMain(), idleTimer_, kCFRunLoopDefaultMode);
    }
}

- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    [self refreshIdleTimer];
    
    socket_ = newSocket;

    [socket_ readDataToLength:MESSAGE_HEADER_SIZE withTimeout:-1 tag:MESSAGE_HEADER];
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
            NSString *query= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
//            NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
            static UniCall *uniCall = nil;
            if (!uniCall)
                uniCall = [[UniCall alloc] init];
            NSString *results = [uniCall process:query];
//            NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
//            NSLog(@"%@: %lf", query, endTime - startTime);
            
            NSData *messageBody = [results dataUsingEncoding:NSUTF8StringEncoding];
            NSUInteger messageLen = [messageBody length];
            [sender writeData:[NSData dataWithBytes:&messageLen length:MESSAGE_HEADER_SIZE] withTimeout:-1 tag:MESSAGE_HEADER];
            [sender writeData:messageBody withTimeout:-1 tag:MESSAGE_BODY];
            
            break;
        }
    }
}

@end

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        Main *m = [[Main alloc] init];
        [m execute];
        
//        UniCall *uc = [[UniCall alloc] init];
//        NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
//        NSTimeInterval endTime;
//        NSString *results;
//
//        results = [uc process:@"g g"];
//        endTime = [[NSDate date] timeIntervalSince1970];
//        NSLog(@"Comp time: %lf", endTime - startTime);
//        NSLog(@"%@", results);
    }
    
    return 0;
}

