#define VERSION @"6.0"
//#define GENERATE_DEFAULT_THUMBNAILS 1
//
//  UniCall.m
//  Uni Call
//
//  Created by Guan Gui on 19/05/13.
//  Last modified by Guan Gui on 23/11/14.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>

#import "RMPhoneFormat.h"
#import "PinYin4Objc.h"
#import "pcre.h"
#import "UniCall.h"
#import "Updater.h"

#define IDENTIFIER @"net.guiguan.Uni-Call"
#define THUMBNAIL_CACHE_LIFESPAN 604800 // 1 week time
#define PREPOPULATE_IM_STATUS_INTERVAL 60 // sec
#define RESULT_NUM_LIMIT 20

#define CALLTYPE_BOUNDARY_LOW 5
#define CALLTYPE_BOUNDARY_HIGH 16
typedef NS_OPTIONS(NSInteger, CallType)
{
    CTNoThumbnailCache              = 1 << 0,
    CTBuildFullThumbnailCache       = 1 << 1,
    CTAudioCall                     = 1 << 2,
    CTVideoCall                     = 1 << 3,
    CTText                          = 1 << 4,
///////////////////////////////////////////////
    CTSkype                         = 1 << CALLTYPE_BOUNDARY_LOW,
    CTFaceTime                      = 1 << 6,
    CTPhoneAmego                    = 1 << 7,
    CTSIP                           = 1 << 8,
    CTPushDialer                    = 1 << 9,
    CTGrowlVoice                    = 1 << 10,
    CTCallTrunk                     = 1 << 11,
    CTFritzBox                      = 1 << 12,
    CTDialogue                      = 1 << 13,
    CTIPhone                        = 1 << 14,
    CTMessages                      = 1 << 15,
    CTWeChat                        = 1 << CALLTYPE_BOUNDARY_HIGH
};

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

