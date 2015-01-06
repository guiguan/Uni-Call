//
//  UniCall.h
//  Uni Call
//
//  Created by Guan Gui on 2/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GGMutableDictionary.h"

@interface UniCall : NSObject

@property GGMutableDictionary *config;

+ (NSString *)version;
+ (void)pushNotificationWithOptions:(NSDictionary *)options;

- (NSString *)process:(NSString *)query;
- (NSString *)uniCallBasestationPath;
- (void)saveConfig;

@end
