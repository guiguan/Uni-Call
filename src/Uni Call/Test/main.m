//
//  main.m
//  Test
//
//  Created by Guan Gui on 16/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "RMPhoneFormat.h"
#include "pcre.h"

@implementation NSString (UniCall)

- (BOOL)isValidPhoneNumber:(BOOL)partialMatching
{
    static pcre *re;
    static dispatch_once_t predicate = 0;
    
    dispatch_once(&predicate, ^{
        const char *errstr = NULL;
        int erroffset;
        re = pcre_compile("^(?:\\+ *)?(?:\\( *\\d[\\d*#,; -]*\\)| *\\d[\\d*#,; -]*)+$", 0, &errstr, &erroffset, NULL);
    });
    
    const char *str = [self UTF8String];
    int rc = pcre_exec(re, NULL, str, (int)strlen(str), 0, partialMatching ? PCRE_PARTIAL : 0, NULL, 0);
    
    return rc == 0 || rc == PCRE_ERROR_PARTIAL;
}

- (BOOL)isValidEmail:(BOOL)partialMatching
{
    static pcre *re;
    static dispatch_once_t predicate = 0;

    dispatch_once(&predicate, ^{
        const char *errstr = NULL;
        int erroffset;
        re = pcre_compile("^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$", 0, &errstr, &erroffset, NULL);
    });
    
    const char *str = [self UTF8String];
    int rc = pcre_exec(re, NULL, str, (int)strlen(str), 0, partialMatching ? PCRE_PARTIAL : 0, NULL, 0);
    
    return rc == 0 || rc == PCRE_ERROR_PARTIAL;
}

- (BOOL)isValidWeChatUsername:(BOOL)partialMatching
{
    static pcre *re;
    static dispatch_once_t predicate = 0;
    
    dispatch_once(&predicate, ^{
        const char *errstr = NULL;
        int erroffset;
        // 可以使用6—20个字母、数字、下划线和减号，必须以字母开头
        // http://kf.qq.com/faq/120911VrYVrA1310282MbiaM.html
        re = pcre_compile("^[A-Za-z][A-Za-z0-9_-]{5,19}$", 0, &errstr, &erroffset, NULL);
    });
    
    const char *str = [self UTF8String];
    int rc = pcre_exec(re, NULL, str, (int)strlen(str), 0, partialMatching ? PCRE_PARTIAL : 0, NULL, 0);
    
    return rc == 0 || rc == PCRE_ERROR_PARTIAL;
}

- (BOOL)isValidSkypeUsername:(BOOL)partialMatching
{
    static pcre *re;
    static dispatch_once_t predicate = 0;
    
    dispatch_once(&predicate, ^{
        const char *errstr = NULL;
        int erroffset;
        // Your Skype Name must have between 6 and 32 characters. It must start
        // with a letter and can contain only letters, numbers and the following
        // punctuation marks:
        //    
        //    full stop (.)
        //    comma (,)
        //    dash (-)
        //    underscore (_)
        // https://support.skype.com/en/faq/FA94/what-is-a-skype-name
        re = pcre_compile("^[A-Za-z][A-Za-z0-9.,_-]{5,31}$", 0, &errstr, &erroffset, NULL);
    });
    
    const char *str = [self UTF8String];
    int rc = pcre_exec(re, NULL, str, (int)strlen(str), 0, partialMatching ? PCRE_PARTIAL : 0, NULL, 0);
    
    return rc == 0 || rc == PCRE_ERROR_PARTIAL;
}

@end

@interface Test : NSObject
@end

@implementation Test : NSObject 