- (NSString *)stringByReplacingSpacesWithNonBreakingSpaces
{
    return [self stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
}

- (NSString *)stringByRemovingPrefixes:(NSString *)firstPrefix, ...
NS_REQUIRES_NIL_TERMINATION
{
    NSMutableString *result = [self mutableCopy];
    
    va_list args;
    va_start(args, firstPrefix);
    for (NSString *arg = firstPrefix; arg != nil; arg = va_arg(args, NSString *)) {
        if ([result rangeOfString:arg options:(NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound)
            [result deleteCharactersInRange:NSMakeRange(0, arg.length)];
    }
    va_end(args);
    
    return result;
}

- (NSString *)stringByRemovingSuffixes:(NSString *)firstSuffix, ...
NS_REQUIRES_NIL_TERMINATION
{
    NSMutableString *result = [self mutableCopy];
    
    va_list args;
    va_start(args, firstSuffix);
    for (NSString *arg = firstSuffix; arg != nil; arg = va_arg(args, NSString *)) {
        if ([result rangeOfString:arg options:(NSAnchoredSearch | NSBackwardsSearch | NSCaseInsensitiveSearch)].location != NSNotFound)
            [result deleteCharactersInRange:NSMakeRange(result.length - arg.length, arg.length)];
    }
    va_end(args);
    
    return result;
}

@end

@implementation UniCall

static CallType sAudioCallTypes = CTSkype | CTFaceTime | CTPhoneAmego | CTSIP | CTPushDialer | CTGrowlVoice | CTCallTrunk | CTFritzBox | CTDialogue | CTIPhone;
static CallType sVideoCallTypes = CTSkype | CTFaceTime;
static CallType sTextCallTypes = CTSkype | CTGrowlVoice | CTMessages | CTWeChat;
static CallType sNonSearchableOptions;
static CallType sAllCallTypes;
static NSArray *sCallTypeDefault;
static NSDictionary *sCallType2ComponentCode;
static NSDictionary *sComponentCode2CallType;
static NSDictionary *sCallType2Names;
static NSDictionary *sCallModifier2Desc;
static NSArray *sIMIndex2IMStatus;
static NSMutableDictionary *sIMStatusBuffer = nil;
static NSSize sThumbnailSize;
static NSSet *sFaceTimeNominatedLabels;
static NSSet *sMessagesNominatedLabels;
static NSSet *sMessagesGtalkLabels;
static NSSet *sWeChatLabels;
static NSMutableSet *sReservedPhoneLabels;

Updater *updater_;
NSMutableDictionary *config_; // don't assume config.plist has necessary components
CallType enabledCallType_;
CallType callType_;
NSMutableArray *callTypes_;
NSMutableArray *callModifiers_;
NSMutableString *callTypeDefaultOrder_;
NSString *extraParameter_;
NSMutableArray *extraPhoneNumberExtensionsAfter_;
NSMutableArray *extraPhoneNumberExtensionsBefore_;
BOOL hasGeneratedOutputsForFirstContact_;
BOOL hasStartedSettingUp_ = YES;
BOOL isInProcessOfSettingUp_ = NO;
BOOL hasSettingUpSucceeded = YES;
BOOL isNewUser_ = NO;

- (CallType)getSetValueForCallModifier:(CallType)ct
{
    switch (ct) {
        case CTAudioCall:
            return sAudioCallTypes;
        case CTVideoCall:
            return sVideoCallTypes;
        case CTText:
            return sTextCallTypes;
        default:
            return ct;
    }
}

+ (void)initialize
{
    sNonSearchableOptions = (1 << CALLTYPE_BOUNDARY_LOW) - 1;
    sAllCallTypes = (1 << (CALLTYPE_BOUNDARY_HIGH + 1)) - 1 - sNonSearchableOptions;
    sCallTypeDefault = @[[NSNumber numberWithInteger:CTIPhone],
                         [NSNumber numberWithInteger:CTMessages],
                         [NSNumber numberWithInteger:CTFaceTime],
                         [NSNumber numberWithInteger:CTSkype],
                         [NSNumber numberWithInteger:CTPhoneAmego],
                         [NSNumber numberWithInteger:CTGrowlVoice],
                         [NSNumber numberWithInteger:CTWeChat],
                         [NSNumber numberWithInteger:CTSIP],
                         [NSNumber numberWithInteger:CTFritzBox],
                         [NSNumber numberWithInteger:CTCallTrunk],
                         [NSNumber numberWithInteger:CTPushDialer],
                         [NSNumber numberWithInteger:CTDialogue]];
    sCallType2ComponentCode = @{[NSNumber numberWithInteger:CTAudioCall] : @"_",
                                [NSNumber numberWithInteger:CTVideoCall] : @"+",
                                [NSNumber numberWithInteger:CTText] : @"=",
                                [NSNumber numberWithInteger:CTSkype] : @"s",
                                [NSNumber numberWithInteger:CTFaceTime] : @"f",
                                [NSNumber numberWithInteger:CTPhoneAmego] : @"p",
                                [NSNumber numberWithInteger:CTSIP] : @"i",
                                [NSNumber numberWithInteger:CTPushDialer] : @"d",
                                [NSNumber numberWithInteger:CTGrowlVoice] : @"g",
                                [NSNumber numberWithInteger:CTCallTrunk] : @"k",
                                [NSNumber numberWithInteger:CTFritzBox] : @"z",
                                [NSNumber numberWithInteger:CTDialogue] : @"l",
                                [NSNumber numberWithInteger:CTIPhone] : @"h",
                                [NSNumber numberWithInteger:CTMessages] : @"m",
                                [NSNumber numberWithInteger:CTWeChat] : @"w"};
    sComponentCode2CallType = @{@"_" : [NSNumber numberWithInteger:CTAudioCall],
                                @"+" : [NSNumber numberWithInteger:CTVideoCall],
                                @"=" : [NSNumber numberWithInteger:CTText],
                                @"s" : [NSNumber numberWithInteger:CTSkype],
                                @"f" : [NSNumber numberWithInteger:CTFaceTime],
                                @"p" : [NSNumber numberWithInteger:CTPhoneAmego],
                                @"i" : [NSNumber numberWithInteger:CTSIP],
                                @"d" : [NSNumber numberWithInteger:CTPushDialer],
                                @"g" : [NSNumber numberWithInteger:CTGrowlVoice],
                                @"k" : [NSNumber numberWithInteger:CTCallTrunk],
                                @"z" : [NSNumber numberWithInteger:CTFritzBox],
                                @"l" : [NSNumber numberWithInteger:CTDialogue],
                                @"h" : [NSNumber numberWithInteger:CTIPhone],
                                @"m" : [NSNumber numberWithInteger:CTMessages],
                                @"w" : [NSNumber numberWithInteger:CTWeChat]};
    sCallType2Names = @{[NSNumber numberWithInteger:CTAudioCall] : @"CTAudioCall",
                        [NSNumber numberWithInteger:CTVideoCall] : @"CTVideoCall",
                        [NSNumber numberWithInteger:CTText] : @"CTText",
                        [NSNumber numberWithInteger:CTSkype] : @"CTSkype",
                        [NSNumber numberWithInteger:CTFaceTime] : @"CTFaceTime",
                        [NSNumber numberWithInteger:CTPhoneAmego] : @"CTPhoneAmego",
                        [NSNumber numberWithInteger:CTSIP] : @"CTSIP",
                        [NSNumber numberWithInteger:CTPushDialer] : @"CTPushDialer",
                        [NSNumber numberWithInteger:CTGrowlVoice] : @"CTGrowlVoice",
                        [NSNumber numberWithInteger:CTCallTrunk] : @"CTCallTrunk",
                        [NSNumber numberWithInteger:CTFritzBox] : @"CTFritzBox",
                        [NSNumber numberWithInteger:CTDialogue] : @"CTDialogue",
                        [NSNumber numberWithInteger:CTIPhone] : @"CTIPhone",
                        [NSNumber numberWithInteger:CTMessages] : @"CTMessages",
                        [NSNumber numberWithInteger:CTWeChat] : @"CTWeChat"};
    sCallModifier2Desc = @{[NSNumber numberWithInteger:CTAudioCall] : @"Make audio call to your contact",
                           [NSNumber numberWithInteger:CTVideoCall] : @"Make video call to your contact",
                           [NSNumber numberWithInteger:CTText] : @"Send text to your contact"};
    sIMIndex2IMStatus = @[@"unknown", @"offline", @"idle", @"away", @"available"];
    sIMStatusBuffer = [NSMutableDictionary dictionary];
    sThumbnailSize = NSMakeSize(32, 32);
    sReservedPhoneLabels = [NSMutableSet set];
}

- (id)init
{
    self = [super init];
    if (self) {
        updater_ = [Updater new];
        BOOL configHasChanged = NO;
        
        if (![[self fileManager] fileExistsAtPath:[self configPlistPath]]) {
            // new user
            hasStartedSettingUp_ = NO;
            isNewUser_ = YES;
            config_ = [[NSMutableDictionary alloc] init];
            configHasChanged = YES;
        } else {
            config_ = [[NSMutableDictionary alloc] initWithContentsOfFile:[self configPlistPath]];
        }

        if (!config_[@"uId"]) {
            config_[@"uId"] = [[[NSUUID UUID] UUIDString] lowercaseString];
            configHasChanged = YES;
        }
        
        NSNumber *callComponentStatus = config_[@"callComponentStatus"];
        if (callComponentStatus) {
            enabledCallType_ = [callComponentStatus integerValue] << CALLTYPE_BOUNDARY_LOW;
        } else {
            int tmp = 0;
            for (int i = 0; i < 5; i++) {
                tmp |= [sCallTypeDefault[i] integerValue];
            }
            enabledCallType_ = tmp;
            config_[@"callComponentStatus"] = [NSNumber numberWithInteger: enabledCallType_];
            configHasChanged = YES;
        }
        
        NSString *callComponentDefaultOrder = config_[@"callComponentDefaultOrder"];
        if (callComponentDefaultOrder) {
            callTypeDefaultOrder_ = [self deriveCallComponentOrderFrom:callComponentDefaultOrder andFrom:[self getComponentCodesFromCallType:enabledCallType_]];
        } else {
            callTypeDefaultOrder_ = [[self getComponentCodesFromCallType:enabledCallType_] mutableCopy];
            config_[@"callComponentDefaultOrder"] = callTypeDefaultOrder_;
            configHasChanged = YES;
        }
        
        NSString *version = config_[@"version"];
        if (!version) {
            config_[@"version"] = VERSION;
            configHasChanged = YES;
        } else {
            if ([VERSION floatValue] > [version floatValue]) {
                // user has upgraded to a new version
                hasStartedSettingUp_ = NO;
                config_[@"version"] = VERSION;
                configHasChanged = YES;
            }
        }
        
        if (configHasChanged) {
            [config_ writeToFile:[self configPlistPath] atomically:YES];
        }
    }
    return self;
}

-(NSMutableString *)deriveCallComponentOrderFrom:(NSString *)callComponentDefaultOrder andFrom:(NSString *)callComponentReferenceOrder
{
    NSMutableString *results = [NSMutableString string];
    
    NSMutableOrderedSet *r = [NSMutableOrderedSet orderedSet];
    for (int i = 0; i < callComponentReferenceOrder.length; i++) {
        NSString *c = [callComponentReferenceOrder substringWithRange:NSMakeRange(i, 1)];
        [r addObject:c];
    }
    for (int i = 0; i < callComponentDefaultOrder.length; i++) {
        NSString *c = [callComponentDefaultOrder substringWithRange:NSMakeRange(i, 1)];
        if ([r containsObject:c]) {
            [results appendString:c];
            [r removeObject:c];
        }
    }
    for (NSString *c in r) {
        [results appendString:c];
    }
    
    return results;
}

-(NSRange)getRangeFromQueryMatch:(NSTextCheckingResult *)queryMatch
{
    if ([queryMatch rangeAtIndex:2].location != NSNotFound && [queryMatch rangeAtIndex:1].location == NSNotFound)
        return [queryMatch rangeAtIndex:2];
    else
        return [queryMatch range];
}

- (NSDictionary *)processLabel:(NSString *)label
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableArray *labelsToDisplay = [NSMutableArray array];
    [dict setObject:[NSMutableSet set] forKey:@"toConsume"];
    
    static NSCharacterSet *spaceCS = nil;
    
    if (!spaceCS)
        spaceCS = [NSCharacterSet characterSetWithCharactersInString:@" \n_$!<>"];
    
    for (NSString *l in [label componentsSeparatedByString:@","]) {
        NSString *cl = [[l stringByTrimmingCharactersInSet:spaceCS] lowercaseString];
        if ([sReservedPhoneLabels containsObject:cl]) {
            [dict[@"toConsume"] addObject:cl];
        } else {
            [labelsToDisplay addObject:cl];
        }
    }
    
    [dict setObject:[labelsToDisplay componentsJoinedByString:@", "] forKey:@"toDisplay"];
    
    return dict;
}

- (NSRegularExpression *)chineseRe
{
    static NSRegularExpression *re = nil;
    if (!re)
        // Chinese names allow spaces in between Chinese characters
        re = [NSRegularExpression regularExpressionWithPattern:@"^(\\p{script=Han}+ *)+$" options:0 error:nil];
    return re;
}

#pragma mark -
#pragma mark Process Query
- (NSString *)process:(NSString *)query
{
#pragma mark Set Up
    if (!hasStartedSettingUp_) {
        hasStartedSettingUp_ = YES;
        
        [UniCall pushNotificationWithOptions:@{@"title": @"Setting up your Uni Call...",
                                               @"message": @"Please sit tight",
                                               @"sound": @"Purr",
                                               @"group": @"settingUp"}];
        
        // post upgrade process
        isInProcessOfSettingUp_ = YES;
        if (!isNewUser_) {
            [self process:@"--updatealfredpreferences yes "];
            [self process:@"--destroythumbnailcache yes "];
            [self process:@"--buildfullthumbnailcache yes "];
        }
        [self process:@"--formatcontactsphonenumbers yes "];
        [self process:@"--addcontactsphoneticnames yes "];
        isInProcessOfSettingUp_ = NO;
        
        [NSThread sleepForTimeInterval:0.5];
        
        if (hasSettingUpSucceeded) {
            [UniCall pushNotificationWithOptions:@{@"title": @"Done",
                                                   @"message": @"Your Uni Call is ready to go",
                                                   @"group": @"settingUp"}];
        } else {
            [UniCall pushNotificationWithOptions:@{@"title": @"Something went wrong",
                                                   @"message": @"Click me to check your Console logs for details",
                                                   @"sound": @"Ping",
                                                   @"remove": @"settingUp",
                                                   @"activate": @"com.apple.Console"}];
        }
        
        [NSThread sleepForTimeInterval:1.3];
        
        if (isNewUser_) {
            [UniCall pushNotificationWithOptions:@{@"title": @"Welcome to Uni Call \U0001F604",
                                                   @"message": @"Click me to view documentation",
                                                   @"sound": @"Glass",
                                                   @"group": @"settingUp",
                                                   @"open": @"http://unicall.guiguan.net/usage.html"}];
        } else {
            [UniCall pushNotificationWithOptions:@{@"title": [NSString stringWithFormat: @"Welcome to v%@ \U0001F604", VERSION],
                                                   @"message": @"Click me to check out what's new",
                                                   @"sound": @"Glass",
                                                   @"group": @"settingUp",
                                                   @"open": @"http://unicall.guiguan.net/index.html#changelog"}];
        }
        
        // just to make sure this is the newest version
        [updater_ checkForUpdateAndDeliverNotification:YES withCompletion:nil];
        
        [self invokeAlfredWithCommand:@"call -"];
        return @"";
    }
    
    if (!isInProcessOfSettingUp_) {
#pragma mark Piggyback Actions
        if (enabledCallType_ & CTMessages) {
            NSNumber *rawTextingGtalkEnabledStatus = config_[@"CTMessagesTextingGtalkEnabledStatus"];
            
            if (!rawTextingGtalkEnabledStatus || [rawTextingGtalkEnabledStatus boolValue]) {
                static NSTimeInterval lastStartTime = 0;
                
                NSTimeInterval currTime = [[NSDate date] timeIntervalSince1970];
                if (!lastStartTime || currTime - lastStartTime > PREPOPULATE_IM_STATUS_INTERVAL) {
                    lastStartTime = currTime;
                    [self prepopulateAllOnlineJabberUserStatus];
                }
            }
        }
        
        NSNumber *rawAutoUpdateCheckingEnabledStatus = config_[@"autoUpdateCheckingEnabledStatus"];
        if (!rawAutoUpdateCheckingEnabledStatus || [rawAutoUpdateCheckingEnabledStatus boolValue]) {
            [updater_ checkForUpdateAndDeliverNotification:YES withCompletion:nil];
        }
    }
    
#pragma mark Process Options
    static NSRegularExpression *queryRe = nil;
    if (!queryRe)
        queryRe = [NSRegularExpression regularExpressionWithPattern:@"([/;,])?\"(.+)\"(?= )|[^ ]+(?= )" options:0 error:nil];
    NSArray *queryMatches = [queryRe matchesInString:query options:0 range:NSMakeRange(0, [query length])];
    
    if ([queryMatches count] == 0)
        return [self outputHelpOnOptions];
    
    NSMutableString *results = [NSMutableString stringWithString:[self xmlHeader]];
    callType_ = 0;
    callTypes_ = [NSMutableArray array];
    callModifiers_ = [NSMutableArray array];
    extraParameter_ = nil;
    extraPhoneNumberExtensionsAfter_ = [NSMutableArray array];
    extraPhoneNumberExtensionsBefore_ = [NSMutableArray array];
    
    NSMutableArray *queryParts = [NSMutableArray array];
    for (int i = 0; i < [queryMatches count]; i++) {
        NSString *queryPart = [query substringWithRange:[self getRangeFromQueryMatch:queryMatches[i]]];
        if ([queryPart hasPrefix:@"-"]) {
            if ([self processOptions:queryPart withRestQueryMatches:(i + 1 < [queryMatches count] ? [queryMatches subarrayWithRange:NSMakeRange(i + 1, [queryMatches count] - i - 1)] : nil) andQuery:query andResults:results]) {
                // option has asked to exit immediately
                [results appendFormat:@"</items>\n"];
                return results;
            }
        } else if ([queryPart hasPrefix:@"/"]) {
            if (queryPart.length > 1) {
                NSString *tmp = [[queryPart substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
                if (tmp.length >= 1)
                    extraParameter_ = tmp;
            }
        } else if ([queryPart hasPrefix:@";"] || [queryPart hasPrefix:@","]) {
            // ; call wait extension
            // , call pause extension
            [extraPhoneNumberExtensionsAfter_ addObjectsFromArray:[RMPhoneFormat dissectPhoneNumber:queryPart]];
        } else {
            [queryParts addObject:queryPart];
        }
    }
    
    if (callType_ & CTBuildFullThumbnailCache) {
        callType_ = CTBuildFullThumbnailCache;
        [self processOptions:@"-a" withRestQueryMatches:nil andQuery:query andResults:results];
    } else if ([queryParts count] == [queryMatches count] || ([queryParts count] > 0 && callType_ <= sNonSearchableOptions)) {
        // default: no searchable options, just query
        [self processOptions:@"-a" withRestQueryMatches:nil andQuery:query andResults:results];
        [self postProcessCallTypeOptionsWithOutputingOptionHelp:NO];
    } else {
        if ([queryParts count] == 0) {
            // no query
            if (callType_ <= sNonSearchableOptions) {
                // no searchable options provided
                return [self outputHelpOnOptions];
            } else {
                // only options
                [results appendFormat:@"%@</items>\n", [self postProcessCallTypeOptionsWithOutputingOptionHelp:YES]];
                return results;
            }
        } else {
            // has searchable options and query
            [self postProcessCallTypeOptionsWithOutputingOptionHelp:NO];
        }
    }
    
    static ABAddressBook *AB = nil;
    
    if (!AB)
        AB = [ABAddressBook addressBook];
    
    NSArray *peopleFound;
    int population;
    NSMutableArray *phoneNumberSearchStrings = nil;
    if (callType_ & CTBuildFullThumbnailCache)
        peopleFound = [AB people];
    else {
#pragma mark Generate Search Element
        NSMutableArray *searchTerms = [[NSMutableArray alloc] initWithCapacity:[queryParts count]];
        NSMutableString *newQuery = [NSMutableString string];
        BOOL isQueryInChinese = YES;
        
        // build search element for queryParts
        for (int i = 0; i < queryParts.count; i++) {
            NSString *curQueryPart = queryParts[i];
            
            BOOL isCurQueryPartInChinese = [[self chineseRe] matchesInString:curQueryPart options:0 range:NSMakeRange(0, [curQueryPart length])].count > 0;
            isQueryInChinese = isCurQueryPartInChinese && isQueryInChinese;
            
            NSMutableArray *searchElements = [NSMutableArray array];
            ABSearchComparison nameSC = queryParts.count > 1 && isCurQueryPartInChinese ? kABContainsSubStringCaseInsensitive : kABPrefixMatchCaseInsensitive;
            
            // first name
            [searchElements addObject:[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:curQueryPart comparison:nameSC]];
            // last name
            [searchElements addObject:[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:curQueryPart comparison:nameSC]];
            if (!isCurQueryPartInChinese) {
                ABSearchComparison phoneticNameSC = curQueryPart.length > 1 ? kABContainsSubStringCaseInsensitive : kABPrefixMatchCaseInsensitive;
                // first name phonetic
                [searchElements addObject:[ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:curQueryPart comparison:phoneticNameSC]];
                // last name phonetic
                [searchElements addObject:[ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:curQueryPart comparison:phoneticNameSC]];
            }
            
            ABSearchElement *queryPartEl = [ABSearchElement searchElementForConjunction:kABSearchOr children:searchElements];

            if (i == 0) {
                // queryPart is nameInitial -> AND initial letters and OR the result along with original queryPart
                BOOL characterwiseQuery = curQueryPart.length == 2;
                if (characterwiseQuery) {
                    queryPartEl = [ABSearchElement searchElementForConjunction:kABSearchOr children:@[queryPartEl, [self generateSearchingElementForQueryPart:[curQueryPart substringWithRange:NSMakeRange(0, 1)] andQueryPart:[curQueryPart substringWithRange:NSMakeRange(1, 1)]]]];
                }
                
                if (!characterwiseQuery) {
                    characterwiseQuery = curQueryPart.length == 3;
                    if (characterwiseQuery) {
                        queryPartEl = [ABSearchElement searchElementForConjunction:kABSearchOr children:@[queryPartEl, [self generateSearchingElementForQueryPart:[curQueryPart substringWithRange:NSMakeRange(0, 1)] queryPart:[curQueryPart substringWithRange:NSMakeRange(1, 1)] andQueryPart:[curQueryPart substringWithRange:NSMakeRange(2, 1)]]]];
                    }
                }
            }
            
            [searchTerms addObject:queryPartEl];
            [newQuery appendFormat:@"%@ ", queryParts[i]]; // keep spaces typed by user
        }
        
        isQueryInChinese = isQueryInChinese && queryParts.count == 1;
        ABSearchElement *searchEl = [ABSearchElement searchElementForConjunction:kABSearchAnd children:searchTerms];
        
        // this represents the whole query (without options)
        query = [newQuery substringToIndex:[newQuery length] - 1];
        
        // preprocess phone number query
        if ([query isValidPhoneNumber:YES]) {
            NSArray *dissectedPhoneNumber = [RMPhoneFormat dissectPhoneNumber:query];
            [extraPhoneNumberExtensionsBefore_ addObjectsFromArray:[dissectedPhoneNumber subarrayWithRange:NSMakeRange(1, [dissectedPhoneNumber count] - 1)]];
            NSString *origPhoneNumber = dissectedPhoneNumber[0];
            // phoneNumberSearchStrings spec
            // -----------------------------
            // all without extensions.
            //
            // phoneNumberSearchStrings[0]: stripped original query
            // phoneNumberSearchStrings[1]: deformatted raw phone number (without international and trunk prefixes)
            // phoneNumberSearchStrings[2]: formatted phone number
            // phoneNumberSearchStrings[3]: formatted phone number with non-breaking spaces (phone numbers entered on iOS and synced to OSX)
            // phoneNumberSearchStrings[4]: original query
            // phoneNumberSearchStrings[5]: original query with non-breaking spaces (phone numbers entered on iOS and synced to OSX)
            phoneNumberSearchStrings = [[[RMPhoneFormat instance] getSearchStringsForPhoneNumber:origPhoneNumber] mutableCopy];
            [phoneNumberSearchStrings addObject:[phoneNumberSearchStrings[2]stringByReplacingSpacesWithNonBreakingSpaces]];
            [phoneNumberSearchStrings addObject:origPhoneNumber];
            [phoneNumberSearchStrings addObject:[origPhoneNumber stringByReplacingSpacesWithNonBreakingSpaces]];
        }
        
        // build search element for query
        NSMutableArray *searchElements = [NSMutableArray array];
        
        if (queryParts.count > 1) {
            ABSearchComparison nameSC = query.length > 1 && isQueryInChinese ? kABContainsSubStringCaseInsensitive : kABPrefixMatchCaseInsensitive;
            // first name
            [searchElements addObject:[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:query comparison:nameSC]];
            // last name
            [searchElements addObject:[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:query comparison:nameSC]];
        }
        
        // organization
        [searchElements addObject:[ABPerson searchElementForProperty:kABOrganizationProperty label:nil key:nil value:query comparison:(isQueryInChinese && query.length > 1) || query.length > 2 ? kABContainsSubStringCaseInsensitive : kABPrefixMatchCaseInsensitive]];
        // nickname
        [searchElements addObject:[ABPerson searchElementForProperty:kABNicknameProperty label:nil key:nil value:query comparison:isQueryInChinese || query.length > 2 ? kABContainsSubStringCaseInsensitive : kABPrefixMatchCaseInsensitive]];
        
        if (!isQueryInChinese && query.length > 1) {
            ABSearchComparison sc = query.length > 2 ? kABContainsSubStringCaseInsensitive : kABPrefixMatchCaseInsensitive;
            
            // phone number
            if (phoneNumberSearchStrings) {
                for (NSString *str in [NSSet setWithArray:phoneNumberSearchStrings]) {
                    [searchElements addObject:[ABPerson searchElementForProperty:kABPhoneProperty label:nil key:nil value:str comparison:kABContainsSubString]];
                }
            }
            // skype username
            if (callType_ & CTSkype) {
                ABSearchElement *skypeUsername = [ABPerson searchElementForProperty:kABInstantMessageProperty label:nil key:kABInstantMessageUsernameKey value:query comparison:kABPrefixMatchCaseInsensitive];
                ABSearchElement *skypeService = [ABPerson searchElementForProperty:kABInstantMessageProperty label:nil key:kABInstantMessageServiceKey value:kABInstantMessageServiceSkype comparison:kABEqual];
                [searchElements addObject:[ABSearchElement searchElementForConjunction:kABSearchAnd children:@[skypeUsername, skypeService]]];
            }
            // email
            if (callType_ & (CTFaceTime | CTMessages))
                [searchElements addObject:[ABPerson searchElementForProperty:kABEmailProperty label:nil key:nil value:query comparison:kABPrefixMatchCaseInsensitive]];
            // sip url
            if (callType_ & CTSIP)
                [searchElements addObject:[ABPerson searchElementForProperty:kABURLsProperty label:@"sip" key:nil value:query comparison:sc]];
            // wechat url
            if (callType_ & CTWeChat) {
                for (NSString *label in sWeChatLabels) {
                    [searchElements addObject:[ABPerson searchElementForProperty:kABURLsProperty label:label key:nil value:query comparison:sc]];
                }
            }
        }
        
        searchEl = [ABSearchElement searchElementForConjunction:kABSearchOr children:@[[ABSearchElement searchElementForConjunction:kABSearchOr children:searchElements], searchEl]];
        
        peopleFound = [AB recordsMatchingSearchElement:searchEl];
        [results setString:[self xmlHeader]];
        hasGeneratedOutputsForFirstContact_ = NO;
    }
    
    if (!(callType_ & CTNoThumbnailCache) && ![[self fileManager] fileExistsAtPath:[self thumbnailCachePath]]) {
        //create the folder if it doesn't exist
        [[self fileManager] createDirectoryAtPath:[self thumbnailCachePath] withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    population = (int)[peopleFound count];
    
    BOOL preserveResultOrder = NO;
    NSMutableArray *bufferedResults = nil;
    NSMutableArray *stickyResults = nil;
    
    if (!(callType_ & CTBuildFullThumbnailCache)) {
#pragma mark Initialise Variables Before Result Generation
        if (callType_ & CTFaceTime && !sFaceTimeNominatedLabels) {
            sFaceTimeNominatedLabels = [NSSet setWithObjects:@"imessages", @"facetime", @"iphone", @"ipad", @"mac", @"idevice", @"apple", @"icloud", nil];
            [sReservedPhoneLabels unionSet:sFaceTimeNominatedLabels];
        }
        if (callType_ & CTMessages && !sMessagesNominatedLabels) {
            sMessagesNominatedLabels = [NSSet setWithObjects:@"imessages", @"facetime", @"iphone", @"ipad", @"mac", @"idevice", @"apple", @"icloud", nil];
            sMessagesGtalkLabels = [NSSet setWithObjects:@"gmail", @"gtalk", nil];
            [sReservedPhoneLabels unionSet:sMessagesNominatedLabels];
            [sReservedPhoneLabels unionSet:sMessagesGtalkLabels];
        }
        if (callType_ & CTWeChat && !sWeChatLabels) {
            sWeChatLabels = [NSSet setWithObjects:@"wechat", @"weixin", @"微信", nil];
            [sReservedPhoneLabels unionSet:sWeChatLabels];
        }
        
        bufferedResults = [NSMutableArray array];
        stickyResults = [NSMutableArray array];
    }
    
    for (int j = 0; j < population; j++) {
        ABRecord *r = peopleFound[j];
        NSMutableString *outDisplayName = [NSMutableString string];
        // remove :ABPerson from the end of uId
        NSString *uId = [[r uniqueId] stringByRemovingSuffixes:@":ABPerson", nil];
        
        if (!(callType_ & CTBuildFullThumbnailCache)) {
            hasGeneratedOutputsForFirstContact_ = j >= 1;
            
            NSString *lastName = [r valueForProperty:kABLastNameProperty];
            NSString *firstName = [r valueForProperty:kABFirstNameProperty];
            NSString *middleName = [r valueForProperty:kABMiddleNameProperty];
            
            if (lastName && firstName) {
                NSArray *mLastName = [[self chineseRe] matchesInString:lastName options:0 range:NSMakeRange(0, [lastName length])];
                NSArray *mFirstName = [[self chineseRe] matchesInString:firstName options:0 range:NSMakeRange(0, [firstName length])];
                if ([mLastName count] > 0 && [mFirstName count] > 0) {
                    // Chinese name
                    [outDisplayName appendFormat:@"%@%@", lastName, firstName];
                    if (middleName)
                        [outDisplayName appendString:middleName];
                }
            }

            if (outDisplayName.length == 0) {
                int nameOrdering = ([[r valueForProperty:kABPersonFlags] intValue] & kABNameOrderingMask);
                if (nameOrdering == kABDefaultNameOrdering)
                    nameOrdering = (int)[AB defaultNameOrdering];
                if ((nameOrdering == kABLastNameFirst) && lastName)
                    [outDisplayName appendFormat:@"%@ ", lastName];
                if (firstName)
                    [outDisplayName appendFormat:@"%@ ", firstName];
                if (middleName)
                    [outDisplayName appendFormat:@"%@ ", middleName];
                if ((nameOrdering != kABLastNameFirst) && lastName)
                    [outDisplayName appendFormat:@"%@ ", lastName];
                if (outDisplayName.length > 0)
                    // delete trailing space
                    [outDisplayName deleteCharactersInRange:NSMakeRange([outDisplayName length]-1, 1)];
                else
                    outDisplayName = [r valueForProperty:kABOrganizationProperty];
            }
        }
        
        // output available results for each person according to the order defined by callTypes, i.e. the order of the options specified by user
        for (int i = 0; i < [callTypes_ count]; i++) {
            switch ([callTypes_[i] integerValue]) {
#pragma mark Generate Results for Each Found Record
#pragma mark _ CTSkype
                case CTSkype: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.23137f green:0.72941f blue:0.93725f alpha:1.0f];
                    NSString *skypeThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-Skype.tiff", uId];
                    NSString *skypeUsernameThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-Skype-Username.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:skypeThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    [self checkAndUpdateThumbnailIfNeededAtPath:skypeUsernameThumbnailPath forRecord:r withColor:color hasShadow:YES];
                    
                    if (!isThumbNailOkay) {
                        skypeThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-Skype.tiff"];
                        skypeUsernameThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-Skype-Username.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:skypeThumbnailPath withColor:color hasShadow:NO];
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:skypeUsernameThumbnailPath withColor:color hasShadow:YES];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                        
                        // output Skype usernames
                        ABMultiValue *ims = [r valueForProperty:kABInstantMessageProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSDictionary *entry = [ims valueAtIndex:i];
                            if ([entry[kABInstantMessageServiceKey] isEqualToString: kABInstantMessageServiceSkype]) {
                                NSString *username = entry[kABInstantMessageUsernameKey];
                                NSString *iMSUId = [ims identifierAtIndex:i];
                                BOOL stickyCritera = [username rangeOfString:query options:(NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound;
                                if (stickyCritera && query.length > 3)
                                    [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                                
                                for (NSNumber *cm in curCM) {
                                    CallType ct = [cm integerValue];
                                    switch (ct) {
                                        case CTAudioCall:
                                            if ([self fillBufferedResults:bufferedResults
                                                         andStickyResults:stickyResults
                                                withPreservingResultOrder:preserveResultOrder
                                                         andStickyCritera:stickyCritera
                                                               andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Skype-Username-Audio\"", iMSUId]
                                                               andResultB:[NSString stringWithFormat:@" arg=\"[CTSkype]%@?call&amp;video=false\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype audio call to Skype username: %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", username, username, outDisplayName, username, username, username, skypeUsernameThumbnailPath]])
                                                goto end_result_generation;
                                            break;
                                        case CTVideoCall:
                                            if([self fillBufferedResults:bufferedResults
                                                        andStickyResults:stickyResults
                                               withPreservingResultOrder:preserveResultOrder
                                                        andStickyCritera:stickyCritera
                                                              andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Skype-Username-Video\"", iMSUId]
                                                              andResultB:[NSString stringWithFormat:@" arg=\"[CTSkype]%@?call&amp;video=true\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype video call to Skype username: %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", username, username, outDisplayName, username, username, username, skypeUsernameThumbnailPath]])
                                                goto end_result_generation;
                                            break;
                                        case CTText:
                                            if([self fillBufferedResults:bufferedResults
                                                        andStickyResults:stickyResults
                                               withPreservingResultOrder:preserveResultOrder
                                                        andStickyCritera:stickyCritera
                                                              andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Skype-Username-Text\"", iMSUId]
                                                              andResultB:[NSString stringWithFormat:@" arg=\"[CTSkype]%@?chat\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype text to Skype username: %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", username, username, outDisplayName, username, username, username, skypeUsernameThumbnailPath]])
                                                goto end_result_generation;
                                        default:
                                            break;
                                    }
                                }
                            }
                        }
                        
                        // output phone numbers
                        ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]][0];
                            NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                            NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                            BOOL stickyCritera = phoneNumberSearchStrings && [strippedPhoneNum rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                            if (stickyCritera && query.length > 3)
                                [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        if([self fillBufferedResults:bufferedResults
                                                    andStickyResults:stickyResults
                                           withPreservingResultOrder:preserveResultOrder
                                                    andStickyCritera:stickyCritera
                                                          andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Skype-Audio\"", iMSUId]
                                                          andResultB:[NSString stringWithFormat:@" arg=\"[CTSkype]%@?call&amp;video=false\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype audio call to phone number:%@%@ %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, skypeThumbnailPath]])
                                            goto end_result_generation;
                                        break;
                                    case CTVideoCall:
                                        if([self fillBufferedResults:bufferedResults
                                                    andStickyResults:stickyResults
                                           withPreservingResultOrder:preserveResultOrder
                                                    andStickyCritera:stickyCritera
                                                          andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Skype-Video\"", iMSUId]
                                                          andResultB:[NSString stringWithFormat:@" arg=\"[CTSkype]%@?call&amp;video=true\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype video call to phone number:%@%@ %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, skypeThumbnailPath]])
                                            goto end_result_generation;
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                    }
                    
                    break;
                }
#pragma mark _ CTFaceTime
                case CTFaceTime: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.97647f green:0.29412f blue:0.60000f alpha:1.0f];
                    NSString *faceTimeThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-FaceTime.tiff", uId];
                    NSString *faceTimeNominatedThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-FaceTime-Nominated.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:faceTimeThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    [self checkAndUpdateThumbnailIfNeededAtPath:faceTimeNominatedThumbnailPath forRecord:r withColor:color hasShadow:YES];
                    
                    if (!isThumbNailOkay) {
                        faceTimeThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-FaceTime.tiff"];
                        faceTimeNominatedThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-FaceTime-Nominated.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:faceTimeThumbnailPath withColor:color hasShadow:NO];
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:faceTimeNominatedThumbnailPath withColor:color hasShadow:YES];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableArray *localBufferedResults = [NSMutableArray array];
                        NSMutableArray *localStickyResults = [NSMutableArray array];
                        NSArray *curCM;
                        if ([callModifiers_ count] > 0)
                            curCM = callModifiers_;
                        else {
                            NSNumber *defaultWorkingMode = config_[@"CTFaceTimeDefaultWorkingMode"];
                            if (defaultWorkingMode)
                                curCM = @[defaultWorkingMode];
                            else
                                curCM = @[[NSNumber numberWithInteger:CTVideoCall]];
                        }
                        
                        // output phone numbers
                        __block BOOL hasNomination = NO;
                        void (^foundNominatedTarget)(void) = ^{
                            if (!hasNomination) {
                                hasNomination = YES;
                                
                                [localBufferedResults removeAllObjects];
                                [localStickyResults removeAllObjects];
                            }
                        };
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]][0];
                            NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                            NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                            BOOL isNominated = [sFaceTimeNominatedLabels intersectsSet:processedPhoneLabels[@"toConsume"]];
                            BOOL stickyCritera = phoneNumberSearchStrings && [[RMPhoneFormat strip:phoneNum] rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        if (isNominated) {
                                            foundNominatedTarget();
                                            
                                            [self fillBufferedResults:localBufferedResults
                                                     andStickyResults:localStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-FaceTime-Nominated-Audio\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTFaceTime]facetime-audio:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime audio call to phone number:%@%@ %@ (nominated)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, faceTimeNominatedThumbnailPath]];
                                        } else if (!hasNomination)
                                            [self fillBufferedResults:localBufferedResults
                                                     andStickyResults:localStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-FaceTime-Audio\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTFaceTime]facetime-audio:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime audio call to phone number:%@%@ %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, faceTimeThumbnailPath]];
                                        break;
                                    case CTVideoCall:
                                        if (isNominated) {
                                            foundNominatedTarget();
                                            
                                            [self fillBufferedResults:localBufferedResults
                                                     andStickyResults:localStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-FaceTime-Nominated-Video\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime video call to phone number:%@%@ %@ (nominated)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, faceTimeNominatedThumbnailPath]];
                                        } else if (!hasNomination)
                                            [self fillBufferedResults:localBufferedResults
                                                     andStickyResults:localStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-FaceTime-Video\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime video call to phone number:%@%@ %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, faceTimeThumbnailPath]];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        
                        // output emails
                        ims = [r valueForProperty:kABEmailProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *email = [ims valueAtIndex:i];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedEmailLabels = [self processLabel:[ims labelAtIndex:i]];
                            BOOL isNominated = [sFaceTimeNominatedLabels intersectsSet:processedEmailLabels[@"toConsume"]] || [email hasSuffix:@"icloud.com"] || [email hasSuffix:@"me.com"];
                            BOOL stickyCritera = [email rangeOfString:query options:(NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound;
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        if (isNominated) {
                                            foundNominatedTarget();
                                            
                                            [self fillBufferedResults:localBufferedResults
                                                     andStickyResults:localStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-FaceTime-Nominated-Audio\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTFaceTime]facetime-audio:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime audio call to email address: %@ (nominated)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", email, email, outDisplayName, email, email, email, faceTimeNominatedThumbnailPath]];
                                        } else if (!hasNomination)
                                            [self fillBufferedResults:localBufferedResults
                                                     andStickyResults:localStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-FaceTime-Audio\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTFaceTime]facetime-audio:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime audio call to email address: %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", email, email, outDisplayName, email, email, email, faceTimeThumbnailPath]];
                                        break;
                                    case CTVideoCall:
                                        if (isNominated) {
                                            foundNominatedTarget();
                                            
                                            [self fillBufferedResults:localBufferedResults
                                                     andStickyResults:localStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-FaceTime-Nominated-Video\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime video call to email address: %@ (nominated)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", email, email, outDisplayName, email, email, email, faceTimeNominatedThumbnailPath]];
                                        } else if (!hasNomination)
                                            [self fillBufferedResults:localBufferedResults
                                                     andStickyResults:localStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-FaceTime-Video\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime video call to email address: %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", email, email, outDisplayName, email, email, email, faceTimeThumbnailPath]];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        
                        if (localStickyResults.count > 0 && query.length > 3)
                            [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, localBufferedResults, localStickyResults, nil];
                        
                        if ([self mergeBufferedResults:bufferedResults andStickyResults:stickyResults withLocalBufferedResults:localBufferedResults andLocalStickyResults:localStickyResults])
                            goto end_result_generation;
                    }
                    
                    break;
                }
#pragma mark _ CTPhoneAmego
                case CTPhoneAmego: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:1.00000f green:0.74118f blue:0.30196f alpha:1.0f];
                    NSString *phoneAmegoThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-PhoneAmego.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:phoneAmegoThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        phoneAmegoThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-PhoneAmego.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:phoneAmegoThumbnailPath withColor:color hasShadow:NO];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSArray *dissectedPhoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]];
                            NSString *phoneNum = dissectedPhoneNum[0];
                            NSString *postd = nil;
                            if (extraPhoneNumberExtensionsBefore_.count > 0) {
                                postd = [extraPhoneNumberExtensionsBefore_[0] substringFromIndex:1];
                            } else if (dissectedPhoneNum.count > 1) {
                                postd = [dissectedPhoneNum[1] substringFromIndex:1];
                            } else if (extraPhoneNumberExtensionsAfter_.count > 0) {
                                postd = [extraPhoneNumberExtensionsAfter_[0] substringFromIndex:1];
                            }
                            NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                            NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                            BOOL stickyCritera = phoneNumberSearchStrings && [strippedPhoneNum rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                            if (stickyCritera && query.length > 3)
                                [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                            
                            NSString *deviceLabel = nil;
                            if (extraParameter_) {
                                deviceLabel = config_[@"phoneAmegoDeviceAliases"][extraParameter_];
                            }
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall: {
                                        NSString *outDisplayPhoneNum = [@[phoneNum, postd ? [NSString stringWithFormat:@",%@", postd] : @""] componentsJoinedByString:@""];
                                        if([self fillBufferedResults:bufferedResults
                                                    andStickyResults:stickyResults
                                           withPreservingResultOrder:preserveResultOrder
                                                    andStickyCritera:stickyCritera
                                                          andResultA:[NSString stringWithFormat:@"<item uid=\"%@-PhoneAmego-Audio\"", iMSUId]
                                                          andResultB:[NSString stringWithFormat:@" arg=\"[CTPhoneAmego]%@%@%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Bluetooth audio call to phone number:%@%@ %@ via Phone Amego</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, deviceLabel ? [NSString stringWithFormat:@";device=%@", deviceLabel] : @"", postd ? [NSString stringWithFormat:@";postd=%@", postd] : @"", phoneNum, outDisplayName,  phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, outDisplayPhoneNum, outDisplayPhoneNum, outDisplayPhoneNum, phoneAmegoThumbnailPath]])
                                            goto end_result_generation;
                                        break;
                                    }
                                    default:
                                        break;
                                }
                            }
                        }
                    }
                    
                    break;
                }
