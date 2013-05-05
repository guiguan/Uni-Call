//
//  main.m
//  Uni Call
//
//  Created by Guan Gui on 5/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#include "UniCall.h"

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        NSMutableString *query = [NSMutableString string];
        for (int i = 1; i < argc; i++) {
            [query appendFormat:@"%s ", argv[i]];
        }
        NSString *results = [[[UniCall alloc] init] process:query];
//        NSString *results = [[[UniCall alloc] init] process:[NSString stringWithCString:"c" encoding:NSUTF8StringEncoding]];
        [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:[results dataUsingEncoding:NSUTF8StringEncoding]];
//        NSLog(@"%@: %@", query, results);
    }
    
    return 0;
}