- (NSString *)examineString:(NSString *)str toRemovePrefixes:(NSString *)firstPrefix, ...
NS_REQUIRES_NIL_TERMINATION
{
    NSMutableString *result = [str mutableCopy];
    
    va_list args;
    va_start(args, firstPrefix);
    for (NSString *arg = firstPrefix; arg != nil; arg = va_arg(args, NSString *)) {
        if ([result rangeOfString:arg options:(NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound)
            [result deleteCharactersInRange:NSMakeRange(0, arg.length)];
    }
    va_end(args);
    
    return result;
}

@end

int main(int argc, const char * argv[])
{

    @autoreleasepool {
//        NSString *query = @"abc ; \"sdf \" df\" ";
//        NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"([/;,])?\"(.+)\"(?= )|[^ ]+(?= )" options:0 error:nil];
//        NSArray *queryMatches = [re matchesInString:query options:0 range:NSMakeRange(0, [query length])];
//        int count = 0;
//        for (NSTextCheckingResult *tcr in queryMatches) {
//            NSMutableString *result = [NSMutableString stringWithFormat:@"%d\t", count++];
//            for (int i = 0; i < tcr.numberOfRanges; i++) {
//                NSRange curR = [tcr rangeAtIndex:i];
//                [result appendFormat:@"%d->%@ ", i, curR.location != NSNotFound? [query substringWithRange:curR] : @"_"];
//            }
//            NSLog(@"%@", result);
//        }
        
//        NSString *query = @"桂冠  但";
//        NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"^(\\p{script=Han}+ *)+$" options:0 error:nil];
//        NSArray *queryMatches = [re matchesInString:query options:0 range:NSMakeRange(0, [query length])];
//        NSLog(@"%lu", (unsigned long)((NSTextCheckingResult *)queryMatches[0]).numberOfRanges);

//        RMPhoneFormat *fmt = [[RMPhoneFormat alloc] init];
//        NSLog(@"%@", [fmt defaultCallingCode]);
//        NSLog(@"%@", [fmt callingCodeForCountryCode:@"us"]);
//        NSLog(@"%@", [fmt countriesForCallingCode:@"+1"]);
//        NSLog(@"%@", [fmt getSearchStringsForPhoneNumber:@"0433329343"]);
//        NSLog(@"%@", [fmt format:@"0433329343"]);
//        NSLog(@"%@", [fmt getSearchStringsForPhoneNumber:@"0011"]);
//        NSLog(@"%@", [fmt getSearchStringsForPhoneNumber:@"+61433329343"]);
//        NSLog(@"%lu", (unsigned long)[@"1324;," rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@";,"]].length);
        
//        Test *test = [[Test alloc] init];
//        
//        NSLog(@"%@", [test examineString:@"siP:tel:test" toRemovePrefixes:@"Tel:", @"sip:", nil]);
        
        
//        NSLog(@"%d", [@"ab" isValidEmail:YES]);
//        NSLog(@"%d", [@"ab@test.com" isValidEmail:YES]);
//        NSLog(@"%d", [@"ab@test.com" isValidEmail:NO]);
//        NSLog(@"%d", [@"abcjjh?" isValidWeChatUsername:YES]);
//        NSLog(@"%d", [@"abcjjh?" isValidSkypeUsername:YES]);
//        NSLog(@"%d", [@"(  - 2-3- ;)212" isValidPhoneNumber:YES]);

//        //Create a new local notification
//        NSUserNotification *notification = [[NSUserNotification alloc] init];
//        //Set the title of the notification
//        notification.title = @"My Title";
//        //Set the text of the notification
//        notification.informativeText = @"My Text";
//        //Schedule the notification to be delivered 20 seconds after execution
//        notification.deliveryDate = [NSDate dateWithTimeIntervalSinceNow:0];
//        
//        //Get the default notification center and schedule delivery
//        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
        
//        NSUserNotification *notification = [[NSUserNotification alloc] init];
//        notification.title = @"Hello, World!";
//        notification.informativeText = [NSString stringWithFormat:@"details details details"];
//        notification.soundName = NSUserNotificationDefaultSoundName;
//        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        typedef NS_ENUM(NSInteger, ActionStatus)
        {
            ATHasUpdate,
            ATNoUpdate,
            ATFailed,
            ATIdle,
            ATChecking
        };

        NSLog(@"%ld", (long)ATChecking);
        NSLog(@"%ld", (long)ATHasUpdate);
        
        return 0;
    }
}