#pragma mark _ CTSIP
                case CTSIP: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.50588f green:0.20784f blue:0.65882f alpha:1.0f];
                    NSString *sipThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-SIP.tiff", uId];
                    NSString *sipRecordedThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-SIP-Recorded.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:sipThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    [self checkAndUpdateThumbnailIfNeededAtPath:sipRecordedThumbnailPath forRecord:r withColor:color hasShadow:YES];
                    
                    if (!isThumbNailOkay) {
                        sipThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-SIP.tiff"];
                        sipRecordedThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-SIP-Recorded.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:sipThumbnailPath withColor:color hasShadow:NO];
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:sipRecordedThumbnailPath withColor:color hasShadow:YES];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                        
                        // output recorded SIP url
                        ABMultiValue *ims = [r valueForProperty:kABURLsProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            if ([[ims labelAtIndex:i] caseInsensitiveCompare:@"sip"] == NSOrderedSame) {
                                NSString *sIPUrl = [ims valueAtIndex:i];
                                NSString *iMSUId = [ims identifierAtIndex:i];
                                BOOL stickyCritera = [sIPUrl rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound;
                                if (stickyCritera && query.length > 3)
                                    [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                                
                                sIPUrl = [sIPUrl stringByRemovingPrefixes:@"sip:", nil];
                                
                                for (NSNumber *cm in curCM) {
                                    CallType ct = [cm integerValue];
                                    switch (ct) {
                                        case CTAudioCall:
                                            if ([self fillBufferedResults:bufferedResults
                                                         andStickyResults:stickyResults
                                                withPreservingResultOrder:preserveResultOrder
                                                         andStickyCritera:stickyCritera
                                                               andResultA:[NSString stringWithFormat:@"<item uid=\"%@-SIP-Recorded-Audio\"", iMSUId]
                                                               andResultB:[NSString stringWithFormat:@" arg=\"[CTSIP]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>SIP audio call to SIP address: %@ (recorded)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", sIPUrl, sIPUrl, outDisplayName, sIPUrl, sIPUrl, sIPUrl, sipRecordedThumbnailPath]])
                                                goto end_result_generation;
                                            break;
                                        default:
                                            break;
                                    }
                                }
                            }
                        }
                        
                        if ([config_[@"CTSIPCallingPhoneNumberEnabledStatus"] boolValue]) {
                            // output phone numbers
                            ims = [r valueForProperty:kABPhoneProperty];
                            for (int i = 0; i < [ims count]; i++) {
                                NSString *phoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]][0];
                                NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                                NSString *iMSUId = [ims identifierAtIndex:i];
                                NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                                NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                                BOOL stickyCritera = phoneNumberSearchStrings && [strippedPhoneNum rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                                if (stickyCritera && query.length > 3)
                                    [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                                
                                for (NSNumber *cm in curCM) {
                                    CallType ct = [cm integerValue];
                                    switch (ct) {
                                        case CTAudioCall:
                                            if([self fillBufferedResults:bufferedResults
                                                        andStickyResults:stickyResults
                                               withPreservingResultOrder:preserveResultOrder
                                                        andStickyCritera:stickyCritera
                                                              andResultA:[NSString stringWithFormat:@"<item uid=\"%@-SIP-Audio\"", iMSUId]
                                                              andResultB:[NSString stringWithFormat:@" arg=\"[CTSIP]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>SIP audio call to phone number:%@%@ %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName,  phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, sipThumbnailPath]])
                                                goto end_result_generation;
                                            break;
                                        default:
                                            break;
                                    }
                                }
                            }
                        }
                    }
                    
                    break;
                }
#pragma mark _ CTPushDialer
                case CTPushDialer: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.62745f green:0.32157f blue:0.17647f alpha:1.0f];
                    NSString *pushDialerThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-PushDialer.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:pushDialerThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        pushDialerThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-PushDialer.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:pushDialerThumbnailPath withColor:color hasShadow:NO];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]][0];
                            NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                            NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                            BOOL stickyCritera = phoneNumberSearchStrings && [strippedPhoneNum rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                            if (stickyCritera && query.length > 3)
                                [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        if([self fillBufferedResults:bufferedResults
                                                    andStickyResults:stickyResults
                                           withPreservingResultOrder:preserveResultOrder
                                                    andStickyCritera:stickyCritera
                                                          andResultA:[NSString stringWithFormat:@"<item uid=\"%@-PushDialer-Audio\"", iMSUId]
                                                          andResultB:[NSString stringWithFormat:@" arg=\"[CTPushDialer]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>PushDialer audio call to phone number:%@%@ %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>",strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, pushDialerThumbnailPath]])
                                            goto end_result_generation;
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                    }
                    
                    break;
                }
#pragma mark _ CTGrowlVoice
                case CTGrowlVoice: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.21569f green:0.65882f blue:0.20784f alpha:1.0f];
                    NSString *growlVoiceThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-GrowlVoice.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:growlVoiceThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        growlVoiceThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-GrowlVoice.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:growlVoiceThumbnailPath withColor:color hasShadow:NO];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]][0];
                            NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                            NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                            BOOL stickyCritera = phoneNumberSearchStrings && [strippedPhoneNum rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                            if (stickyCritera && query.length > 3)
                                [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        if([self fillBufferedResults:bufferedResults
                                                    andStickyResults:stickyResults
                                           withPreservingResultOrder:preserveResultOrder
                                                    andStickyCritera:stickyCritera
                                                          andResultA:[NSString stringWithFormat:@"<item uid=\"%@-GrowlVoice-Audio\"", iMSUId]
                                                          andResultB:[NSString stringWithFormat:@" arg=\"[CTGrowlVoice]%@?call\" autocomplete=\"%@\"><title>%@</title><subtitle>Google Voice audio call to phone number:%@%@ %@ via GrowlVoice</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, growlVoiceThumbnailPath]])
                                            goto end_result_generation;
                                        break;
                                    case CTText:
                                        if([self fillBufferedResults:bufferedResults
                                                    andStickyResults:stickyResults
                                           withPreservingResultOrder:preserveResultOrder
                                                    andStickyCritera:stickyCritera
                                                          andResultA:[NSString stringWithFormat:@"<item uid=\"%@-GrowlVoice-Text\"", iMSUId]
                                                          andResultB:[NSString stringWithFormat:@" arg=\"[CTGrowlVoice]%@?text\" autocomplete=\"%@\"><title>%@</title><subtitle>Google Voice text to phone number:%@%@ %@ via GrowlVoice</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, growlVoiceThumbnailPath]])
                                            goto end_result_generation;
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                    }
                    
                    break;
                }
#pragma mark _ CTCallTrunk
                case CTCallTrunk: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.082353f green:0.278431f blue:0.235294f alpha:1.0f];
                    NSString *callTrunkThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-CallTrunk.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:callTrunkThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        callTrunkThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-CallTrunk.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:callTrunkThumbnailPath withColor:color hasShadow:NO];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                        
                        NSString *country = nil;
                        if (extraParameter_) {
                            country = [extraParameter_ uppercaseString];
                        }
                        if (!country) {
                            country = config_[@"callTrunkDefaultCountry"];
                            if (!country) {
                                NSDictionary *candidate = [self checkAvailableCallTrunkCountries];
                                if ([candidate count] > 0) {
                                    country = [candidate allKeys][0]; // randomly pick an available one
                                    [config_ setObject:country forKey:@"callTrunkDefaultCountry"];
                                    [config_ writeToFile:[self configPlistPath] atomically:YES];
                                } else {
                                    country = @"US";
                                }
                            }
                        }
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]][0];
                            NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                            NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                            BOOL stickyCritera = phoneNumberSearchStrings && [strippedPhoneNum rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                            if (stickyCritera && query.length > 3)
                                [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        if([self fillBufferedResults:bufferedResults
                                                    andStickyResults:stickyResults
                                           withPreservingResultOrder:preserveResultOrder
                                                    andStickyCritera:stickyCritera
                                                          andResultA:[NSString stringWithFormat:@"<item uid=\"%@-CallTrunk-Audio\"", iMSUId]
                                                          andResultB:[NSString stringWithFormat:@" arg=\"[CTCallTrunk]%@/%@\" autocomplete=\"%@\"><title>%@</title><subtitle>CallTrunk audio call to phone number:%@%@ %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, country, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, callTrunkThumbnailPath]])
                                            goto end_result_generation;
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                    }
                    
                    break;
                }
#pragma mark _ CTFritzBox
                case CTFritzBox: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.81961f green:0.25490f blue:0.21569f alpha:1.0f];
                    NSString *fritzBoxThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-FritzBox.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:fritzBoxThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        fritzBoxThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-FritzBox.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:fritzBoxThumbnailPath withColor:color hasShadow:NO];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]][0];
                            NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                            NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                            BOOL stickyCritera = phoneNumberSearchStrings && [strippedPhoneNum rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                            if (stickyCritera && query.length > 3)
                                [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        if([self fillBufferedResults:bufferedResults
                                                    andStickyResults:stickyResults
                                           withPreservingResultOrder:preserveResultOrder
                                                    andStickyCritera:stickyCritera
                                                          andResultA:[NSString stringWithFormat:@"<item uid=\"%@-FritzBox-Audio\"", iMSUId]
                                                          andResultB:[NSString stringWithFormat:@" arg=\"[CTFritzBox]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Fritz!Box audio call to phone number:%@%@ %@ via Frizzix</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, fritzBoxThumbnailPath]])
                                            goto end_result_generation;
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                    }
                    
                    break;
                }
#pragma mark _ CTDialogue
                case CTDialogue: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.77647f green:0.00000f blue:0.74118f alpha:1.0f];
                    NSString *dialogueThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-Dialogue.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:dialogueThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        dialogueThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-Dialogue.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:dialogueThumbnailPath withColor:color hasShadow:NO];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]][0];
                            NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                            NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                            BOOL stickyCritera = phoneNumberSearchStrings && [strippedPhoneNum rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                            if (stickyCritera && query.length > 3)
                                [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        if([self fillBufferedResults:bufferedResults
                                                    andStickyResults:stickyResults
                                           withPreservingResultOrder:preserveResultOrder
                                                    andStickyCritera:stickyCritera
                                                          andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Dialogue-Audio\"", iMSUId]
                                                          andResultB:[NSString stringWithFormat:@" arg=\"[CTDialogue]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Bluetooth audio call to phone number:%@%@ %@ via Dialogue</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, dialogueThumbnailPath]])
                                            goto end_result_generation;
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                    }
                    
                    break;
                }
#pragma mark _ CTIPhone
                case CTIPhone: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.99216f green:0.49804f blue:0.38824f alpha:1.0f];
                    NSString *iPhoneThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-IPhone.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:iPhoneThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        iPhoneThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-IPhone.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:iPhoneThumbnailPath withColor:color hasShadow:NO];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSArray *dissectedPhoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]];
                            NSString *phoneNum = dissectedPhoneNum[0];
                            NSString *phoneNumExtensions =
                            [@[[extraPhoneNumberExtensionsBefore_ componentsJoinedByString:@""],
                               [[dissectedPhoneNum subarrayWithRange:NSMakeRange(1, dissectedPhoneNum.count - 1)] componentsJoinedByString:@""],
                               [extraPhoneNumberExtensionsAfter_ componentsJoinedByString:@""]] componentsJoinedByString:@""];
                            NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                            NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                            BOOL stickyCritera = phoneNumberSearchStrings && [strippedPhoneNum rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                            if (stickyCritera && query.length > 3)
                                [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall: {
                                        NSString *outDisplayPhoneNum = [@[phoneNum, phoneNumExtensions] componentsJoinedByString:@""];
                                        if([self fillBufferedResults:bufferedResults
                                                    andStickyResults:stickyResults
                                           withPreservingResultOrder:preserveResultOrder
                                                    andStickyCritera:stickyCritera
                                                          andResultA:[NSString stringWithFormat:@"<item uid=\"%@-IPhone-Audio\"", iMSUId]
                                                          andResultB:[NSString stringWithFormat:@" arg=\"[CTIPhone]%@%@\" autocomplete=\"%@\"><title>%@</title><subtitle>iPhone audio call to phone number:%@%@ %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNumExtensions, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, outDisplayPhoneNum, outDisplayPhoneNum, outDisplayPhoneNum, iPhoneThumbnailPath]])
                                            goto end_result_generation;
                                        break;
                                    }
                                    default:
                                        break;
                                }
                            }
                        }
                    }
                    
                    break;
                }
