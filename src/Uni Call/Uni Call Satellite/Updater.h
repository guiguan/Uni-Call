//
//  Updater.h
//  Uni Call
//
//  Created by Guan Gui on 23/11/2014.
//  Copyright (c) 2014 Guan Gui. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UniCall.h"

typedef NS_ENUM(NSInteger, UpdateActionStatus)
{
    UASHasUpdate,
    UASNoUpdate,
    UASFailed
};

@interface Updater : NSObject

@property NSDictionary *responseObject;

- (instancetype)init:(UniCall *)unicall;

- (void)checkForUpdateAndDeliverNotification:(BOOL)shouldDeliverNotif withCompletion:(void(^)(UpdateActionStatus result))completion;

@end
