//
//  main.m
//  Test
//
//  Created by Guan Gui on 16/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGMutableDictionary.h"

@implementation NSString (UniCall)

- (NSArray *)composedCharacterRanges
{
    NSMutableArray *ranges = [NSMutableArray array];
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        [ranges addObject:[NSValue valueWithRange:substringRange]];
    }];
    return ranges;
}

@end

int main(int argc, const char * argv[])
{
    @autoreleasepool {
//        NSString *test = @"훙길동";
        NSString *test = @"韓國";
        NSArray *ranges = [test composedCharacterRanges];
        for (NSValue *v in ranges) {
            NSRange range = v.rangeValue;
            NSLog(@"%lu %lu", range.location, range.length);
        }
        NSLog(@"%@", [test precomposedStringWithCanonicalMapping]);
//        NSLog(@"%lu %lu", [test rangeOfComposedCharacterSequenceAtIndex:1].location, [test rangeOfComposedCharacterSequenceAtIndex:1].length);
//        NSLog(@"%lu", [@"훙길동" compare:test]);
        return 0;
    }
}