#pragma mark _ CTMessages
                case CTMessages: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.149019608f green:0.57254902f blue:0.976470588f alpha:1.0f];
                    NSString *messagesThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-Messages.tiff", uId];
                    NSString *messagesNominatedThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-Messages-Nominated.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:messagesThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    [self checkAndUpdateThumbnailIfNeededAtPath:messagesNominatedThumbnailPath forRecord:r withColor:color hasShadow:YES];
                    
                    if (!isThumbNailOkay) {
                        messagesThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-Messages.tiff"];
                        messagesNominatedThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-Messages-Nominated.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:messagesThumbnailPath withColor:color hasShadow:NO];
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:messagesNominatedThumbnailPath withColor:color hasShadow:YES];
#endif
                    }
                    
                    NSNumber *rawTextingGtalkEnabledStatus = config_[@"CTMessagesTextingGtalkEnabledStatus"];
                    
                    NSArray *iMThumbnailPaths = nil;
                    
                    if (!rawTextingGtalkEnabledStatus || [rawTextingGtalkEnabledStatus boolValue])
                        iMThumbnailPaths = [self checkAndReturnIMThumbnailPathsForUId:uId andRecord:r];
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableArray *localBufferedResults = [NSMutableArray array];
                        NSMutableArray *localSecondaryBufferedResults = [NSMutableArray array];
                        NSMutableArray *localStickyResults = [NSMutableArray array];
                        NSMutableArray *localSecondaryStickyResults = [NSMutableArray array];
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTText]];
                        
                        __block BOOL hasNomination = NO;
                        // output phone numbers (only nominated if possible; if no nomination found, output all phone numbers)
                        void (^foundNominatedTargetInPhoneNumbers)(void) = ^{
                            if (!hasNomination) {
                                hasNomination = YES;
                                
                                [localBufferedResults removeAllObjects];
                                [localStickyResults removeAllObjects];
                            }
                        };
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]][0];
                            NSString *strippedPhoneNum = [RMPhoneFormat strip:phoneNum];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processLabel:[ims labelAtIndex:i]];
                            NSString *phoneLabelsToBeDisplayed = processedPhoneLabels[@"toDisplay"];
                            BOOL isNominated = [sMessagesNominatedLabels intersectsSet:processedPhoneLabels[@"toConsume"]];
                            BOOL stickyCritera = phoneNumberSearchStrings && [strippedPhoneNum rangeOfString:phoneNumberSearchStrings[1] options:NSCaseInsensitiveSearch].location != NSNotFound;
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTText:
                                        if (isNominated) {
                                            foundNominatedTargetInPhoneNumbers();
                                            
                                            [self fillBufferedResults:localBufferedResults
                                                     andStickyResults:localStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Messages-Nominated-Text\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTMessages]imessage:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Messages text to phone number:%@%@ %@ (nominated)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, messagesNominatedThumbnailPath]];
                                        } else if (!hasNomination)
                                            [self fillBufferedResults:localBufferedResults
                                                     andStickyResults:localStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Messages-Text\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTMessages]imessage:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Messages text to phone number:%@%@ %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", strippedPhoneNum, phoneNum, outDisplayName, phoneLabelsToBeDisplayed.length > 0 ? @" " : @"", phoneLabelsToBeDisplayed, phoneNum, phoneNum, phoneNum, messagesThumbnailPath]];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        
                        // output emails (only nominated if possible; if no nomination found, output after gtalk addresses)
                        void (^foundNominatedTargetInEmails)(void) = ^{
                            if (!hasNomination) {
                                hasNomination = YES;
                                
                                [localBufferedResults removeAllObjects];
                                [localSecondaryBufferedResults removeAllObjects];
                                [localStickyResults removeAllObjects];
                                [localSecondaryStickyResults removeAllObjects];
                            }
                        };
                        ims = [r valueForProperty:kABEmailProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *email = [ims valueAtIndex:i];
                            NSString *iMSUId = [ims identifierAtIndex:i];
                            NSDictionary *processedEmailLabels = [self processLabel:[ims labelAtIndex:i]];
                            BOOL isNominated = [sMessagesNominatedLabels intersectsSet:processedEmailLabels[@"toConsume"]] || [email hasSuffix:@"icloud.com"] || [email hasSuffix:@"me.com"];
                            BOOL stickyCritera = [email rangeOfString:query options:(NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound;
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTText:
                                        if (isNominated) {
                                            foundNominatedTargetInEmails();
                                            
                                            [self fillBufferedResults:localSecondaryBufferedResults
                                                     andStickyResults:localSecondaryStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Messages-Nominated-Text\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTMessages]imessage:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Messages text to email address: %@ (nominated)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", email, email, outDisplayName, email, email, email, messagesNominatedThumbnailPath]];
                                        } else if (!hasNomination)
                                            [self fillBufferedResults:localSecondaryBufferedResults
                                                     andStickyResults:localSecondaryStickyResults
                                            withPreservingResultOrder:preserveResultOrder
                                                     andStickyCritera:stickyCritera
                                                           andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Messages-Text\"", iMSUId]
                                                           andResultB:[NSString stringWithFormat:@" arg=\"[CTMessages]imessage:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Messages text to email address: %@</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", email, email, outDisplayName, email, email, email, messagesThumbnailPath]];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        
                        if (hasNomination) {
                            // if a nominated target has been found, put email results in front
                            [localBufferedResults addObjectsFromArray:localSecondaryBufferedResults];
                            [localStickyResults addObjectsFromArray:localSecondaryStickyResults];
                        }
                        
                        if (!rawTextingGtalkEnabledStatus || [rawTextingGtalkEnabledStatus boolValue]) {
                            // output gtalk addresses
                            // first check gtalk addresses from im section
                            BOOL foundGtalkUsername = NO;
                            ims = [r valueForProperty:kABInstantMessageProperty];
                            for (int i = 0; i < [ims count]; i++) {
                                NSDictionary *entry = [ims valueAtIndex:i];
                                if ([entry[kABInstantMessageServiceKey] isEqualToString: kABInstantMessageServiceGoogleTalk]) {
                                    foundGtalkUsername = YES;
                                    NSString *username = entry[kABInstantMessageUsernameKey];
                                    NSString *iMSUId = [ims identifierAtIndex:i];
                                    BOOL stickyCritera = [username rangeOfString:query options:(NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound;
                                    
                                    NSInteger iMIdx = [self checkJabberStatusForUsername:username];
                                    
                                    for (NSNumber *cm in curCM) {
                                        CallType ct = [cm integerValue];
                                        switch (ct) {
                                            case CTText:
                                                [self fillBufferedResults:localBufferedResults
                                                         andStickyResults:localStickyResults
                                                withPreservingResultOrder:preserveResultOrder
                                                         andStickyCritera:stickyCritera
                                                               andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Messages-Gtalk-Username-Text\"", iMSUId]
                                                               andResultB:[NSString stringWithFormat:@" arg=\"[CTMessages]xmpp:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Messages text to Google Talk/Hangout address: %@ (%@)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", username, username, outDisplayName, username, sIMIndex2IMStatus[iMIdx], username, username, iMThumbnailPaths[iMIdx]]];
                                            default:
                                                break;
                                        }
                                    }
                                }
                            }
                            // else check gmails from email section
                            if (!foundGtalkUsername) {
                                ims = [r valueForProperty:kABEmailProperty];
                                for (int i = 0; i < [ims count]; i++) {
                                    NSString *email = [ims valueAtIndex:i];
                                    NSString *iMSUId = [ims identifierAtIndex:i];
                                    NSDictionary *processedEmailLabels = [self processLabel:[ims labelAtIndex:i]];
                                    if (![sMessagesGtalkLabels intersectsSet:processedEmailLabels[@"toConsume"]] && [email rangeOfString:@"gmail" options:NSCaseInsensitiveSearch].location == NSNotFound)
                                        // skip if it is not a gmail
                                        continue;
                                    BOOL stickyCritera = [email rangeOfString:query options:(NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound;
                                    
                                    NSInteger iMIdx = [self checkJabberStatusForUsername:email];
                                    
                                    for (NSNumber *cm in curCM) {
                                        CallType ct = [cm integerValue];
                                        switch (ct) {
                                            case CTText:
                                                [self fillBufferedResults:localBufferedResults
                                                         andStickyResults:localStickyResults
                                                withPreservingResultOrder:preserveResultOrder
                                                         andStickyCritera:stickyCritera
                                                               andResultA:[NSString stringWithFormat:@"<item uid=\"%@-Messages-Gtalk-Gmail-Text\"", iMSUId]
                                                               andResultB:[NSString stringWithFormat:@" arg=\"[CTMessages]xmpp:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Messages text to Google Talk/Hangout address: %@ (%@)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", email, email, outDisplayName, email, sIMIndex2IMStatus[iMIdx], email, email, iMThumbnailPaths[iMIdx]]];
                                                break;
                                            default:
                                                break;
                                        }
                                    }
                                }
                            }
                        }
                        
                        if (!hasNomination) {
                            // if a nominated target hasn't been found, put email results behind
                            [localBufferedResults addObjectsFromArray:localSecondaryBufferedResults];
                            [localStickyResults addObjectsFromArray:localSecondaryStickyResults];
                        }
                        
                        if (localStickyResults.count > 0 && query.length > 3)
                            [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, localBufferedResults, localStickyResults, nil];
                        
                        if ([self mergeBufferedResults:bufferedResults andStickyResults:stickyResults withLocalBufferedResults:localBufferedResults andLocalStickyResults:localStickyResults])
                            goto end_result_generation;
                    }
                    
                    break;
                }
#pragma mark _ CTWeChat
                case CTWeChat: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithRed:0.41176 green:0.56863 blue:0.67451 alpha:1];
                    NSString *weChatRecordedThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-WeChat-Recorded.tiff", uId];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:weChatRecordedThumbnailPath forRecord:r withColor:color hasShadow:YES];
                    
                    if (!isThumbNailOkay) {
                        weChatRecordedThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-WeChat-Recorded.tiff"];
#ifdef GENERATE_DEFAULT_THUMBNAILS
                        // generate default thumbnails
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:weChatRecordedThumbnailPath withColor:color hasShadow:YES];
#endif
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTText]];
                        
                        // output recorded WeChat url
                        ABMultiValue *ims = [r valueForProperty:kABURLsProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSDictionary *processedUrlLabels = [self processLabel:[ims labelAtIndex:i]];
                            if ([sWeChatLabels intersectsSet:processedUrlLabels[@"toConsume"]]) {
                                NSString *weChatUrl = [ims valueAtIndex:i];
                                NSString *iMSUId = [ims identifierAtIndex:i];
                                BOOL stickyCritera = [weChatUrl rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound;
                                if (stickyCritera && query.length > 3)
                                    [self preserveResultOrder:&preserveResultOrder withResults:bufferedResults, stickyResults, nil];

                                weChatUrl = [weChatUrl stringByRemovingPrefixes:@"weixinmac://chat/", nil];
                                
                                for (NSNumber *cm in curCM) {
                                    CallType ct = [cm integerValue];
                                    switch (ct) {
                                        case CTText:
                                            if ([self fillBufferedResults:bufferedResults
                                                         andStickyResults:stickyResults
                                                withPreservingResultOrder:preserveResultOrder
                                                         andStickyCritera:stickyCritera
                                                               andResultA:[NSString stringWithFormat:@"<item uid=\"%@-WeChat-Recorded-Text\"", iMSUId]
                                                               andResultB:[NSString stringWithFormat:@" arg=\"[CTWeChat]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>WeChat text to WeChat username: %@ (recorded)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", weChatUrl, weChatUrl, outDisplayName, weChatUrl, weChatUrl, weChatUrl, weChatRecordedThumbnailPath]])
                                                goto end_result_generation;
                                            break;
                                        default:
                                            break;
                                    }
                                }
                            }
                        }
                    }
                    
                    break;
                }
            }
        }
    }
end_result_generation:
    
    if (callType_ & CTBuildFullThumbnailCache) {
        return @"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --buildfullthumbnailcache</title><subtitle>Done. Contact thumbnail cache is now fully built</subtitle><icon>buildFullThumbnailCache.png</icon></item></items>\n";
    } else {
        for (NSArray *a in stickyResults) {
            [results appendString:[a componentsJoinedByString:@""]];
        }
        for (NSArray *a in bufferedResults) {
            [results appendString:[a componentsJoinedByString:@""]];
        }
        
        if ([results isEqualToString:[self xmlHeader]]) {
#pragma mark Generate Results If No Record Found
            NSString *origQuery = query;
            NSString *uId = nil;
            NSString *arg = nil;
            BOOL isQueryPhoneNumber = phoneNumberSearchStrings != nil;
            if (isQueryPhoneNumber) {
                // phone number takes the highest priority
                
                // formatted origianl query with extension part removed
                query = [[RMPhoneFormat instance] format:phoneNumberSearchStrings[0]];
                uId = phoneNumberSearchStrings[1];
                arg = phoneNumberSearchStrings[0];
            } else {
                query = [self xmlSimpleEscape:query];
                uId = query;
                arg = query;
            }
            BOOL isQueryEmail = [query isValidEmail:YES];
            
            for (int i = 0; i < [callTypes_ count]; i++) {
                switch ([callTypes_[i] integerValue]) {
                    case CTSkype: {
                        BOOL isQuerySkypeUsername = NO;
                        if (!isQueryPhoneNumber) {
                            if (!(isQuerySkypeUsername = [origQuery isValidSkypeUsername:YES]))
                                continue;
                        }
                            
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                        
                        for (NSNumber *cm in curCM) {
                            CallType ct = [cm integerValue];
                            switch (ct) {
                                case CTAudioCall:
                                    [results appendFormat:@"<item uid=\"%@-Skype-Audio\" arg=\"[CTSkype]%@?call&amp;video=false\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype audio call to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>", uId, arg, query, query, query, query, query];
                                    break;
                                case CTVideoCall:
                                    [results appendFormat:@"<item uid=\"%@-Skype-Video\" arg=\"[CTSkype]%@?call&amp;video=true\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype video call to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>", uId, arg, query, query, query, query, query];
                                    break;
                                case CTText:
                                    if (isQuerySkypeUsername)
                                        [results appendFormat:@"<item uid=\"%@-Skype-Text\" arg=\"[CTSkype]%@?chat\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype text to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>", uId, arg, query, query, query, query, query];
                                    break;
                                default:
                                    break;
                            }
                        }
                        break;
                    }
                    case CTFaceTime: {
                        if (isQueryPhoneNumber || isQueryEmail) {
                            NSArray *curCM;
                            if ([callModifiers_ count] > 0)
                                curCM = callModifiers_;
                            else {
                                NSNumber *defaultWorkingMode = config_[@"CTFaceTimeDefaultWorkingMode"];
                                if (defaultWorkingMode)
                                    curCM = @[defaultWorkingMode];
                                else
                                    curCM = @[[NSNumber numberWithInteger:CTVideoCall]];
                            }
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        [results appendFormat:@"<item uid=\"%@-FaceTime-Audio\" arg=\"[CTFaceTime]facetime-audio:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime audio call to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>", uId, arg, query, query, query, query, query];
                                        break;
                                    case CTVideoCall:
                                        [results appendFormat:@"<item uid=\"%@-FaceTime-Video\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime video call to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>", uId, arg, query, query, query, query, query];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        break;
                    }
                    case CTPhoneAmego: {
                        if (isQueryPhoneNumber) {
                            NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                            NSString *postd = nil;
                            if (extraPhoneNumberExtensionsBefore_.count > 0) {
                                postd = [extraPhoneNumberExtensionsBefore_[0] substringFromIndex:1];
                            } else if (extraPhoneNumberExtensionsAfter_.count > 0) {
                                postd = [extraPhoneNumberExtensionsAfter_[0] substringFromIndex:1];
                            }
                            NSString *phoneAmegoQuery = postd ? [NSString stringWithFormat:@"%@,%@", query, postd] : query;
                            
                            NSString *deviceLabel = nil;
                            if (extraParameter_) {
                                deviceLabel = config_[@"phoneAmegoDeviceAliases"][extraParameter_];
                            }
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        [results appendFormat:@"<item uid=\"%@-PhoneAmego-Audio\" arg=\"[CTPhoneAmego]%@%@%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Bluetooth audio call to: %@ via Phone Amego (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>", uId, arg, deviceLabel ? [NSString stringWithFormat:@";device=%@", deviceLabel] : @"", postd ? [NSString stringWithFormat:@";postd=%@", postd] : @"", phoneAmegoQuery, phoneAmegoQuery, phoneAmegoQuery, phoneAmegoQuery, phoneAmegoQuery];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        break;
                    }
                    case CTSIP: {
                        if (isQueryEmail || (isQueryPhoneNumber && [config_[@"CTSIPCallingPhoneNumberEnabledStatus"] boolValue])) {
                            NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                            
                            NSString *sIPUId = [uId stringByRemovingPrefixes:@"sip:", @"tel:", nil];
                            NSString *sIPArg = [arg stringByRemovingPrefixes:@"sip:", @"tel:", nil];
                            NSString *sIPQuery = [query stringByRemovingPrefixes:@"sip:", @"tel:", nil];;
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        [results appendFormat:@"<item uid=\"%@-SIP-Audio\" arg=\"[CTSIP]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>SIP audio call to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>D825394C-284F-4BC0-A8C8-3A00988225E5.png</icon></item>", sIPUId, sIPArg, sIPQuery, sIPQuery, sIPQuery, sIPQuery, sIPQuery];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        break;
                    }
                    case CTPushDialer: {
                        if (isQueryPhoneNumber) {
                            NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        [results appendFormat:@"<item uid=\"%@-PushDialer-Audio\" arg=\"[CTPushDialer]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>PushDialer audio call to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>4E251686-06AC-44A9-8C74-C6A03158E9DC.png</icon></item>", uId, arg, query, query, query, query, query];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        break;
                    }
                    case CTGrowlVoice: {
                        if (isQueryPhoneNumber) {
                            NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        [results appendFormat:@"<item uid=\"%@-GrowlVoice-Audio\" arg=\"[CTGrowlVoice]%@?call\" autocomplete=\"%@\"><title>%@</title><subtitle>Google Voice audio call to: %@ via GrowlVoice (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>07913B02-FCA2-4435-B010-A160ECC14BDF.png</icon></item>", uId, arg, query, query, query, query, query];
                                        break;
                                    case CTText:
                                        [results appendFormat:@"<item uid=\"%@-GrowlVoice-Text\" arg=\"[CTGrowlVoice]%@?text\" autocomplete=\"%@\"><title>%@</title><subtitle>Google Voice text to: %@ via GrowlVoice (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>07913B02-FCA2-4435-B010-A160ECC14BDF.png</icon></item>", uId, arg, query, query, query, query, query];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        break;
                    }
                    case CTCallTrunk: {
                        if (isQueryPhoneNumber) {
                            NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                            
                            NSString *country = nil;
                            if (extraParameter_) {
                                country = [extraParameter_ uppercaseString];
                            }
                            if (!country) {
                                country = config_[@"callTrunkDefaultCountry"];
                                if (!country) {
                                    NSDictionary *candidate = [self checkAvailableCallTrunkCountries];
                                    if ([candidate count] > 0) {
                                        country = [candidate allKeys][0]; // randomly pick an available one
                                        [config_ setObject:country forKey:@"callTrunkDefaultCountry"];
                                        [config_ writeToFile:[self configPlistPath] atomically:YES];
                                    } else {
                                        country = @"US";
                                    }
                                }
                            }
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        [results appendFormat:@"<item uid=\"%@-CallTrunk-Audio\" arg=\"[CTCallTrunk]%@/%@\" autocomplete=\"%@\"><title>%@</title><subtitle>CallTrunk audio call to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>", uId, arg, country, query, query, query, query, query];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        break;
                    }
                    case CTFritzBox: {
                        if (isQueryPhoneNumber) {
                            NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        [results appendFormat:@"<item uid=\"%@-FritzBox-Audio\" arg=\"[CTFritzBox]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Fritz!Box audio call to: %@ via Frizzix (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>05088DC0-D882-4E8B-B130-F087F7C04FC2.png</icon></item>", uId, arg, query, query, query, query, query];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        break;
                    }
                    case CTDialogue: {
                        if (isQueryPhoneNumber) {
                            NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        [results appendFormat:@"<item uid=\"%@-Dialogue-Audio\" arg=\"[CTDialogue]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Bluetooth audio call to: %@ via Dialogue (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>D47F4C69-2F33-4974-AF4F-3027EF487BCB.png</icon></item>", uId, arg, query, query, query, query, query];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        break;
                    }
                    case CTIPhone: {
                        if (isQueryPhoneNumber) {
                            NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTAudioCall]];
                            NSString *phoneNumExtensions =
                            [@[[extraPhoneNumberExtensionsBefore_ componentsJoinedByString:@""],
                               [extraPhoneNumberExtensionsAfter_ componentsJoinedByString:@""]] componentsJoinedByString:@""];
                            NSString *iPhoneQuery = [@[query, phoneNumExtensions] componentsJoinedByString:@""];
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTAudioCall:
                                        [results appendFormat:@"<item uid=\"%@-IPhone-Audio\" arg=\"[CTIPhone]%@%@\" autocomplete=\"%@\"><title>%@</title><subtitle>iPhone audio call to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>C35996F3-5CF7-4B64-9690-3D12C42A585D.png</icon></item>", uId, arg, phoneNumExtensions, iPhoneQuery, iPhoneQuery, iPhoneQuery, iPhoneQuery, iPhoneQuery];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                        break;
                    }
                    case CTMessages: {
                        if (isQueryEmail | isQueryPhoneNumber) {
                            NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTText]];
                            
                            NSNumber *rawTextingGtalkEnabledStatus = config_[@"CTMessagesTextingGtalkEnabledStatus"];
                            BOOL outputGtalk = isQueryEmail && (!rawTextingGtalkEnabledStatus || [rawTextingGtalkEnabledStatus boolValue]);
                            
                            NSInteger iMIdx = 0;
                            NSString *iMThumbnailPath = nil;
                            NSString *statusText = nil;
                            
                            if (outputGtalk) {
                                iMIdx = [self checkJabberStatusForUsername:query];
                                iMThumbnailPath = iMIdx > 0 ? [self checkAndReturnIMThumbnailPathsForUId:nil andRecord:nil][iMIdx] : @"DCE03DF2-CD83-4F89-BB02-3AEC8A6F7FEB.png";
                                statusText = iMIdx > 0 ? sIMIndex2IMStatus[iMIdx] : @"unidentified";
                            }
                            
                            for (NSNumber *cm in curCM) {
                                CallType ct = [cm integerValue];
                                switch (ct) {
                                    case CTText: {
                                        [results appendFormat:@"<item uid=\"%@-Messages-Text\" arg=\"[CTMessages]imessage:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Messages text to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>DCE03DF2-CD83-4F89-BB02-3AEC8A6F7FEB.png</icon></item>", uId, arg, query, query, query, query, query];
                                        
                                        if (outputGtalk) {
                                            [results appendFormat:@"<item uid=\"%@-Messages-Gtalk-Username-Text\" arg=\"[CTMessages]xmpp:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Messages text to: %@ (%@) via Google Talk/Hangout</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>%@</icon></item>", uId, arg, query, query, query, statusText, query, query, iMThumbnailPath];
                                        }
                                        break;
                                    }
                                    default:
                                        break;
                                }
                            }
                        }
                        break;
                    }
                    case CTWeChat: {
                        if (![origQuery isValidWeChatUsername:YES])
                            continue;
                        
                        NSArray *curCM = [callModifiers_ count] > 0 ? callModifiers_ : @[[NSNumber numberWithInteger:CTText]];
                        
                        for (NSNumber *cm in curCM) {
                            CallType ct = [cm integerValue];
                            switch (ct) {
                                case CTText:
                                    [results appendFormat:@"<item uid=\"%@-WeChat-Text\" arg=\"[CTWeChat]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>WeChat text to: %@ (unidentified)</subtitle><text type=\"copy\">%@</text><text type=\"largetype\">%@</text><icon>E2DECCAB-CDD2-459E-BACC-9FBD1CAB69EA.png</icon></item>", query, query, query, query, query, query, query];
                                    break;
                                default:
                                    break;
                            }
                        }
                        break;
                    }
                    default:
                        break;
                }
            }
        }
        
        if ([results isEqualToString:[self xmlHeader]]) {
            [results appendFormat:@"<item arg=\"\" autocomplete=\"%@\" valid=\"no\"><title>No Call Options Available</title><subtitle>Try to revise search string, relax query criteria or enable more call components</subtitle></item>", query];
        }
        
        [results appendString:@"</items>\n"];
        return results;
    }
}

static NSString *sDefaultResultA = @"<item";

- (void)preserveResultOrder:(BOOL *)shouldPreserveResultOrder withResults:(NSMutableArray *)firstResults, ...
    NS_REQUIRES_NIL_TERMINATION;
{
    if (!*shouldPreserveResultOrder) {
        *shouldPreserveResultOrder = YES;
        
        va_list args;
        va_start(args, firstResults);
        for (NSMutableArray *arg = firstResults; arg != nil; arg = va_arg(args, NSMutableArray *)) {
            for (NSMutableArray *a in arg) {
                a[0] = sDefaultResultA;
            }
        }
        va_end(args);
    }
}

- (BOOL)fillBufferedResults:(NSMutableArray *)bufferedResults andStickyResults:(NSMutableArray *)stickyResults withPreservingResultOrder:(BOOL)shouldPreserveResultOrder andStickyCritera:(BOOL)stickyCritera andResultA:(NSString *)resultA andResultB:(NSString *)resultB
{
    if (hasGeneratedOutputsForFirstContact_ && stickyResults.count + bufferedResults.count >= RESULT_NUM_LIMIT) {
        return YES;
    } else {
        NSMutableArray *newResult = [NSMutableArray arrayWithObjects:shouldPreserveResultOrder ? sDefaultResultA : resultA, resultB, nil];
        
        if (stickyCritera) {
            [stickyResults addObject:newResult];
        } else {
            [bufferedResults addObject:newResult];
        }
        return NO;
    }
}

- (BOOL)mergeBufferedResults:(NSMutableArray *)bufferedResults andStickyResults:(NSMutableArray *)stickyResults withLocalBufferedResults:(NSMutableArray *)localBufferedResults andLocalStickyResults:(NSMutableArray *)localStickyResults
{
    int resultCount = (int)stickyResults.count + (int)bufferedResults.count;
    int numOfResultsToFillIn = (int)localStickyResults.count + (int)localBufferedResults.count;
    
    if (hasGeneratedOutputsForFirstContact_) {
        int quota = MAX(RESULT_NUM_LIMIT - resultCount, 0);
        int numOfResultsToDiscard = numOfResultsToFillIn - quota;
        
        if (numOfResultsToDiscard > 0) {
            // can't fill in all buffer
            numOfResultsToFillIn -= numOfResultsToDiscard;
            
            if (numOfResultsToFillIn <= [localStickyResults count]) {
                [localStickyResults removeObjectsInRange:NSMakeRange(numOfResultsToFillIn, localStickyResults.count - numOfResultsToFillIn)];
                [localBufferedResults removeAllObjects];
            } else {
                [localBufferedResults removeObjectsInRange:NSMakeRange(localBufferedResults.count - numOfResultsToDiscard, numOfResultsToDiscard)];
            }
        }
    }
    
    [bufferedResults addObjectsFromArray:localBufferedResults];
    [stickyResults addObjectsFromArray:localStickyResults];
    
    resultCount += numOfResultsToFillIn;

    return hasGeneratedOutputsForFirstContact_ ? resultCount >= RESULT_NUM_LIMIT : NO;
}

#pragma mark -
#pragma mark Process Options

#pragma mark _ CTSkype
- (NSString *)CTSkypeOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-s\" valid=\"no\"><title>Uni Call Option -s</title><subtitle>Make a Skype call to your contact</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>";
}

- (NSString *)CTSkypeComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>Skype Call Component Code s</title><subtitle>Make a Skype call to your contact</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark _ CTFaceTime
- (NSString *)CTFaceTimeOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-f\" valid=\"no\"><title>Uni Call Option -f</title><subtitle>Make a FaceTime call to your contact</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>";
}

- (NSString *)CTFaceTimeSetDefaultWorkingModeOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-f-setdefaultworkingmode \" valid=\"no\"><title>FaceTime Call Option --setdefaultworkingmode</title><subtitle>Type \"callf --setdefaultworkingmode MODE_CODE yes\" to set the default working mode</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>";
}

- (NSString *)CTFaceTimeComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>FaceTime Call Component Code f</title><subtitle>Make a FaceTime call to your contact</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

- (NSString *)CTFaceTimeLongOptionHelp
{
    return [self CTFaceTimeSetDefaultWorkingModeOptionHelp];
}

#pragma mark _ CTPhoneAmego
- (NSString *)CTPhoneAmegoOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-p\" valid=\"no\"><title>Uni Call Option -p</title><subtitle>Make a bluetooth phone call to your contact via Phone Amego</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>";
}

- (NSString *)CTPhoneAmegoMapOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-p-map \" valid=\"no\"><title>Phone Amego Call Option --map</title><subtitle>Type \"callp --map ALIAS to DEVICE_LABEL yes\" to assign an alias to a bluetooth device</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>";
}

- (NSString *)CTPhoneAmegoUnmapOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-p-unmap \" valid=\"no\"><title>Phone Amego Call Option --unmap</title><subtitle>Type \"callp --unmap ALIAS yes\" to remove the assigned alias</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>";
}

- (NSString *)CTPhoneAmegoLongOptionHelp
{
    return [@[[self CTPhoneAmegoMapOptionHelp],
              [self CTPhoneAmegoUnmapOptionHelp]] componentsJoinedByString:@""];
}

- (NSString *)CTPhoneAmegoComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>Phone Amego Call Component Code p</title><subtitle>Make a bluetooth phone call to your contact via Phone Amego</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark _ CTSIP
- (NSString *)CTSIPOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-i\" valid=\"no\"><title>Uni Call Option -i</title><subtitle>Make a SIP call to your contact via Telephone</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5.png</icon></item>";
}

- (NSString *)CTSIPTurnCallingPhoneNumberOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-i-turncallingphonenumber \" valid=\"no\"><title>SIP Call Option --turncallingphonenumber</title><subtitle>Type \"calli --turncallingphonenumber on/off\" to enable/disable SIP phone numbers calling</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5.png</icon></item>";
}

- (NSString *)CTSIPLongOptionHelp
{
    return [self CTSIPTurnCallingPhoneNumberOptionHelp];
}

- (NSString *)CTSIPComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>SIP Call Component Code i</title><subtitle>Make a SIP call to your contact via Telephone</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark _ CTPushDialer
- (NSString *)CTPushDialerOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-d\" valid=\"no\"><title>Uni Call Option -d</title><subtitle>Make a PushDialer call to your contact</subtitle><icon>4E251686-06AC-44A9-8C74-C6A03158E9DC.png</icon></item>";
}

- (NSString *)CTPushDialerComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>PushDialer Call Component Code d</title><subtitle>Make a PushDialer call to your contact</subtitle><icon>4E251686-06AC-44A9-8C74-C6A03158E9DC%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark _ CTGrowlVoice
- (NSString *)CTGrowlVoiceOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-g\" valid=\"no\"><title>Uni Call Option -g</title><subtitle>Make a Google Voice call to your contact via GrowlVoice</subtitle><icon>07913B02-FCA2-4435-B010-A160ECC14BDF.png</icon></item>";
}

- (NSString *)CTGrowlVoiceComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>GrowlVoice Call Component Code g</title><subtitle>Make a Google Voice call to your contact via GrowlVoice</subtitle><icon>07913B02-FCA2-4435-B010-A160ECC14BDF%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark _ CTCallTrunk
- (NSString *)CTCallTrunkOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-k\" valid=\"no\"><title>Uni Call Option -k</title><subtitle>Make a CallTrunk call to your contact</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>";
}

- (NSString *)CTCallTrunkSetDefaultCountryOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-k-setdefaultcountry \" valid=\"no\"><title>CallTrunk Call Option --setdefaultcountry</title><subtitle>Type \"callk --setdefaultcountry COUNTRY_CODE yes\" to set the default country</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>";
}

- (NSString *)CTCallTrunkLongOptionHelp
{
    return [self CTCallTrunkSetDefaultCountryOptionHelp];
}

- (NSString *)CTCallTrunkComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>CallTrunk Call Component Code k</title><subtitle>Make a CallTrunk call to your contact</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark _ CTFritzBox
- (NSString *)CTFritzBoxOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-z\" valid=\"no\"><title>Uni Call Option -z</title><subtitle>Make a Fritz!Box call to your contact via Frizzix</subtitle><icon>05088DC0-D882-4E8B-B130-F087F7C04FC2.png</icon></item>";
}

- (NSString *)CTFritzBoxComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>Fritz!Box Call Component Code z</title><subtitle>Make a Fritz!Box call to your contact via Frizzix</subtitle><icon>05088DC0-D882-4E8B-B130-F087F7C04FC2%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark _ CTDialogue
- (NSString *)CTDialogueOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-l\" valid=\"no\"><title>Uni Call Option -l</title><subtitle>Make a bluetooth phone call to your contact via Dialogue</subtitle><icon>D47F4C69-2F33-4974-AF4F-3027EF487BCB.png</icon></item>";
}

- (NSString *)CTDialogueComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>Dialogue Call Component Code l</title><subtitle>Make a bluetooth phone call to your contact via Dialogue</subtitle><icon>D47F4C69-2F33-4974-AF4F-3027EF487BCB%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark _ CTIPhone
- (NSString *)CTIPhoneOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-h\" valid=\"no\"><title>Uni Call Option -h</title><subtitle>Make a phone call to your contact via iPhone (Yosemite Handoff)</subtitle><icon>C35996F3-5CF7-4B64-9690-3D12C42A585D.png</icon></item>";
}

- (NSString *)CTIPhoneComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>iPhone Call Component Code h</title><subtitle>Make a phone call to your contact via iPhone (Yosemite Handoff)</subtitle><icon>C35996F3-5CF7-4B64-9690-3D12C42A585D%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark _ CTMessages
- (NSString *)CTMessagesOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-m\" valid=\"no\"><title>Uni Call Option -m</title><subtitle>Send Message to your contact via Messages</subtitle><icon>DCE03DF2-CD83-4F89-BB02-3AEC8A6F7FEB.png</icon></item>";
}

- (NSString *)CTMessagesTurnTextingGtalkOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-m-turntextinggtalk \" valid=\"no\"><title>Messages Call Option --turntextinggtalk</title><subtitle>Type \"callm --turntextinggtalk on/off\" to enable/disable Messages Google Talk/Hangout texting</subtitle><icon>DCE03DF2-CD83-4F89-BB02-3AEC8A6F7FEB.png</icon></item>";
}

- (NSString *)CTMessagesLongOptionHelp
{
    return [self CTMessagesTurnTextingGtalkOptionHelp];
}

- (NSString *)CTMessagesComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>Messages Call Component Code m</title><subtitle>Send Message to your contact via Messages</subtitle><icon>DCE03DF2-CD83-4F89-BB02-3AEC8A6F7FEB%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark _ CTWeChat
- (NSString *)CTWeChatOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"-w\" valid=\"no\"><title>Uni Call Option -w</title><subtitle>Send Message to your contact via WeChat</subtitle><icon>E2DECCAB-CDD2-459E-BACC-9FBD1CAB69EA.png</icon></item>";
}

- (NSString *)CTWeChatComponentCodeHelpWithStatus:(NSNumber *)enabled
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>WeChat Call Component Code w</title><subtitle>Send Message to your contact via WeChat</subtitle><icon>E2DECCAB-CDD2-459E-BACC-9FBD1CAB69EA%@.png</icon></item>", [enabled boolValue] ? @"" : @"-disabled"];
}

#pragma mark Generic Short Option Help
- (NSString *)noThumbnailCacheOptionHelp
{
    return @"<item arg=\"\" valid=\"no\"><title>Uni Call Modifier -!</title><subtitle>Prohibit contact thumbnails caching</subtitle><icon>shouldNotCacheThumbnail.png</icon></item>";
}

- (NSString *)CTAudioCallOptionHelp
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>Uni Call Modifier -_ (audio)</title><subtitle>%@</subtitle><icon>CTAudioCall.png</icon></item>", sCallModifier2Desc[[NSNumber numberWithInteger:CTAudioCall]]];
}

- (NSString *)CTVideoCallOptionHelp
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>Uni Call Modifier -+ (video)</title><subtitle>%@</subtitle><icon>CTVideoCall.png</icon></item>", sCallModifier2Desc[[NSNumber numberWithInteger:CTVideoCall]]];
}

- (NSString *)CTTextOptionHelp
{
    return [NSString stringWithFormat:@"<item arg=\"\" valid=\"no\"><title>Uni Call Modifier -= (text)</title><subtitle>%@</subtitle><icon>CTText.png</icon></item>", sCallModifier2Desc[[NSNumber numberWithInteger:CTVideoCall]]];
}

#pragma mark Generic Long Option Help
- (NSString *)processingActionHelpForOption:(NSString *)option
{
    return [NSString stringWithFormat:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" valid=\"no\"><title>Uni Call Option --%@</title><subtitle>Processing... Please do not type in anything</subtitle><icon>processing.png</icon></item>", option];
}

- (NSString *)failedActionHelpForOption:(NSString *)option
{
    return [NSString stringWithFormat:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"[Cmd]%@\"><title>Uni Call Option --%@</title><subtitle>Failed. Please hit return to check your Console logs for details.</subtitle><icon>failed.png</icon></item>", [self xmlSimpleEscape:@"open -b 'com.apple.Console'"], option];
}

- (NSString *)openHelpDocumentationHelp
{
    return [NSString stringWithFormat:@"<item arg=\"[Cmd]%@\" autocomplete=\"--openhelpdocumentation\"><title>Uni Call Option --openhelpdocumentation</title><subtitle>Open Uni Call help documentation</subtitle><icon>openHelpDocumentation.png</icon></item>", [self xmlSimpleEscape:@"open 'http://unicall.guiguan.net/usage.html'"]];
}

- (NSString *)contactAuthorHelp
{
    return [NSString stringWithFormat:@"<item arg=\"[Cmd]%@\" autocomplete=\"--contactauthor\"><title>Uni Call Option --contactauthor</title><subtitle>Email user feedback to Uni Call author</subtitle><icon>contactAuthor.png</icon></item>", [self xmlSimpleEscape:[NSString stringWithFormat:@"open 'mailto:root@guiguan.net?Subject=Uni Call v%@ User Feedback&Body=Hi Guan,'", VERSION]]];
}

- (NSString *)checkForUpdateOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"--checkforupdate \" valid=\"no\"><title>Uni Call Option --checkforupdate</title><subtitle>Type \"call --checkforupdate \" to check for new Uni Call version now</subtitle><icon>update.png</icon></item>";
}

- (NSString *)turnAutoUpdateCheckingOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"--turnautoupdatechecking \" valid=\"no\"><title>Uni Call Option --turnautoupdatechecking</title><subtitle>Type \"call --turnautoupdatechecking on/off\" to enable/disable automatic update checking</subtitle><icon>update.png</icon></item>";
}

- (NSString *)enableOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"--enable \" valid=\"no\"><title>Uni Call Option --enable</title><subtitle>Type \"call --enable COMPONENT_CODES yes\" to enable call components</subtitle><icon>enableCallComponents.png</icon></item>";
}

- (NSString *)disableOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"--disable \" valid=\"no\"><title>Uni Call Option --disable</title><subtitle>Type \"call --disable COMPONENT_CODES yes\" to disable call components</subtitle><icon>disableCallComponents.png</icon></item>";
}

- (NSString *)reorderOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"--reorder \" valid=\"no\"><title>Uni Call Option --reorder</title><subtitle>Type \"call --reorder COMPONENT_CODES yes\" to change call component default order</subtitle><icon>reorderCallComponents.png</icon></item>";
}

- (NSString *)updateAlfredPreferencesOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"--updatealfredpreferences \" valid=\"no\"><title>Uni Call Option --updatealfredpreferences</title><subtitle>Type \"call --updatealfredpreferences yes\" to update Alfred Preferences to reflect your call component settings</subtitle><icon>updateAlfredPreferences.png</icon></item>";
}

- (NSString *)formatContactsPhoneNumbersOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"--formatcontactsphonenumbers \" valid=\"no\"><title>Uni Call Option --formatcontactsphonenumbers</title><subtitle>Type \"call --formatcontactsphonenumbers yes\" to format phone numbers in your Apple Contacts</subtitle><icon>appleContactsIcon.png</icon></item>";
}

- (NSString *)addContactsPhoneticNamesOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"--addcontactsphoneticnames \" valid=\"no\"><title>Uni Call Option --addcontactsphoneticnames</title><subtitle>Type \"call --addcontactsphoneticnames yes\" to add phonetic names for 中文名 in your Apple Contacts</subtitle><icon>appleContactsIcon.png</icon></item>";
}

- (NSString *)buildFullThumbnailCacheOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"--buildfullthumbnailcache \" valid=\"no\"><title>Uni Call Option --buildfullthumbnailcache</title><subtitle>Type \"call --buildfullthumbnailcache yes\" to start building full contact thumbnail cache</subtitle><icon>buildFullThumbnailCache.png</icon></item>";
}

- (NSString *)destroyThumbnailCacheOptionHelp
{
    return @"<item arg=\"\" autocomplete=\"--destroythumbnailcache \" valid=\"no\"><title>Uni Call Option --destroythumbnailcache</title><subtitle>Type \"call --destroythumbnailcache yes\" to start destroying contact thumbnail cache</subtitle><icon>destroyThumbnailCache.png</icon></item>";
}

- (NSString *)longOptionHelp
{
    NSMutableString *s = [NSMutableString string];
    
    void (^outputLongOptionForCallType)(CallType) = ^(CallType ct) {
        if (callType_ & ct || !(callType_ & sAllCallTypes)) {
            if ([self respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"%@LongOptionHelp", sCallType2Names[[NSNumber numberWithInteger:ct]]])]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [s appendString:[self performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@LongOptionHelp", sCallType2Names[[NSNumber numberWithInteger:ct]]])]];
                #pragma clang diagnostic pop
            }
        }
    };
    
    if (callTypes_.count > 0) {
        for (NSNumber *rawCt in callTypes_) {
            CallType ct = [rawCt integerValue];
            outputLongOptionForCallType(ct);
        }
    } else {
        for (int i = 0; i < callTypeDefaultOrder_.length; i++) {
            CallType ct = [sComponentCode2CallType[[callTypeDefaultOrder_ substringWithRange:NSMakeRange(i, 1)]] integerValue];
            outputLongOptionForCallType(ct);
        }
    }
    
    return [@[!(callType_ & sAllCallTypes) ? [@[[self openHelpDocumentationHelp],
                                                [self contactAuthorHelp],
                                                [self checkForUpdateOptionHelp],
                                                [self enableOptionHelp],
                                                [self disableOptionHelp],
                                                [self reorderOptionHelp]] componentsJoinedByString:@""] : @"",
               s,
               !(callType_ & sAllCallTypes) ? [@[[self updateAlfredPreferencesOptionHelp],
                                                 [self formatContactsPhoneNumbersOptionHelp],
                                                 [self addContactsPhoneticNamesOptionHelp],
                                                 [self buildFullThumbnailCacheOptionHelp],
                                                 [self destroyThumbnailCacheOptionHelp],
                                                 [self turnAutoUpdateCheckingOptionHelp]] componentsJoinedByString:@""] : @""] componentsJoinedByString:@""];
}

