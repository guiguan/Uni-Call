//
//  Updater.m
//  Uni Call
//
//  Created by Guan Gui on 16/01/2015.
//  Copyright (c) 2014 Guan Gui. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>

#import "Updater.h"

@implementation Updater {
    AFHTTPRequestOperationManager *httpManager_;
    UniCall * __weak unicall_;
}

@synthesize responseObject = responseObject_;

- (instancetype)init:(UniCall *)unicall
{
    self = [super init];
    if (self) {
        httpManager_ = [AFHTTPRequestOperationManager manager];
        httpManager_.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        httpManager_.requestSerializer = [AFJSONRequestSerializer serializer];
        httpManager_.responseSerializer = [AFJSONResponseSerializer serializer];
        unicall_ = unicall;
        responseObject_ = unicall_.config[@"autoUpdateCheckingResponseObject"];
    }
    return self;
}

- (void)checkForUpdateAndDeliverNotification:(BOOL)shouldDeliverNotif withCompletion:(void(^)(UpdateActionStatus result))completion
{
    unicall_.config[@"autoUpdateCheckingLastStartTime"] = [NSDate date];
    [unicall_ saveConfig];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [httpManager_ POST:@"https://unicall.guiguan.net/checkforupdate.php" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            UpdateActionStatus status = -1;
            if ([responseObject[@"version"] doubleValue] > [[UniCall version] doubleValue]) {
                status = UASHasUpdate;
                responseObject_ = responseObject;
                unicall_.config[@"autoUpdateCheckingResponseObject"] = responseObject_;
                if (shouldDeliverNotif) {
                    [UniCall pushNotificationWithOptions:@{@"title": @"New version available",
                                                           @"message": [NSString stringWithFormat:@"A new version (v%@) of Uni Call is available. Click me to upgrade.", responseObject[@"version"]],
                                                           @"sound": @"Ping",
                                                           @"group": @"checkingForUpdate",
                                                           @"execute": [NSString stringWithFormat:@"'%@' --[Update]", [unicall_ uniCallBasestationPath]]}];
                }
            } else {
                status = UASNoUpdate;
                responseObject_ = nil;
                [unicall_.config removeObjectForKey:@"autoUpdateCheckingResponseObject"];
            }
            [unicall_ saveConfig];
            if (completion) {
                completion(status);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Checking for update failed: %@", [error localizedDescription]);
            responseObject_ = nil;
            [unicall_.config removeObjectForKey:@"autoUpdateCheckingResponseObject"];
            [unicall_ saveConfig];
            if (completion) {
                completion(UASFailed);
            }
        }];
    });
}

@end