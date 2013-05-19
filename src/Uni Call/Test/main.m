//
//  main.m
//  Test
//
//  Created by Guan Gui on 16/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        NSLog(@"%@", CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)@"<item uid=\"\"\" arg=\"[CTSkype]\"\" autocomplete=\"\"\"><title>\"</title><subtitle>Skype call to: \" (unidentified in Apple Contacts)</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>", NULL));
    }
    return 0;
}