- (NSString *)outputHelpOnOptions
{
    NSMutableString *s = [NSMutableString string];
    for (int i = 0; i < callTypeDefaultOrder_.length; i++) {
        CallType ct = [sComponentCode2CallType[[callTypeDefaultOrder_ substringWithRange:NSMakeRange(i, 1)]] integerValue];
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [s appendString:[self performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@OptionHelp", sCallType2Names[[NSNumber numberWithInteger:ct]]])]];
        #pragma clang diagnostic pop
    }
    return [@[[NSString stringWithFormat:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" valid=\"no\"><title>List of Uni Call Options</title><subtitle>v%@: type \"-\" plus any combination of \"a_+=!%@\"; type \"--\" for long options</subtitle><icon>icon.png</icon></item>", VERSION, [self getComponentCodesFromCallType:enabledCallType_]], @"<item arg=\"\" autocomplete=\"-a\" valid=\"no\"><title>Uni Call Option -a (default)</title><subtitle>Lay out all default call options for your contact</subtitle><icon>defaultCall.png</icon></item>", [self CTAudioCallOptionHelp], [self CTVideoCallOptionHelp], [self CTTextOptionHelp], [self noThumbnailCacheOptionHelp],
              s,
              [self longOptionHelp],
              @"</items>\n"] componentsJoinedByString:@""];
}

- (NSString *)postProcessCallTypeOptionsWithOutputingOptionHelp:(BOOL)optionHelp
{
    NSMutableString *help = nil;
    if (optionHelp)
        help = [NSMutableString string];
    CallType nonSearchableOptions = callType_ & sNonSearchableOptions; // backup
    for (NSNumber *rawCT in callModifiers_) {
        CallType ct = [rawCT integerValue];
        if (nonSearchableOptions & ct) {
            callType_ &= [self getSetValueForCallModifier:ct];
            if (optionHelp) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [help appendString:[self performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@OptionHelp", sCallType2Names[rawCT]])]];
                #pragma clang diagnostic pop
            }
        }
    }
    
    if (nonSearchableOptions & CTNoThumbnailCache) {
        if (optionHelp)
            [help appendString:[self noThumbnailCacheOptionHelp]];
    }

    callType_ |= nonSearchableOptions; // restore
    NSMutableIndexSet *toBeRemoved = [NSMutableIndexSet indexSet];
    [callTypes_ enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CallType curType = [obj integerValue];
        if (!(curType & callType_)) {
            [toBeRemoved addIndex:idx];
        } else {
            if (optionHelp) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [help appendString:[self performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@OptionHelp", sCallType2Names[obj]])]];
                #pragma clang diagnostic pop
            }
        }
    }];
    [callTypes_ removeObjectsAtIndexes:toBeRemoved];
    return help;
}

- (NSString *)getComponentCodesFromCallType:(CallType)callType
{
    NSMutableString *results = [NSMutableString string];
    for (NSNumber *rawCT in sCallTypeDefault) {
        CallType ct = [rawCT integerValue];
        if (callType & ct)
            [results appendString:sCallType2ComponentCode[rawCT]];
    }
    return results;
}

- (CallType)getCallTypeFromComponentCodes:(NSString *)codes
{
    CallType tmp = 0;
    for (int i = 0; i < [codes length]; i++) {
        tmp |= [sComponentCode2CallType[[codes substringWithRange:NSMakeRange(i, 1)]] integerValue];
    }
    // remove non-searchable options
    tmp &= sAllCallTypes;
    return tmp;
}

- (void)manipulateInfoPlistWithComponentName:(NSString *)componentName andOperation:(NSString *)operation andInfoPlist:(NSMutableDictionary *)infoPlist andPrefLibPlist:(NSDictionary *)prefLibPlist
{
    if ([operation isEqualToString:@"remove"]) {
        // remove
        NSDictionary *componentsToBeRemoved = prefLibPlist[componentName];
        [infoPlist[@"connections"] removeObjectsForKeys:[componentsToBeRemoved[@"connections"] allKeys]];
        NSMutableIndexSet *indicesToBeRemoved = [NSMutableIndexSet indexSet];
        NSArray *desObjects = infoPlist[@"objects"];
        for (NSDictionary *srcDict in componentsToBeRemoved[@"objects"]) {
            for (NSUInteger i = 0; i < [desObjects count]; i++) {
                if ([desObjects[i][@"uid"] isEqualToString:srcDict[@"uid"]])
                    [indicesToBeRemoved addIndex:i];
            }
        }
        [infoPlist[@"objects"] removeObjectsAtIndexes:indicesToBeRemoved];
        [infoPlist[@"uidata"] removeObjectsForKeys:[componentsToBeRemoved[@"uidata"] allKeys]];
    } else if ([operation isEqualToString:@"add"]) {
        // add
        NSDictionary *componentsToBeAdded = prefLibPlist[componentName];
        [infoPlist[@"connections"] addEntriesFromDictionary:componentsToBeAdded[@"connections"]];
        NSMutableArray *desObjects = infoPlist[@"objects"];
        for (NSDictionary *srcDict in componentsToBeAdded[@"objects"]) {
            BOOL exists = NO;
            for (NSUInteger i = 0; i < [desObjects count]; i++) {
                if ([desObjects[i][@"uid"] isEqualToString:srcDict[@"uid"]]) {
                    exists = YES;
                    break;
                }
            }
            if (!exists)
                [desObjects addObject:srcDict];
        }
        [infoPlist[@"uidata"] addEntriesFromDictionary:componentsToBeAdded[@"uidata"]];
    }
}

// YES: should exit immediately
- (BOOL)processOptions:(NSString *)options withRestQueryMatches:(NSArray *)restQueryMatches andQuery:(NSString *)query andResults:(NSMutableString *)results
{
    for (int i = 1; i < [options length]; i++) {
        NSString *option = [options substringWithRange:NSMakeRange(i, 1)];
        if ([option isEqualToString:@"-"]) {
            // long options
            [results setString:[self xmlHeader]];
            
            if (i + 1 < [options length]) {
                NSString *longOption = [options substringFromIndex:i + 1];

                if (!(callType_ & sAllCallTypes)) {
#pragma mark Handle Hidden Long Options
                    // this option should only be used privately
                    if ([longOption isEqualToString:@"[Update]"]) {
                        
                    }
                    
#pragma mark Handle Most Used Generic Long Options
                    if ([@"openhelpdocumentation" hasPrefix:longOption]) {
                        [results appendString:[self openHelpDocumentationHelp]];
                    }
                    
                    if ([@"contactauthor" hasPrefix:longOption]) {
                        [results appendString:[self contactAuthorHelp]];
                    }
                    
                    if ([@"checkforupdate" hasPrefix:longOption]) {
                        if ([longOption isEqualToString:@"checkforupdate"]) {
                            
                            // each long option should have their own set of action status
                            typedef NS_ENUM(NSInteger, ActionStatus)
                            {
                                ASHasUpdate,
                                ASNoUpdate,
                                ASFailed,
                                ASIdle,
                                ASChecking
                            };
                            
                            static ActionStatus sessionStatus = ASIdle;
                            static double versionNum = -1;
                            
                            switch (sessionStatus) {
                                case ASIdle: {
                                    if (restQueryMatches && [restQueryMatches count] == 1 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] isEqualToString:@"yes"]) {
                                        versionNum = -1;
                                        [updater_ checkForUpdateAndDeliverNotification:NO withCompletion:^(UpdateActionStatus result, double newVersionNum) {
                                            sessionStatus = (ActionStatus)result;
                                            versionNum = newVersionNum;
                                            [self invokeAlfredWithCommand:@"call --checkforupdate"];
                                        }];
                                    } else {
                                        [results appendString:[self checkForUpdateOptionHelp]];
                                        break;
                                    }
                                }
                                case ASChecking:
                                    [results setString:[self processingActionHelpForOption:@"checkforupdate"]];
                                    return YES;
                                case ASHasUpdate:
                                    sessionStatus = ASIdle;
                                    [results setString:[NSString stringWithFormat:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --checkforupdate</title>A new version (v%lf) of Uni Call is available. Hit return to upgrade<subtitle></subtitle><icon>succeeded.png</icon></item>", versionNum]];
                                    return YES;
                                case ASNoUpdate:
                                    sessionStatus = ASIdle;
                                    [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --checkforupdate</title><subtitle>Done. All Apple Contacts phone numbers are now formatted to their regional formats</subtitle><icon>succeeded.png</icon></item>"];
                                    return YES;
                                case ASFailed:
                                    sessionStatus = ASIdle;
                                    [results setString:[self failedActionHelpForOption:@"checkforupdate"]];
                                    return YES;
                            }
                        } else {
                            [results appendString:[self checkForUpdateOptionHelp]];
                        }
                    }
                    
                    if ([@"enable" hasPrefix:longOption]) {
                        if ([longOption isEqualToString:@"enable"]) {
                            if (restQueryMatches && [restQueryMatches count] == 2 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"yes"]) {
                                NSString *rawSelectedCodes = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                CallType selectedCodes = [self getCallTypeFromComponentCodes:rawSelectedCodes];
                                CallType changedCodes = enabledCallType_;
                                enabledCallType_ |= selectedCodes;
                                callTypeDefaultOrder_ = [self deriveCallComponentOrderFrom:[@[rawSelectedCodes, callTypeDefaultOrder_] componentsJoinedByString:@""] andFrom:[self getComponentCodesFromCallType:enabledCallType_]];
                                [config_ setObject:callTypeDefaultOrder_ forKey:@"callComponentDefaultOrder"];
                                
                                changedCodes ^= enabledCallType_;
                                NSString *operation = @"add";
                                
                                NSMutableDictionary *infoPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"]];
                                NSDictionary *prefLibPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/prefLib.plist"]];
                                
                                for (NSInteger i = CALLTYPE_BOUNDARY_HIGH; i >= CALLTYPE_BOUNDARY_LOW; i--) {
                                    CallType ct = 1 << i;
                                    if (changedCodes & ct)
                                        [self manipulateInfoPlistWithComponentName:sCallType2Names[[NSNumber numberWithInteger:ct]] andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                }
                                
                                [infoPlist writeToFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"] atomically:YES];
                                
                                [config_ setObject:[NSNumber numberWithInteger:(enabledCallType_ >> CALLTYPE_BOUNDARY_LOW)] forKey:@"callComponentStatus"];
                                [config_ writeToFile:[self configPlistPath] atomically:YES];
                                
                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --enable</title><subtitle>Done. Now your selected call components are enabled</subtitle><icon>enableCallComponents.png</icon></item>"];
                            } else {
                                [results setString:[self xmlHeader]];
                                [results appendString:[self enableOptionHelp]];
                                CallType previewCodes = 0;
                                if (restQueryMatches && [restQueryMatches count] > 0)
                                    previewCodes = [self getCallTypeFromComponentCodes:[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]]];
                                
                                for (NSInteger i = CALLTYPE_BOUNDARY_HIGH; i >= CALLTYPE_BOUNDARY_LOW; i--) {
                                    CallType ct = 1 << i;
                                    if (!(enabledCallType_ & ct)) {
                                        #pragma clang diagnostic push
                                        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                                        [results appendString:[self performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@ComponentCodeHelpWithStatus:", sCallType2Names[[NSNumber numberWithInteger:ct]]]) withObject:[NSNumber numberWithBool:(previewCodes & ct) > 0]]];
                                        #pragma clang diagnostic pop
                                    }
                                }
                            }
                            return YES;
                        } else {
                            [results appendString:[self enableOptionHelp]];
                        }
                    }
                    
                    if ([@"disable" hasPrefix:longOption]) {
                        if ([longOption isEqualToString:@"disable"]) {
                            if (restQueryMatches && [restQueryMatches count] == 2 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"yes"]) {
                                CallType selectedCodes = [self getCallTypeFromComponentCodes:[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]]];
                                CallType changedCodes = enabledCallType_;
                                enabledCallType_ = enabledCallType_ & (enabledCallType_ ^ selectedCodes);
                                callTypeDefaultOrder_ = [self deriveCallComponentOrderFrom:callTypeDefaultOrder_ andFrom:[self getComponentCodesFromCallType:enabledCallType_]];
                                [config_ setObject:callTypeDefaultOrder_ forKey:@"callComponentDefaultOrder"];
                                
                                changedCodes &= selectedCodes;
                                NSString *operation = @"remove";
                                
                                NSMutableDictionary *infoPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"]];
                                NSDictionary *prefLibPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/prefLib.plist"]];
                                
                                for (NSInteger i = CALLTYPE_BOUNDARY_HIGH; i >= CALLTYPE_BOUNDARY_LOW; i--) {
                                    CallType ct = 1 << i;
                                    if (changedCodes & ct)
                                        [self manipulateInfoPlistWithComponentName:sCallType2Names[[NSNumber numberWithInteger:ct]] andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                }

                                [infoPlist writeToFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"] atomically:YES];
                                
                                [config_ setObject:[NSNumber numberWithInteger:(enabledCallType_ >> CALLTYPE_BOUNDARY_LOW)] forKey:@"callComponentStatus"];
                                [config_ writeToFile:[self configPlistPath] atomically:YES];
                                
                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --disable</title><subtitle>Done. Now your selected call components are disabled</subtitle><icon>disableCallComponents.png</icon></item>"];
                            } else {
                                [results setString:[self xmlHeader]];
                                [results appendString:[self disableOptionHelp]];
                                CallType previewCodes = 0;
                                if (restQueryMatches && [restQueryMatches count] > 0)
                                    previewCodes = [self getCallTypeFromComponentCodes:[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]]];
                                for (int i = (int)callTypeDefaultOrder_.length - 1; i >= 0; i--) {
                                    CallType ct = [sComponentCode2CallType[[callTypeDefaultOrder_ substringWithRange:NSMakeRange(i, 1)]] integerValue];
                                    if (enabledCallType_ & ct) {
                                        #pragma clang diagnostic push
                                        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                                        [results appendString:[self performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@ComponentCodeHelpWithStatus:", sCallType2Names[[NSNumber numberWithInteger:ct]]]) withObject:[NSNumber numberWithBool:(previewCodes & ct) == 0]]];
                                        #pragma clang diagnostic pop

                                    }
                                }
                            }
                            return YES;
                        } else {
                            [results appendString:[self disableOptionHelp]];
                        }
                    }
                    
                    if ([@"reorder" hasPrefix:longOption]) {
                        if ([longOption isEqualToString:@"reorder"]) {
                            if (restQueryMatches && [restQueryMatches count] == 2 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"yes"]) {
                                callTypeDefaultOrder_ = [self deriveCallComponentOrderFrom:[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] andFrom:callTypeDefaultOrder_];
                                [config_ setObject:callTypeDefaultOrder_ forKey:@"callComponentDefaultOrder"];
                                [config_ writeToFile:[self configPlistPath] atomically:YES];
                                
                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --reorder</title><subtitle>Done. Now your call component default order is saved</subtitle><icon>reorderCallComponents.png</icon></item>"];
                            } else {
                                [results setString:[self xmlHeader]];
                                [results appendString:[self reorderOptionHelp]];
                                NSString *previewOrder = @"";
                                if (restQueryMatches && [restQueryMatches count] > 0) {
                                    previewOrder = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                }
                                previewOrder = [self deriveCallComponentOrderFrom:previewOrder andFrom:callTypeDefaultOrder_];
                                for (int i = 0; i < previewOrder.length; i++) {
                                    CallType ct = [sComponentCode2CallType[[previewOrder substringWithRange:NSMakeRange(i, 1)]] integerValue];
                                    #pragma clang diagnostic push
                                    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                                    [results appendString:[self performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@ComponentCodeHelpWithStatus:", sCallType2Names[[NSNumber numberWithInteger:ct]]]) withObject:[NSNumber numberWithBool:YES]]];
                                    #pragma clang diagnostic pop
                                }
                            }
                            return YES;
                        } else {
                            [results appendString:[self reorderOptionHelp]];
                        }
                    }
                }

#pragma mark Handle Call Component Specific Long Options
                for (int i = 0; i < callTypeDefaultOrder_.length; i++) {
                    switch ([callTypeDefaultOrder_ characterAtIndex:i]) {
                        case 'f': {
                            if (callType_ & CTFaceTime || !(callType_ & sAllCallTypes)) {
                                if ([@"setdefaultworkingmode" hasPrefix:longOption]) {
                                    if ([longOption isEqualToString:@"setdefaultworkingmode"]) {
                                        NSArray *availableWorkingModes = @[[NSNumber numberWithInteger:CTAudioCall], [NSNumber numberWithInteger:CTVideoCall]];
                                        
                                        if (restQueryMatches && [restQueryMatches count] == 2 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"yes"]) {
                                            NSString *chosenWorkingModeCode = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                            NSNumber *rawChosenWorkingMode = sComponentCode2CallType[chosenWorkingModeCode];
                                            if ([availableWorkingModes containsObject:rawChosenWorkingMode]) {
                                                [config_ setObject:rawChosenWorkingMode forKey:@"CTFaceTimeDefaultWorkingMode"];
                                                [config_ writeToFile:[self configPlistPath] atomically:YES];
                                                
                                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>FaceTime Call Option --setdefaultworkingmode</title><subtitle>Done. The default working mode for FaceTime has now been set.</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>"];
                                            } else {
                                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"error\" arg=\"\" valid=\"no\"><title>FaceTime Call Option --setdefaultworkingmode</title><subtitle>Error: the mode code is invalid!</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>"];
                                            }
                                        } else {
                                            [results setString:[self xmlHeader]];
                                            [results appendString:[self CTFaceTimeSetDefaultWorkingModeOptionHelp]];
                                            
                                            NSNumber *rawDefaultWorkingMode = config_[@"CTFaceTimeDefaultWorkingMode"];
                                            NSString *previewWorkingModeCode = nil;
                                            
                                            if (restQueryMatches && [restQueryMatches count] > 0) {
                                                previewWorkingModeCode = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                            }
                                            
                                            for (NSNumber *rawM in availableWorkingModes) {
                                                NSString *mC = sCallType2ComponentCode[rawM];
                                                [results appendFormat:@"<item arg=\"\" valid=\"no\"><title>Mode Code %@</title><subtitle>%@</subtitle><icon>%@.png</icon></item>", mC, rawDefaultWorkingMode && [rawM isEqualToNumber:rawDefaultWorkingMode] ? [NSString stringWithFormat:@"%@ (current default)", sCallModifier2Desc[rawM]] : sCallModifier2Desc[rawM], (previewWorkingModeCode && [mC isEqualToString:previewWorkingModeCode]) || (!previewWorkingModeCode && rawDefaultWorkingMode && [rawM isEqualToNumber:rawDefaultWorkingMode]) ? [NSString stringWithFormat:@"%@", sCallType2Names[rawM]] : [NSString stringWithFormat:@"%@-bw", sCallType2Names[rawM]]];
                                            }
                                        }
                                        
                                        return YES;
                                    } else {
                                        [results appendString:[self CTFaceTimeSetDefaultWorkingModeOptionHelp]];
                                    }
                                }
                            }
                            break;
                        }
                        case 'p': {
                            if (callType_ & CTPhoneAmego || !(callType_ & sAllCallTypes)) {
                                if ([@"map" hasPrefix:longOption]) {
                                    if ([longOption isEqualToString:@"map"]) {
                                        [results setString:[self xmlHeader]];
                                        [results appendString:[self CTPhoneAmegoMapOptionHelp]];
                                        
                                        NSMutableDictionary *phoneAmegoDeviceAliases = config_[@"phoneAmegoDeviceAliases"];
                                        
                                        if (!phoneAmegoDeviceAliases) {
                                            config_[@"phoneAmegoDeviceAliases"] = [[NSMutableDictionary alloc] init];
                                            phoneAmegoDeviceAliases = config_[@"phoneAmegoDeviceAliases"];
                                        }
                                        
                                        if (restQueryMatches && [restQueryMatches count] == 4 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"to"] && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[3]]] isEqualToString:@"yes"]) {
                                            // should apply the alias mapping
                                            NSString *chosenAlias = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                            NSString *deviceLabel = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[2]]];
                                            
                                            phoneAmegoDeviceAliases[chosenAlias] = deviceLabel;
                                            [config_ writeToFile:[self configPlistPath] atomically:YES];
                                            
                                            [results setString:[NSString stringWithFormat:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-p-\" valid=\"no\"><title>Phone Amego Call Option --map</title><subtitle>Done. Assigned alias %@ to device %@</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>", chosenAlias, deviceLabel]];
                                        } else if (restQueryMatches && [restQueryMatches count] >= 3 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"to"]) {
                                            // alias has chosen
                                            NSString *chosenAlias = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                            NSString *deviceLabel = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[2]]];
                                            
                                            [results appendFormat:@"<item arg=\"\" valid=\"no\"><title>%@ to %@</title><subtitle>Type \"callp TARGET /%@\" to call the TARGET through device %@</subtitle><icon>edit-active.png</icon></item>", chosenAlias, deviceLabel, chosenAlias, deviceLabel];
                                        } else if (restQueryMatches && [restQueryMatches count] >= 1) {
                                            // show existing mappings whose prefixes match the typed alias
                                            BOOL hasMatch = NO;
                                            NSString *chosenAlias = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                            
                                            for (NSString *key in [phoneAmegoDeviceAliases allKeys]) {
                                                if ([key hasPrefix:chosenAlias]) {
                                                    hasMatch = YES;
                                                    NSString *value = phoneAmegoDeviceAliases[key];
                                                    [results appendFormat:@"<item arg=\"\" valid=\"no\"><title>%@ to %@</title><subtitle>Type \"callp TARGET /%@\" to call the TARGET through device %@</subtitle><icon>edit-inactive.png</icon></item>", key, value, key, value];
                                                }
                                            }
                                            
                                            if (!hasMatch)
                                                [results appendFormat:@"<item arg=\"\" valid=\"no\"><title>%@ to SOME_DEVICE</title><subtitle>Type \"callp TARGET /%@\" to call the TARGET through device SOME_DEVICE</subtitle><icon>edit-active.png</icon></item>", chosenAlias, chosenAlias];
                                        } else {
                                            // show all alias
                                            for (NSString *key in [phoneAmegoDeviceAliases allKeys]) {
                                                NSString *value = phoneAmegoDeviceAliases[key];
                                                [results appendFormat:@"<item arg=\"\" valid=\"no\"><title>%@ to %@</title><subtitle>Type \"callp TARGET /%@\" to call the TARGET through device %@</subtitle><icon>edit-inactive.png</icon></item>", key, value, key, value];
                                            }
                                        }
                                        
                                        return YES;
                                    } else {
                                        [results appendString:[self CTPhoneAmegoMapOptionHelp]];
                                    }
                                }
                                
                                if ([@"unmap" hasPrefix:longOption]) {
                                    if ([longOption isEqualToString:@"unmap"]) {
                                        [results setString:[self xmlHeader]];
                                        [results appendString:[self CTPhoneAmegoUnmapOptionHelp]];
                                        
                                        NSMutableDictionary *phoneAmegoDeviceAliases = config_[@"phoneAmegoDeviceAliases"];
                                        
                                        if (!phoneAmegoDeviceAliases) {
                                            return YES;
                                        }
                                        
                                        if (restQueryMatches && [restQueryMatches count] == 2 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"yes"]) {
                                            // should remove the alias mapping of the first match
                                            NSString *chosenAlias = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                            NSString *actualAlias = nil;
                                            
                                            for (NSString *key in [phoneAmegoDeviceAliases allKeys]) {
                                                if ([key hasPrefix:chosenAlias]) {
                                                    actualAlias = key;
                                                }
                                            }
                                            
                                            if (actualAlias) {
                                                [results setString:[NSString stringWithFormat:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-p-\" valid=\"no\"><title>Phone Amego Call Option --unmap</title><subtitle>Done. Removed alias %@ to device %@</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>", actualAlias, phoneAmegoDeviceAliases[actualAlias]]];
                                                
                                                [phoneAmegoDeviceAliases removeObjectForKey:actualAlias];
                                                [config_ writeToFile:[self configPlistPath] atomically:YES];
                                                return YES;
                                            }
                                        }
                                        
                                        if (restQueryMatches && [restQueryMatches count] >= 1) {
                                            // show existing mappings whose prefixes match the typed alias
                                            BOOL isFirstMatch = YES;
                                            NSString *chosenAlias = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                            
                                            for (NSString *key in [phoneAmegoDeviceAliases allKeys]) {
                                                if ([key hasPrefix:chosenAlias]) {
                                                    NSString *value = phoneAmegoDeviceAliases[key];
                                                    [results appendFormat:@"<item arg=\"\" valid=\"no\"><title>%@ to %@</title><subtitle>Type \"callp TARGET /%@\" to call the TARGET through device %@</subtitle><icon>edit-%@.png</icon></item>", key, value, key, value, isFirstMatch ? @"active" : @"inactive"];
                                                    isFirstMatch = NO;
                                                }
                                            }
                                        } else {
                                            // show all alias
                                            for (NSString *key in [phoneAmegoDeviceAliases allKeys]) {
                                                NSString *value = phoneAmegoDeviceAliases[key];
                                                [results appendFormat:@"<item arg=\"\" valid=\"no\"><title>%@ to %@</title><subtitle>Type \"callp TARGET /%@\" to call the TARGET through device %@</subtitle><icon>edit-inactive.png</icon></item>", key, value, key, value];
                                            }
                                        }
                                        
                                        return YES;
                                    } else {
                                        [results appendString:[self CTPhoneAmegoUnmapOptionHelp]];
                                    }
                                }
                            }
                            break;
                        }
                        case 'i': {
                            if (callType_ & CTSIP || !(callType_ & sAllCallTypes)) {
                                if ([@"turncallingphonenumber" hasPrefix:longOption]) {
                                    if ([longOption isEqualToString:@"turncallingphonenumber"] && restQueryMatches && [restQueryMatches count] == 1) {
                                        NSString *input = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                        
                                        if ([input isEqualToString:@"on"]) {
                                            [config_ setObject:[NSNumber numberWithBool:YES] forKey:@"CTSIPCallingPhoneNumberEnabledStatus"];
                                            [config_ writeToFile:[self configPlistPath] atomically:YES];
                                            
                                            [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>SIP Call Option --turncallingphonenumber</title><subtitle>Done. Calling phone numbers using SIP is now enabled.</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5.png</icon></item>"];
                                            
                                            return YES;
                                        } else if([input isEqualToString:@"off"]) {
                                            [config_ setObject:[NSNumber numberWithBool:NO] forKey:@"CTSIPCallingPhoneNumberEnabledStatus"];
                                            [config_ writeToFile:[self configPlistPath] atomically:YES];
                                            
                                            [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>SIP Call Option --turncallingphonenumber</title><subtitle>Done. Calling phone numbers using SIP is now disabled.</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5.png</icon></item>"];
                                            
                                            return YES;
                                        } else
                                            [results appendString:[self CTSIPTurnCallingPhoneNumberOptionHelp]];
                                    } else {
                                        [results appendString:[self CTSIPTurnCallingPhoneNumberOptionHelp]];
                                    }
                                }
                            }
                            break;
                        }
                        case 'k': {
                            if (callType_ & CTCallTrunk || !(callType_ & sAllCallTypes)) {
                                if ([@"setdefaultcountry" hasPrefix:longOption]) {
                                    if ([longOption isEqualToString:@"setdefaultcountry"]) {
                                        NSDictionary *availableCountries = [self checkAvailableCallTrunkCountries];
                                        
                                        if (restQueryMatches && [restQueryMatches count] == 2 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"yes"]) {
                                            NSString *chosenCountry = [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] uppercaseString];
                                            if (availableCountries[chosenCountry]) {
                                                [config_ setObject:chosenCountry forKey:@"callTrunkDefaultCountry"];
                                                [config_ writeToFile:[self configPlistPath] atomically:YES];
                                                
                                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>CallTrunk Call Option --setdefaultcountry</title><subtitle>Done. The default country for CallTrunk has now been set.</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>"];
                                            } else {
                                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"error\" arg=\"\" valid=\"no\"><title>CallTrunk Call Option --setdefaultcountry</title><subtitle>Error: the country code is invalid! Please make sure you have installed the country specific Call Trunck app</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>"];
                                            }
                                        } else {
                                            [results setString:[self xmlHeader]];
                                            [results appendString:[self CTCallTrunkSetDefaultCountryOptionHelp]];
                                            
                                            NSString *callTrunkDefaultCountry = config_[@"callTrunkDefaultCountry"];
                                            NSString *previewCountry = nil;
                                            
                                            if (restQueryMatches && [restQueryMatches count] > 0) {
                                                previewCountry = [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] uppercaseString];
                                            }
                                            
                                            for (NSString *c in availableCountries) {
                                                [results appendFormat:@"<item arg=\"\" valid=\"no\"><title>Country Code %@</title><subtitle>%@</subtitle><icon>country%@.png</icon></item>", c, [c isEqualToString:callTrunkDefaultCountry] ? [NSString stringWithFormat:@"%@ (current default)", availableCountries[c]] : availableCountries[c], [c isEqualToString:previewCountry] || (!previewCountry && [c isEqualToString:callTrunkDefaultCountry]) ? [NSString stringWithFormat:@"%@-chosen", c] : c];
                                            }
                                        }
                                        
                                        return YES;
                                    } else {
                                        [results appendString:[self CTCallTrunkSetDefaultCountryOptionHelp]];
                                    }
                                }
                            }
                            break;
                        }
                        case 'm': {
                            if (callType_ & CTMessages || !(callType_ & sAllCallTypes)) {
                                if ([@"turntextinggtalk" hasPrefix:longOption]) {
                                    if ([longOption isEqualToString:@"turntextinggtalk"] && restQueryMatches && [restQueryMatches count] == 1) {
                                        NSString *input = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                        
                                        if ([input isEqualToString:@"on"]) {
                                            [config_ setObject:[NSNumber numberWithBool:YES] forKey:@"CTMessagesTextingGtalkEnabledStatus"];
                                            [config_ writeToFile:[self configPlistPath] atomically:YES];
                                            
                                            [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Messages Call Option --turntextinggtalk</title><subtitle>Done. Texting Google Talk/Hangout using Messages is now enabled.</subtitle><icon>DCE03DF2-CD83-4F89-BB02-3AEC8A6F7FEB.png</icon></item>"];
                                            
                                            return YES;
                                        } else if([input isEqualToString:@"off"]) {
                                            [config_ setObject:[NSNumber numberWithBool:NO] forKey:@"CTMessagesTextingGtalkEnabledStatus"];
                                            [config_ writeToFile:[self configPlistPath] atomically:YES];
                                            
                                            [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Messages Call Option --turntextinggtalk</title><subtitle>Done. Texting Google Talk/Hangout using Messages is now disabled.</subtitle><icon>DCE03DF2-CD83-4F89-BB02-3AEC8A6F7FEB.png</icon></item>"];
                                            
                                            return YES;
                                        } else
                                            [results appendString:[self CTMessagesTurnTextingGtalkOptionHelp]];
                                    } else {
                                        [results appendString:[self CTMessagesTurnTextingGtalkOptionHelp]];
                                    }
                                }
                            }
                            break;
                        }
                    }
                }
            
