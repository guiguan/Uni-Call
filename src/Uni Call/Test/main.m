//
//  main.m
//  Test
//
//  Created by Guan Gui on 16/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGMutableDictionary.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        GGMutableDictionary *dict = [[GGMutableDictionary alloc] initWithCapacity:10];
        dict[@"test"] = @"sfds";
        [dict writeToFile:@"test.txt" atomically:true];
        NSLog(@"%@", dict);
        return 0;
    }
}