#pragma mark Handle Least Used Generic Long Options
                if (!(callType_ & sAllCallTypes)) {
                    if ([@"updatealfredpreferences" hasPrefix:longOption]) {
                        if ([longOption isEqualToString:@"updatealfredpreferences"] && restQueryMatches && [restQueryMatches count] == 1 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] isEqualToString:@"yes"]) {
                            NSMutableDictionary *infoPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"]];
                            NSDictionary *prefLibPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/prefLib.plist"]];
                            
                            for (NSInteger i = CALLTYPE_BOUNDARY_LOW; i <= CALLTYPE_BOUNDARY_HIGH; i++) {
                                CallType ct = 1 << i;
                                
                                if (enabledCallType_ & ct)
                                    [self manipulateInfoPlistWithComponentName:sCallType2Names[[NSNumber numberWithInteger:ct]] andOperation:@"add" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                else
                                    [self manipulateInfoPlistWithComponentName:sCallType2Names[[NSNumber numberWithInteger:ct]] andOperation:@"remove" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                            }
                            
                            [infoPlist writeToFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"] atomically:YES];
                            
                            [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --updatealfredpreferences</title><subtitle>Done. Your Alfred Preferences are now updated to reflect your call component settings</subtitle><icon>updateAlfredPreferences.png</icon></item>"];
                            return YES;
                        } else {
                            [results appendString:[self updateAlfredPreferencesOptionHelp]];
                        }
                    }
                    
                    if ([@"formatcontactsphonenumbers" hasPrefix:longOption]) {
                        if ([longOption isEqualToString:@"formatcontactsphonenumbers"]) {
                            
                            // each long option should have their own set of action status
                            typedef NS_ENUM(NSInteger, ActionStatus)
                            {
                                ASIdle,
                                ASProcessing,
                                ASSucceeded,
                                ASFailed
                            };
                            
                            static ActionStatus sessionStatus = ASIdle;
                            
                            switch (sessionStatus) {
                                case ASIdle: {
                                    if (restQueryMatches && [restQueryMatches count] == 1 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] isEqualToString:@"yes"]) {
                                        void(^block)(void) = ^{
                                            BOOL success = YES;
                                            
                                            ABAddressBook *AB = [ABAddressBook addressBook];
                                            
                                            for (ABRecord *r in [AB people]) {
                                                ABMutableMultiValue *ims = [[r valueForProperty:kABPhoneProperty] mutableCopy];
                                                for (int i = 0; i < [ims count]; i++) {
                                                    NSArray *dissectedPhoneNum = [RMPhoneFormat dissectPhoneNumber:[ims valueAtIndex:i]];
                                                    NSString *formattedPhoneNumPart = [[RMPhoneFormat instance] format:dissectedPhoneNum[0]];
                                                    NSString *formattedPhoneNum = [@[formattedPhoneNumPart,
                                                                                     [[dissectedPhoneNum subarrayWithRange:NSMakeRange(1, dissectedPhoneNum.count - 1)] componentsJoinedByString:@""]] componentsJoinedByString:@""];
                                                    if (![ims replaceValueAtIndex:i withValue:formattedPhoneNum]) {
                                                        NSLog(@"Formatting phone number %@ failed because ABMutableMultiValue changes could not be saved", [ims valueAtIndex:i]);
                                                        success = NO;
                                                    }
                                                }
                                                if (![r setValue:ims forProperty:kABPhoneProperty]) {
                                                    NSLog(@"Formatting phone number %@ failed because ABRecord changes could not be saved", [ims valueAtIndex:i]);
                                                    success = NO;
                                                }
                                            }
                                            
                                            NSError *error = nil;
                                            [AB saveAndReturnError:&error];
                                            if (error) {
                                                NSLog(@"Formatting phone numbers failed: %@", [error localizedDescription]);
                                                success = NO;
                                            }
                                            
                                            if (!isInProcessOfSettingUp_) {
                                                if (success) {
                                                    sessionStatus = ASSucceeded;
                                                } else {
                                                    sessionStatus = ASFailed;
                                                }
                                                [self invokeAlfredWithCommand:@"call --formatcontactsphonenumbers"];
                                            } else {
                                                hasSettingUpSucceeded = success;
                                            }
                                        };
                                        
                                        if (!isInProcessOfSettingUp_) {
                                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
                                            sessionStatus = ASProcessing;
                                        } else {
                                            block();
                                        }
                                    } else {
                                        [results appendString:[self formatContactsPhoneNumbersOptionHelp]];
                                        break;
                                    }
                                }
                                case ASProcessing:
                                    [results setString:[self processingActionHelpForOption:@"formatcontactsphonenumbers"]];
                                    return YES;
                                case ASSucceeded:
                                    sessionStatus = ASIdle;
                                    [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --formatcontactsphonenumbers</title><subtitle>Done. All Apple Contacts phone numbers are now formatted to their regional formats</subtitle><icon>succeeded.png</icon></item>"];
                                    return YES;
                                case ASFailed:
                                    sessionStatus = ASIdle;
                                    [results setString:[self failedActionHelpForOption:@"formatcontactsphonenumbers"]];
                                    return YES;
                            }
                        } else {
                            [results appendString:[self formatContactsPhoneNumbersOptionHelp]];
                        }
                    }
                    
                    if ([@"addcontactsphoneticnames" hasPrefix:longOption]) {
                        if ([longOption isEqualToString:@"addcontactsphoneticnames"]) {
                            
                            // each long option should have their own set of action status
                            typedef NS_ENUM(NSInteger, ActionStatus)
                            {
                                ASIdle,
                                ASProcessing,
                                ASSucceeded,
                                ASFailed
                            };
                            
                            static ActionStatus sessionStatus = ASIdle;
                            
                            switch (sessionStatus) {
                                case ASIdle: {
                                    if (restQueryMatches && [restQueryMatches count] == 1 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] isEqualToString:@"yes"]) {
                                        void(^block)(void) = ^{
                                            BOOL success = YES;
                                            
                                            HanyuPinyinOutputFormat *outputFormat=[[HanyuPinyinOutputFormat alloc] init];
                                            [outputFormat setToneType:ToneTypeWithoutTone];
                                            [outputFormat setVCharType:VCharTypeWithV];
                                            [outputFormat setCaseType:CaseTypeLowercase];
                                            
                                            ABAddressBook *AB = [ABAddressBook addressBook];
                                            
                                            for (ABRecord *r in [AB people]) {
                                                NSString *lastName = [r valueForProperty:kABLastNameProperty];
                                                
                                                if (lastName) {
                                                    NSArray *mLastName = [[self chineseRe] matchesInString:lastName options:0 range:NSMakeRange(0, [lastName length])];
                                                    if ([mLastName count] > 0) {
                                                        NSString *lastNamePhonetic = [r valueForProperty:kABLastNamePhoneticProperty];
                                                        if(!lastNamePhonetic || [lastNamePhonetic stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
                                                            // add last phonetic name
                                                            if (![r setValue:[[PinyinHelper toHanyuPinyinStringWithNSString:lastName withHanyuPinyinOutputFormat:outputFormat withNSString:@""] capitalizedString] forProperty:kABLastNamePhoneticProperty]) {
                                                                NSLog(@"Adding phonetic last name for %@ failed because ABRecord changes could not be saved", lastName);
                                                                success = NO;
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                NSString *firstName = [r valueForProperty:kABFirstNameProperty];
                                                
                                                if (firstName) {
                                                    NSArray *mFirstName = [[self chineseRe] matchesInString:firstName options:0 range:NSMakeRange(0, [firstName length])];
                                                    if ([mFirstName count] > 0) {
                                                        NSString *firstNamePhonetic = [r valueForProperty:kABFirstNamePhoneticProperty];
                                                        if(!firstNamePhonetic || [firstNamePhonetic stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
                                                            // add first phonetic name
                                                            if (![r setValue:[[PinyinHelper toHanyuPinyinStringWithNSString:firstName withHanyuPinyinOutputFormat:outputFormat withNSString:@""] capitalizedString] forProperty:kABFirstNamePhoneticProperty]) {
                                                                NSLog(@"Adding phonetic first name for %@ failed because ABRecord changes could not be saved", firstName);
                                                                success = NO;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            NSError *error = nil;
                                            [AB saveAndReturnError:&error];
                                            if (error) {
                                                NSLog(@"Adding phonetic names failed: %@", [error localizedDescription]);
                                                success = NO;
                                            }
                                            
                                            if (!isInProcessOfSettingUp_) {
                                                if (success) {
                                                    sessionStatus = ASSucceeded;
                                                } else {
                                                    sessionStatus = ASFailed;
                                                }
                                                [self invokeAlfredWithCommand:@"call --addcontactsphoneticnames"];
                                            } else {
                                                hasSettingUpSucceeded = success;
                                            }
                                        };
                                        
                                        if (!isInProcessOfSettingUp_) {
                                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
                                            sessionStatus = ASProcessing;
                                        } else {
                                            block();
                                        }
                                    } else {
                                        [results appendString:[self addContactsPhoneticNamesOptionHelp]];
                                        break;
                                    }
                                }
                                case ASProcessing:
                                    [results setString:[self processingActionHelpForOption:@"addcontactsphoneticnames"]];
                                    return YES;
                                case ASSucceeded:
                                    sessionStatus = ASIdle;
                                    [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --addcontactsphoneticnames</title><subtitle>Done. All Apple Contacts 中文名's phonetic names are now added</subtitle><icon>succeeded.png</icon></item>"];
                                    return YES;
                                case ASFailed:
                                    sessionStatus = ASIdle;
                                    [results setString:[self failedActionHelpForOption:@"addcontactsphoneticnames"]];
                                    return YES;
                            }
                        } else {
                            [results appendString:[self addContactsPhoneticNamesOptionHelp]];
                        }
                    }
                    
                    if ([@"buildfullthumbnailcache" hasPrefix:longOption]) {
                        if ([longOption isEqualToString:@"buildfullthumbnailcache"] && restQueryMatches && [restQueryMatches count] == 1 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] isEqualToString:@"yes"]) {
                            callType_ |= CTBuildFullThumbnailCache;
                            return NO;
                        } else {
                            [results appendString:[self buildFullThumbnailCacheOptionHelp]];
                        }
                    }
                    
                    if ([@"destroythumbnailcache" hasPrefix:longOption]) {
                        if ([longOption isEqualToString:@"destroythumbnailcache"] && restQueryMatches && [restQueryMatches count] == 1 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] isEqualToString:@"yes"]) {
                            [[self fileManager] removeItemAtPath:[self thumbnailCachePath] error:nil];
                            [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --destroythumbnailcache</title><subtitle>Done. Contact thumbnail cache is now destroyed</subtitle><icon>destroyThumbnailCache.png</icon></item>"];
                            return YES;
                        } else {
                            [results appendString:[self destroyThumbnailCacheOptionHelp]];
                        }
                    }
                    
                    if ([@"turnautoupdatechecking" hasPrefix:longOption]) {
                        if ([longOption isEqualToString:@"turnautoupdatechecking"] && restQueryMatches && [restQueryMatches count] == 1) {
                            NSString *input = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                            
                            if ([input isEqualToString:@"on"]) {
                                [config_ setObject:[NSNumber numberWithBool:YES] forKey:@"autoUpdateCheckingEnabledStatus"];
                                [config_ writeToFile:[self configPlistPath] atomically:YES];
                                
                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --turnautoupdatechecking</title><subtitle>Done. Automatic update checking is now enabled.</subtitle><icon>update.png</icon></item>"];
                                
                                return YES;
                            } else if([input isEqualToString:@"off"]) {
                                [config_ setObject:[NSNumber numberWithBool:NO] forKey:@"autoUpdateCheckingEnabledStatus"];
                                [config_ writeToFile:[self configPlistPath] atomically:YES];
                                
                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --turnautoupdatechecking</title><subtitle>Done. Automatic update checking is now disabled.</subtitle><icon>update.png</icon></item>"];
                                
                                return YES;
                            } else
                                [results appendString:[self turnAutoUpdateCheckingOptionHelp]];
                        } else {
                            [results appendString:[self turnAutoUpdateCheckingOptionHelp]];
                        }
                    }
                }
                
                if ([results isEqualToString:[self xmlHeader]])
                    [results appendString:[self longOptionHelp]];
            } else {
                [results appendString:[self longOptionHelp]];
            }
            
            if ([results isEqualToString:[self xmlHeader]]) {
                [results appendFormat:@"<item arg=\"\" autocomplete=\"-a-\" valid=\"no\"><title>No Long Options Available for \"-%@\"</title><subtitle>Type \"call -a-\" to lay out all long options for call components</subtitle></item>", [self getComponentCodesFromCallType:callType_]];
            }
            
            return YES;
#pragma mark Handle Short Options
        } else if ([option isEqualToString:@"a"]) {
            [self processOptions:[@"-" stringByAppendingString:callTypeDefaultOrder_] withRestQueryMatches:restQueryMatches andQuery:query andResults:results];
        } else if ([option isEqualToString:@"!"]) {
            callType_ |= CTNoThumbnailCache;
        } else {
            NSNumber *ctRaw = sComponentCode2CallType[option];
            if (ctRaw) {
                CallType ct = [ctRaw integerValue];
                if ((sNonSearchableOptions & ct) && !(callType_ & ct)) {
                    callType_ |= ct;
                    [callModifiers_ addObject:ctRaw];
                } else if ((enabledCallType_ & ct) && !(callType_ & ct)) {
                    callType_ |= ct;
                    [callTypes_ addObject:ctRaw];
                }
            }
        }
    }
    
    return NO;
}

- (NSDictionary *)checkAvailableCallTrunkCountries
{
    NSDictionary *knownCountries = @{@"AU":@"Australia", @"UK":@"United Kingdom", @"US":@"United States"};
    NSMutableDictionary *availableCountries = [NSMutableDictionary dictionary];
    
    
    
    for (NSString *c in knownCountries) {
        CFURLRef appURL = NULL;
		OSStatus result = LSFindApplicationForInfo (
                                                    kLSUnknownCreator,         //creator codes are dead, so we don't care about it
                                                    (__bridge CFStringRef)([NSString stringWithFormat:@"com.calltrunk.CallTrunk-%@", c]), //you can use the bundle ID here
                                                    NULL,                      //or the name of the app here (CFSTR("Safari.app"))
                                                    NULL,                      //this is used if you want an FSRef rather than a CFURLRef
                                                    &appURL
                                                    );
        if (result == noErr)
            [availableCountries setObject:knownCountries[c] forKey:c];
        
		//the CFURLRef returned from the function is retained as per the docs so we must release it
		if (appURL)
		    CFRelease(appURL);
    }
    
    return availableCountries;
}

#pragma mark -
#pragma mark Generate Complicated Search Element

-(ABSearchElement *)generateSearchingElementForQueryPart:(NSString *)queryPartA andQueryPart:(NSString *)queryPartB
{
    return [ABSearchElement searchElementForConjunction:kABSearchOr children:
            @[[ABSearchElement searchElementForConjunction:kABSearchAnd children:
               @[[ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive], // first name
                    [ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive] // first name phonetic
                    ]
                  ],
                 [ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:queryPartB comparison:kABPrefixMatchCaseInsensitive], // last name
                    [ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPartB comparison:kABPrefixMatchCaseInsensitive] // last name phonetic
                    ]
                  ]
                 ]
               ],
              [ABSearchElement searchElementForConjunction:kABSearchAnd children:
               @[[ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:queryPartB comparison:kABPrefixMatchCaseInsensitive], // first name
                    [ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPartB comparison:kABPrefixMatchCaseInsensitive] // first name phonetic
                    ]
                  ],
                 [ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive], // last name
                    [ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive] // last name phonetic
                    ]
                  ]
                 ]
               ],
              [ABSearchElement searchElementForConjunction:kABSearchAnd children:
               @[[ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive], // first name phonetic
                 [ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPartB comparison:kABContainsSubStringCaseInsensitive] // first name phonetic (contains)
                 ]
               ],
              [ABSearchElement searchElementForConjunction:kABSearchAnd children:
               @[[ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive], // last name phonetic
                 [ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPartB comparison:kABContainsSubStringCaseInsensitive] // last name phonetic (contains)
                 ]
               ]
              ]
            ];
}

-(ABSearchElement *)generateSearchingElementForQueryPart:(NSString *)queryPartA queryPart:(NSString *)queryPartB andQueryPart:(NSString *)queryPartC
{
    /*
     First Name     Last Name
     ----------     ---------
     A              BC
     AB             C
     BC             A
     C              AB
     */
    return [ABSearchElement searchElementForConjunction:kABSearchOr children:
            @[[ABSearchElement searchElementForConjunction:kABSearchAnd children:
               @[[ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive], // first name
                    [ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive] // first name phonetic
                    ]
                  ],
                 [ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:queryPartB comparison:kABPrefixMatchCaseInsensitive], // last name
                    [ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPartB comparison:kABPrefixMatchCaseInsensitive] // last name phonetic
                    ]
                  ],
                 [ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:queryPartC comparison:kABContainsSubStringCaseInsensitive], // last name (contains)
                    [ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPartC comparison:kABContainsSubStringCaseInsensitive] // last name phonetic (contains)
                    ]
                  ]
                 ]
               ],
              [ABSearchElement searchElementForConjunction:kABSearchAnd children:
               @[[ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive], // first name
                    [ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive] // first name phonetic
                    ]
                  ],
                 [ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:queryPartB comparison:kABContainsSubStringCaseInsensitive], // first name (contains)
                    [ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPartB comparison:kABContainsSubStringCaseInsensitive] // first name phonetic (contains)
                    ]
                  ],
                 [ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:queryPartC comparison:kABPrefixMatchCaseInsensitive], // last name
                    [ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPartC comparison:kABPrefixMatchCaseInsensitive] // last name phonetic
                    ]
                  ]
                 ]
               ],
              [ABSearchElement searchElementForConjunction:kABSearchAnd children:
               @[[ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:queryPartB comparison:kABPrefixMatchCaseInsensitive], // first name
                    [ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPartB comparison:kABPrefixMatchCaseInsensitive] // first name phonetic
                    ]
                  ],
                 [ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:queryPartC comparison:kABContainsSubStringCaseInsensitive], // first name (contains)
                    [ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPartC comparison:kABContainsSubStringCaseInsensitive] // first name phonetic (contains)
                    ]
                  ],
                 [ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive], // last name
                    [ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive] // last name phonetic
                    ]
                  ]
                 ]
               ],
              [ABSearchElement searchElementForConjunction:kABSearchAnd children:
               @[[ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:queryPartC comparison:kABPrefixMatchCaseInsensitive], // first name
                    [ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPartC comparison:kABPrefixMatchCaseInsensitive] // first name phonetic
                    ]
                  ],
                 [ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive], // last name
                    [ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPartA comparison:kABPrefixMatchCaseInsensitive] // last name phonetic
                    ]
                  ],
                 [ABSearchElement searchElementForConjunction:kABSearchOr children:
                  @[[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:queryPartB comparison:kABContainsSubStringCaseInsensitive], // last name (contains)
                    [ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPartB comparison:kABContainsSubStringCaseInsensitive] // last name phonetic (contains)
                    ]
                  ]
                 ]
               ]
              ]
            ];
}

#pragma mark -
#pragma mark Handle Thumbnails

- (NSArray *)checkAndReturnIMThumbnailPathsForUId:(NSString *)uId andRecord:(ABRecord *)r
{
    static dispatch_once_t predicate = 0;
    static NSArray *iMColors = nil;
    static NSArray *iMDefaultThumbnailPaths = nil;
    
    dispatch_once(&predicate, ^{
        iMColors = @[[NSColor colorWithCalibratedRed:0.635294118f green:0.635294118f blue:0.635294118f alpha:1.0f],
                     [NSColor colorWithCalibratedRed:0.176470588f green:0.188235294f blue:0.2f alpha:1.0f],
                     [NSColor colorWithCalibratedRed:0.992156863f green:0.745098039f blue:0.254901961f alpha:1.0f],
                     [NSColor colorWithCalibratedRed:0.980392157f green:0.294117647f blue:0.28627451f alpha:1.0f],
                     [NSColor colorWithCalibratedRed:0.109803922f green:0.733333333f blue:0.282352941f alpha:1.0f]];
        iMDefaultThumbnailPaths = @[[[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-IM-Unknown.tiff"],
                                    [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-IM-Offline.tiff"],
                                    [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-IM-Idle.tiff"],
                                    [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-IM-Away.tiff"],
                                    [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail-IM-Available.tiff"]];
#ifdef GENERATE_DEFAULT_THUMBNAILS
        // generate default thumbnails
        for (int i = 0; i < iMDefaultThumbnailPaths.count; i++) {
            [self checkAndUpdateDefaultThumbnailIfNeededAtPath:iMDefaultThumbnailPaths[i] withColor:iMColors[i] hasShadow:YES];
        }
#endif
    });
    
    BOOL isThumbNailOkay = uId && r;
    
    NSArray *iMThumbnailPaths = nil;
    
    if (isThumbNailOkay) {
        iMThumbnailPaths = @[[[self thumbnailCachePath] stringByAppendingFormat:@"/%@-IM-Unknown.tiff", uId],
                             [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-IM-Offline.tiff", uId],
                             [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-IM-Idle.tiff", uId],
                             [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-IM-Away.tiff", uId],
                             [[self thumbnailCachePath] stringByAppendingFormat:@"/%@-IM-Available.tiff", uId]];
        
        for (int i = 0; i < iMThumbnailPaths.count; i++) {
            isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:iMThumbnailPaths[i] forRecord:r withColor:iMColors[i] hasShadow:YES];
        }
    }
    
    if (!isThumbNailOkay) {
        iMThumbnailPaths = iMDefaultThumbnailPaths;
    }

    return iMThumbnailPaths;
}

- (void)checkAndUpdateDefaultThumbnailIfNeededAtPath:(NSString *)path withColor:(NSColor *)color hasShadow:(BOOL)hasShadow
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![[self fileManager] fileExistsAtPath:path])
            [[[self newThumbnailFrom:[self defaultContactThumbnail] withColor:color hasShadow:hasShadow] TIFFRepresentation] writeToFile:path atomically:NO];
    });
}

- (BOOL)checkAndUpdateThumbnailIfNeededAtPath:(NSString *)path forRecord:(ABRecord *)record withColor:(NSColor *)color hasShadow:(BOOL)hasShadow
{
    if (callType_ & CTNoThumbnailCache)
        return NO;
    
    NSTimeInterval timeNow = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeSinceLastUpdated = [[[[self fileManager] attributesOfItemAtPath:path error:nil] fileModificationDate] timeIntervalSince1970];

    // output the person's thumbnail if it hasn't been cached
    if (![[self fileManager] fileExistsAtPath:path] ||  (timeNow - timeSinceLastUpdated) > THUMBNAIL_CACHE_LIFESPAN) {
        NSImage *thumbnail = [self thumbnailForRecord:record];
        if (thumbnail)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[[self newThumbnailFrom:thumbnail withColor:color hasShadow:hasShadow] TIFFRepresentation] writeToFile:path atomically:NO];
            });
        else
            return NO;
    }
    
    return YES;
}

- (NSFileManager *)fileManager
{
    static NSFileManager *FM = nil;
    static dispatch_once_t predicate = 0;
    
    dispatch_once(&predicate, ^{
        FM = [[NSFileManager alloc] init];
    });
    
    return FM;
}

- (NSImage *)thumbnailForRecord:(ABRecord *)record
{
    static NSCache *cache = nil;
    static dispatch_once_t predicate = 0;
    
    dispatch_once(&predicate, ^{
        cache = [NSCache new];
        cache.countLimit = 10;
    });
    
    NSObject *thumbnail = [cache objectForKey:record];
    
    if (!thumbnail) {
        thumbnail = [[NSImage alloc] initWithData:[(ABPerson *)record imageData]];
        if (thumbnail) {
            thumbnail = [self makeThumbnailUsing:(NSImage *)thumbnail];
        } else {
            thumbnail = [NSNull null];
        }
        [cache setObject:thumbnail forKey:record];
    }
    
    return thumbnail != [NSNull null] ? (NSImage *)thumbnail : nil;
}

- (NSImage *)makeThumbnailUsing:(NSImage *)originalImage
{
    NSSize originalSize = [originalImage size];
    NSRect newRect = NSMakeRect(0, 0, sThumbnailSize.width, sThumbnailSize.height);
    NSImage *newImage = [[NSImage alloc] initWithSize:sThumbnailSize];
    
    [newImage lockFocus];
    
    [originalImage drawInRect:newRect fromRect:NSMakeRect(0, 0, originalSize.width, originalSize.height) operation:NSCompositeCopy fraction:1.0f];
    
    [newImage unlockFocus];
    
    return newImage;
}

- (NSImage *)newThumbnailFrom:(NSImage *)originalImage withColor:(NSColor *)color hasShadow:(BOOL)hasShadow
{
    CGFloat lineWidth = 8.0f;
    CGFloat innerLineWidth = 1.0f;
    
    NSImage *newImage = [originalImage copy];
    
    [newImage lockFocus];
    
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

    if (hasShadow)
        CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 8.0f, [color CGColor]);
    CGContextSetRGBStrokeColor(context, [color redComponent], [color greenComponent], [color blueComponent], [color alphaComponent]);
    CGContextSetLineWidth(context, lineWidth);
    CGContextStrokeRect(context, NSMakeRect(-lineWidth/2 + innerLineWidth, -lineWidth/2+innerLineWidth, sThumbnailSize.width+lineWidth-2*innerLineWidth, sThumbnailSize.height+lineWidth-2*innerLineWidth));
    
    [newImage unlockFocus];
    
    return newImage;
}

- (NSString *)thumbnailCachePath
{
    static NSString *path = nil;
    static dispatch_once_t predicate = 0;
    
    dispatch_once(&predicate, ^{
        path = [[self dataPath] stringByAppendingPathComponent:@"/thumbnails"];
    });

    return path;
}

- (NSImage *)defaultContactThumbnail
{
    static NSImage *image = nil;
    static dispatch_once_t predicate = 0;
    
    dispatch_once(&predicate, ^{
        image = [[NSImage alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail.png"]];
    });
    
    return image;
}

#pragma mark -
#pragma mark Levenshtein String Distance Algorithm

-(float)compareString:(NSString *)originalString withString:(NSString *)comparisonString
{
	// Normalize strings
	[originalString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[comparisonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
	originalString = [originalString lowercaseString];
	comparisonString = [comparisonString lowercaseString];
    
	// Step 1 (Steps follow description at http://www.merriampark.com/ld.htm)
	NSInteger k, i, j, cost, * d, distance;
    
	NSInteger n = [originalString length];
	NSInteger m = [comparisonString length];
    
	if( n++ != 0 && m++ != 0 ) {
        
		d = malloc( sizeof(NSInteger) * m * n );
        
		// Step 2
		for( k = 0; k < n; k++)
			d[k] = k;
        
		for( k = 0; k < m; k++)
			d[ k * n ] = k;
        
		// Step 3 and 4
		for( i = 1; i < n; i++ )
			for( j = 1; j < m; j++ ) {
                
				// Step 5
				if( [originalString characterAtIndex: i-1] ==
				   [comparisonString characterAtIndex: j-1] )
					cost = 0;
				else
					cost = 1;
                
				// Step 6
				d[ j * n + i ] = [self smallestOf: d [ (j - 1) * n + i ] + 1
                                            andOf: d[ j * n + i - 1 ] +  1
                                            andOf: d[ (j - 1) * n + i - 1 ] + cost ];
                
				// This conditional adds Damerau transposition to Levenshtein distance
				if( i>1 && j>1 && [originalString characterAtIndex: i-1] ==
                   [comparisonString characterAtIndex: j-2] &&
                   [originalString characterAtIndex: i-2] ==
                   [comparisonString characterAtIndex: j-1] )
				{
					d[ j * n + i] = [self smallestOf: d[ j * n + i ]
                                               andOf: d[ (j - 2) * n + i - 2 ] + cost ];
				}
			}
        
		distance = d[ n * m - 1 ];
        
		free( d );
        
		return distance;
	}
	return 0.0;
}

// Return the minimum of a, b and c - used by compareString:withString:
-(NSInteger)smallestOf:(NSInteger)a andOf:(NSInteger)b andOf:(NSInteger)c
{
	NSInteger min = a;
	if ( b < min )
		min = b;
    
	if( c < min )
		min = c;
    
	return min;
}

-(NSInteger)smallestOf:(NSInteger)a andOf:(NSInteger)b
{
	NSInteger min=a;
	if (b < min)
		min=b;
    
	return min;
}

#pragma mark -
#pragma mark Utilities

- (NSString *)dataPath
{
    static NSString *path = nil;
    if (!path) {
        //cache folder
        path = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Application Support/Alfred 2/Workflow Data/%@", IDENTIFIER];
    }
    return path;
}

- (NSString *)configPlistPath
{
    static NSString *path = nil;
    if (!path) {
        //cache folder
        path = [[self dataPath] stringByAppendingPathComponent:@"/config.plist"];
    }
    return path;
}

- (NSString *)skypeCallPath
{
    static NSString *path = nil;
    if (!path) {
        path = [[UniCall workingPath] stringByAppendingString:@"/Skype Call"];
    }
    return path;
}

- (NSString *)workflowPath
{
    static NSString *path = nil;
    if (!path) {
        path = [[UniCall workingPath] stringByDeletingLastPathComponent];
    }
    return path;
}

+ (NSString *)workingPath
{
    static NSString *path = nil;
    if (!path) {
#ifdef DEBUG
        path = @"/Users/guiguan/Dropbox/Alfred.alfredpreferences/workflows/user.workflow.D1A87876-B4E1-4FB9-9028-2562B0B52AEA/bin";
#else
        path = [[NSBundle mainBundle] bundlePath];
#endif
    }
    return path;
}

- (void)prepopulateAllOnlineJabberUserStatus
{
    static NSString *path = nil;
    
    if (!path) {
        path = [[UniCall workingPath] stringByAppendingString:@"/allonlinejabberuserstatus.scpt"];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray* result = [[UniCall runCommand:[NSString stringWithFormat:@"osascript \"%@\"", path]] componentsSeparatedByString:@", "];
        NSMutableDictionary *newInfo = [NSMutableDictionary dictionary];
        if (result.count % 2 == 0)
            for (int i = 0; i < result.count; i += 2) {
                newInfo[result[i]] = [NSNumber numberWithInteger:[result[i+1] integerValue]];
            }
        dispatch_async(dispatch_get_main_queue(), ^{
            [sIMStatusBuffer addEntriesFromDictionary:newInfo];
        });
    });
}

- (NSInteger)checkJabberStatusForUsername:(NSString *)username
{
    static NSString *path = nil;
    
    if (!path) {
        path = [[UniCall workingPath] stringByAppendingString:@"/checkjabberstatus.scpt"];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSNumber* status = [NSNumber numberWithInteger:[[UniCall runCommand:[NSString stringWithFormat:@"osascript \"%@\" \"%@\"", path, username]] integerValue]];
        dispatch_async(dispatch_get_main_queue(), ^{
            sIMStatusBuffer[username] = status;
        });
    });
    
    NSNumber *result = sIMStatusBuffer[username];
    if (result) {
        return [result integerValue];
    } else {
        return 0;
    }
}

- (void)invokeAlfredWithCommand:(NSString *)cmd
{
    static NSString *path = nil;
    
    if (!path) {
        path = [[UniCall workingPath] stringByAppendingString:@"/invokealfredwithcmd.scpt"];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [UniCall runCommand:[NSString stringWithFormat:@"osascript \"%@\" \"%@\"", path, cmd]];
    });
}

+ (void)pushNotificationWithOptions:(NSDictionary *)options
{
    static NSString *path = nil;
    if (!path) {
        path = [[UniCall workingPath] stringByAppendingString:@"/Uni Call.app/Contents/MacOS/Uni Call"];
    }
    NSMutableString *optionStr = [NSMutableString string];
    
    [options enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [optionStr appendFormat:@" -%@ \"%@\"", key, obj];
    }];
    
    [UniCall runCommand:[NSString stringWithFormat:@"\"%@\" %@", path, optionStr]];
}

+ (NSString *)runCommand:(NSString *)commandToRun
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    
    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          [NSString stringWithFormat:@"%@", commandToRun],
                          nil];
    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *output;
    output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return output;
}

- (NSString *)xmlHeader
{
    static NSString *header = @"\n<?xml version=\"1.0\"?>\n\n<items>";
    return header;
}

- (NSString *)xmlSimpleEscape:(NSString *)unescapedStr
{
    if (unescapedStr == nil || [unescapedStr length] == 0) {
        return unescapedStr;
    }
    
    const int len = (int)[unescapedStr length];
    int longer = ((int) (len * 0.10));
    if (longer < 5) {
        longer = 5;
    }
    longer = len + longer;
    NSMutableString *mStr = [NSMutableString stringWithCapacity:longer];
    
    NSRange subrange;
    subrange.location = 0;
    subrange.length = 0;
    
    for (int i = 0; i < len; i++) {
        NSString *c = [unescapedStr substringWithRange:NSMakeRange(i, 1)];
        NSString *replaceWithStr = nil;
        
        if ([c isEqual: @"\""])
        {
            replaceWithStr = @"&quot;";
        }
        else if ([c isEqual: @"\'"])
        {
            replaceWithStr = @"&#x27;";
        }
        else if ([c isEqual: @"<"])
        {
            replaceWithStr = @"&lt;";
        }
        else if ([c isEqual: @">"])
        {
            replaceWithStr = @"&gt;";
        }
        else if ([c isEqual: @"&"])
        {
            replaceWithStr = @"&amp;";
        }
        
        if (replaceWithStr == nil) {
            // The current character is not an XML escape character, increase subrange length
            
            subrange.length += 1;
        } else {
            // The current character will be replaced, but append any pending substring first
            
            if (subrange.length > 0) {
                NSString *substring = [unescapedStr substringWithRange:subrange];
                [mStr appendString:substring];
            }
            
            [mStr appendString:replaceWithStr];
            
            subrange.location = i + 1;
            subrange.length = 0;
        }
    }
    
    // Got to end of unescapedStr so append any pending substring, in the
    // case of no escape characters this will append the whole string.
    
    if (subrange.length > 0) {
        if (subrange.location == 0) {
            [mStr appendString:unescapedStr];      
        } else {
            NSString *substring = [unescapedStr substringWithRange:subrange];
            [mStr appendString:substring];
        }
    }
    
    return [NSString stringWithString:mStr];
}

@end