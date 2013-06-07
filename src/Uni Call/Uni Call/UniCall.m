#define VERSION @"v5.1"
//
//  UniCall.m
//  Uni Call
//
//  Created by Guan Gui on 19/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>

#import "UniCall.h"

#define IDENTIFIER @"net.guiguan.Uni-Call"
#define THUMBNAIL_CACHE_LIFESPAN 604800 // 1 week time
#define RESULT_NUM_LIMIT 20

#define CALLTYPE_BOUNDARY 2
typedef NS_OPTIONS(NSInteger, CallType)
{
    CTNoThumbnailCache              = 1 << 0,
    CTBuildFullThumbnailCache       = 1 << 1,
///////////////////////////////////////////////
    CTSkype                         = 1 << 2,// <==== CALLTYPE_BOUNDARY
    CTFaceTime                      = 1 << 3,
    CTPhoneAmego                    = 1 << 4,
    CTSIP                           = 1 << 5,
    CTPushDialer                    = 1 << 6,
    CTGrowlVoice                    = 1 << 7,
    CTCallTrunk                     = 1 << 8,
    CTFritzBox                      = 1 << 9
};

//@implementation NSImage(saveAsJpegWithName)
//
//- (void) saveAsJpegWithName:(NSString*) fileName
//{
//    // Cache the reduced image
//    NSData *imageData = [self TIFFRepresentation];
//    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
//    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
//    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
//    [imageData writeToFile:fileName atomically:NO];
//}
//
//@end

@implementation UniCall

static CallType sNonSearchableOptions = CTNoThumbnailCache | CTBuildFullThumbnailCache;
static CallType sAllCallTypes = CTSkype | CTFaceTime | CTPhoneAmego | CTSIP | CTPushDialer | CTGrowlVoice | CTCallTrunk | CTFritzBox;
static NSSize sThumbnailSize;
static NSSet *sFaceTimeNominatedPhoneLabels;
static NSMutableSet *sReservedPhoneLabels;

NSMutableDictionary *config_; // don't assume config.plist has necessary components
CallType enabledCallType_;
CallType callType_;
NSMutableArray *callTypes_;
int resultCount_;
NSString *extraParameter_;
BOOL hasGeneratedOutputsForFirstContact_;

+ (void)initialize
{
    sThumbnailSize = NSMakeSize(32, 32);
    sFaceTimeNominatedPhoneLabels = [NSSet setWithArray:@[@"facetime", @"iphone", @"ipad", @"mac", @"idevice"]];
    sReservedPhoneLabels = [NSMutableSet set];
    [sReservedPhoneLabels unionSet:sFaceTimeNominatedPhoneLabels];
}

- (id)init
{
    self = [super init];
    if (self) {
        if ([[self fileManager] fileExistsAtPath:[self configPlistPath]]) {
            config_ = [[NSMutableDictionary alloc] initWithContentsOfFile:[self configPlistPath]];
            NSNumber *callComponentStatus = config_[@"callComponentStatus"];
            if (callComponentStatus)
                enabledCallType_ = [callComponentStatus integerValue] << CALLTYPE_BOUNDARY;
            else
                enabledCallType_ = sAllCallTypes;
        } else {
            config_ = [[NSMutableDictionary alloc] init];
            enabledCallType_ = sAllCallTypes;
        }
    }
    return self;
}

-(NSRange)getRangeFromQueryMatch:(NSTextCheckingResult *)queryMatch
{
    if ([queryMatch rangeAtIndex:1].location != NSNotFound)
        return [queryMatch rangeAtIndex:1];
    else
        return [queryMatch range];
}

- (NSDictionary *)processPhoneLabel:(NSString *)phoneLabel
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableArray *labelsToDisplay = [NSMutableArray array];
    [dict setObject:[NSMutableSet set] forKey:@"toConsume"];
    
    static NSCharacterSet *spaceCS = nil;
    
    if (!spaceCS)
        spaceCS = [NSCharacterSet characterSetWithCharactersInString:@" \n_$!<>"];
    
    for (NSString *l in [phoneLabel componentsSeparatedByString:@","]) {
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

-(NSString *)process:(NSString *)query
{
    //    if ([self executionLockPresents])
    //        return [NSString stringWithFormat:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"\" arg=\"\" autocomplete=\"\" valid=\"no\"><title>Please wait for another Uni Call process to terminate</title><subtitle>Error: uniCallExecutionLock detected at %@</subtitle><icon>icon.png</icon></item>", NSHomeDirectory()];
    
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"\"([^\"]+)\"(?= )|[^ ]+(?= )" options:0 error:nil];
    NSArray *queryMatches = [re matchesInString:query options:0 range:NSMakeRange(0, [query length])];
    
    if ([queryMatches count] == 0)
        return [self outputHelpOnOptions];
    
    NSMutableString *results = [NSMutableString stringWithString:@"\n<?xml version=\"1.0\"?>\n\n<items>"];
    callType_ = 0;
    callTypes_ = [NSMutableArray array];
    resultCount_ = 0;
    extraParameter_ = nil;
    
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
            if ([queryPart length] > 1) {
                extraParameter_ = [queryPart substringFromIndex:1];
            }
        } else {
            [queryParts addObject:queryPart];
        }
    }
    
    if (callType_ & CTBuildFullThumbnailCache) {
        //            [self acquireExecutionLock];
        callType_ = CTBuildFullThumbnailCache;
        [self processOptions:@"-a" withRestQueryMatches:nil andQuery:query andResults:results];
    } else if ([queryParts count] == [queryMatches count] || ([queryParts count] > 0 && callType_ <= sNonSearchableOptions)) {
        // default: no options, just query
        [self processOptions:@"-a" withRestQueryMatches:nil andQuery:query andResults:results];
    } else {
        if ([queryParts count] == 0) {
            // no query
            if (callType_ <= sNonSearchableOptions) {
                // no valid options provided
                return [self outputHelpOnOptions];
            } else {
                // only options
                [results appendFormat:@"</items>\n"];
                return results;
            }
        }
    }
    
    static ABAddressBook *AB = nil;
    
    if (!AB)
        AB = [ABAddressBook addressBook];
    
    NSArray *peopleFound;
    int population;
    if (callType_ & CTBuildFullThumbnailCache)
        peopleFound = [AB people];
    else {
        NSMutableArray *searchTerms = [[NSMutableArray alloc] initWithCapacity:[queryParts count]];
        NSMutableString *newQuery = [NSMutableString string];
        
        for (int i = 0; i < [queryParts count]; i++) {
            [searchTerms addObject:[self generateOrSearchingElementForQueryPart: queryParts[i]]];
            [newQuery appendFormat:@"%@ ", queryParts[i]];
        }
        
        query = [newQuery substringToIndex:[newQuery length] - 1];
        
        ABSearchElement *searchEl = [ABSearchElement searchElementForConjunction:kABSearchOr children:@[[self generateOrSearchingElementForQuery:query], [ABSearchElement searchElementForConjunction:kABSearchAnd children:searchTerms]]];
        
        peopleFound = [AB recordsMatchingSearchElement:searchEl];
        [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items>"];
        hasGeneratedOutputsForFirstContact_ = NO;
    }
    
    if (!(callType_ & CTNoThumbnailCache) && ![[self fileManager] fileExistsAtPath:[self thumbnailCachePath]]) {
        //create the folder if it doesn't exist
        [[self fileManager] createDirectoryAtPath:[self thumbnailCachePath] withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    population = (int)[peopleFound count];
    
    for (int j = 0; j < population; j++) {
        ABRecord *r = peopleFound[j];
        NSMutableString *outDisplayName = [NSMutableString string];
        
        if (!(callType_ & CTBuildFullThumbnailCache)) {
            hasGeneratedOutputsForFirstContact_ = j >= 1;
            
            NSString *lastName = [r valueForProperty:kABLastNameProperty];
            NSString *firstName = [r valueForProperty:kABFirstNameProperty];
            NSString *middleName = [r valueForProperty:kABMiddleNameProperty];
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
            if ([outDisplayName length] > 0)
                // delete trailing space
                [outDisplayName deleteCharactersInRange:NSMakeRange([outDisplayName length]-1, 1)];
            else
                outDisplayName = [r valueForProperty:kABOrganizationProperty];
        }
        
        // output available results for each person according to the order defined by callTypes, i.e. the order of the options specified by user
        for (int i = 0; i < [callTypes_ count]; i++) {
            switch ([callTypes_[i] integerValue]) {
                case CTSkype: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.23137f green:0.72941f blue:0.93725f alpha:1.0f];
                    NSString *skypeThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:Skype.tiff", [r uniqueId]];
                    NSString *skypeOnlineThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:Skype:Online.tiff", [r uniqueId]];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:skypeThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    [self checkAndUpdateThumbnailIfNeededAtPath:skypeOnlineThumbnailPath forRecord:r withColor:color hasShadow:YES];
                    
                    if (!isThumbNailOkay) {
                        skypeThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:Skype.tiff"];
                        skypeOnlineThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:Skype:Online.tiff"];
                        // generate default thumbnails
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:skypeThumbnailPath withColor:color hasShadow:NO];
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:skypeOnlineThumbnailPath withColor:color hasShadow:YES];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableArray *bufferedResults = [NSMutableArray array];
                        
                        // output Skype usernames
                        ABMultiValue *ims = [r valueForProperty:kABInstantMessageProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSDictionary *entry = [ims valueAtIndex:i];
                            if ([entry[kABInstantMessageServiceKey] isEqualToString: kABInstantMessageServiceSkype]) {
                                NSString *username = entry[kABInstantMessageUsernameKey];
                                BOOL isOnline = [[UniCall runCommand:[NSString stringWithFormat:@"/usr/bin/osascript \"%@\" [STATUS]%@", [self skypeScptPath], username]] hasPrefix:@"1"];
                                if (isOnline)
                                    [bufferedResults insertObject:[NSString stringWithFormat:@"<item uid=\"%@:Skype:Online\" arg=\"[CTSkype]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to Skype username: %@ (online)</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], username, username, outDisplayName, username, skypeOnlineThumbnailPath] atIndex:0];
                                else
                                    [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:Skype\" arg=\"[CTSkype]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to Skype username: %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], username, username, outDisplayName, username, skypeThumbnailPath]];
                            }
                        }
                        
                        // output phone numbers
                        ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [ims valueAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processPhoneLabel:[ims labelAtIndex:i]];
                            
                            [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:Skype\" arg=\"[CTSkype]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to phone number: %@ %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, processedPhoneLabels[@"toDisplay"], phoneNum, skypeThumbnailPath]];
                        }
                        
                        if ([self fillResults:results withBufferedResults:bufferedResults])
                            goto end_result_generation;
                    }
                    
                    break;
                }
                case CTFaceTime: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.97647f green:0.29412f blue:0.60000f alpha:1.0f];
                    NSString *faceTimeThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:FaceTime.tiff", [r uniqueId]];
                    NSString *faceTimeNominatedThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:FaceTime:Nominated.tiff", [r uniqueId]];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:faceTimeThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    [self checkAndUpdateThumbnailIfNeededAtPath:faceTimeNominatedThumbnailPath forRecord:r withColor:color hasShadow:YES];
                    
                    if (!isThumbNailOkay) {
                        faceTimeThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:FaceTime.tiff"];
                        faceTimeNominatedThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:FaceTime:Nominated.tiff"];
                        // generate default thumbnails
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:faceTimeThumbnailPath withColor:color hasShadow:NO];
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:faceTimeNominatedThumbnailPath withColor:color hasShadow:YES];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableArray *bufferedResults = [NSMutableArray array];
                        
                        // output phone numbers
                        NSMutableIndexSet *nominatedResultsIndices = [NSMutableIndexSet indexSet];
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [ims valueAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processPhoneLabel:[ims labelAtIndex:i]];
                            
                            if ([sFaceTimeNominatedPhoneLabels intersectsSet:processedPhoneLabels[@"toConsume"]]) {
                                [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:FaceTime:Nominated\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime call to phone number: %@ %@ (nominated)</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, processedPhoneLabels[@"toDisplay"], phoneNum, faceTimeNominatedThumbnailPath]];
                                [nominatedResultsIndices addIndex:i];
                            } else
                                [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:FaceTime\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime call to phone number: %@ %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName,  processedPhoneLabels[@"toDisplay"], phoneNum, faceTimeThumbnailPath]];
                        }
                        
                        // output emails
                        ims = [r valueForProperty:kABEmailProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *email = [ims valueAtIndex:i];
                            
                            if ([sFaceTimeNominatedPhoneLabels containsObject:[[ims labelAtIndex:i] lowercaseString]]) {
                                [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:FaceTime:Nominated\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime call to email address: %@ (nominated)</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], email, email, outDisplayName, email, faceTimeNominatedThumbnailPath]];
                                [nominatedResultsIndices addIndex:[bufferedResults count] - 1];
                            } else
                                [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:FaceTime\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime call to email address: %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], email, email, outDisplayName, email, faceTimeThumbnailPath]];
                        }
                        
                        if ([nominatedResultsIndices count] > 0)
                            [bufferedResults setArray:[bufferedResults objectsAtIndexes:nominatedResultsIndices]];
                        
                        if ([self fillResults:results withBufferedResults:bufferedResults])
                            goto end_result_generation;
                    }
                    
                    break;
                }
                case CTPhoneAmego: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:1.00000f green:0.74118f blue:0.30196f alpha:1.0f];
                    NSString *phoneAmegoThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:PhoneAmego.tiff", [r uniqueId]];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:phoneAmegoThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        phoneAmegoThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:PhoneAmego.tiff"];
                        // generate default thumbnails
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:phoneAmegoThumbnailPath withColor:color hasShadow:NO];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableArray *bufferedResults = [NSMutableArray array];
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [ims valueAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processPhoneLabel:[ims labelAtIndex:i]];
                            
                            NSString *deviceLabel = nil;
                            if (extraParameter_) {
                                deviceLabel = config_[@"phoneAmegoDeviceAliases"][extraParameter_];
                            }
                            
                            [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:PhoneAmego\" arg=\"[CTPhoneAmego]%@%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Bluetooth phone call to phone number: %@ %@ via Phone Amego</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, deviceLabel ? [NSString stringWithFormat:@";device=%@", deviceLabel] : @"", phoneNum, outDisplayName, processedPhoneLabels[@"toDisplay"], phoneNum, phoneAmegoThumbnailPath]];
                        }
                        
                        if ([self fillResults:results withBufferedResults:bufferedResults])
                            goto end_result_generation;
                    }
                    
                    break;
                }
                case CTSIP: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.50588f green:0.20784f blue:0.65882f alpha:1.0f];
                    NSString *sipThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:SIP.tiff", [r uniqueId]];
                    NSString *sipRecordedThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:SIP:Recorded.tiff", [r uniqueId]];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:sipThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    [self checkAndUpdateThumbnailIfNeededAtPath:sipRecordedThumbnailPath forRecord:r withColor:color hasShadow:YES];
                    
                    if (!isThumbNailOkay) {
                        sipThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:SIP.tiff"];
                        sipRecordedThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:SIP:Recorded.tiff"];
                        // generate default thumbnails
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:sipThumbnailPath withColor:color hasShadow:NO];
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:sipRecordedThumbnailPath withColor:color hasShadow:YES];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableArray *bufferedResults = [NSMutableArray array];
                        
                        // output recorded SIP url
                        ABMultiValue *ims = [r valueForProperty:kABURLsProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            if ([[ims labelAtIndex:i] caseInsensitiveCompare:@"sip"] == NSOrderedSame) {
                                NSString *sIPUrl = [ims valueAtIndex:i];
                                
                                if ([sIPUrl hasPrefix:@"sip:"]) {
                                    if ([sIPUrl length] >= 4)
                                        sIPUrl = [sIPUrl substringFromIndex:4];
                                    else
                                        sIPUrl = @"";
                                }
                                
                                [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:SIP:Recorded\" arg=\"[CTSIP]sip:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>SIP call to SIP address: %@ (recorded)</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], sIPUrl, sIPUrl, outDisplayName, sIPUrl, sipRecordedThumbnailPath]];
                            }
                        }
                        
                        // output phone numbers
                        ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [ims valueAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processPhoneLabel:[ims labelAtIndex:i]];
                            
                            [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:SIP\" arg=\"[CTSIP]tel:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>SIP call to phone number: %@ %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, processedPhoneLabels[@"toDisplay"], phoneNum, sipThumbnailPath]];
                        }
                        
                        if ([self fillResults:results withBufferedResults:bufferedResults])
                            goto end_result_generation;
                    }

                    break;
                }
                case CTPushDialer: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.62745f green:0.32157f blue:0.17647f alpha:1.0f];
                    NSString *pushDialerThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:PushDialer.tiff", [r uniqueId]];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:pushDialerThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        pushDialerThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:PushDialer.tiff"];
                        // generate default thumbnails
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:pushDialerThumbnailPath withColor:color hasShadow:NO];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableArray *bufferedResults = [NSMutableArray array];
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [ims valueAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processPhoneLabel:[ims labelAtIndex:i]];
                            
                            [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:PushDialer\" arg=\"[CTPushDialer]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>PushDialer call to phone number: %@ %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, processedPhoneLabels[@"toDisplay"], phoneNum, pushDialerThumbnailPath]];
                        }
                        
                        if ([self fillResults:results withBufferedResults:bufferedResults])
                            goto end_result_generation;
                    }
                    
                    break;
                }
                case CTGrowlVoice: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.21569f green:0.65882f blue:0.20784f alpha:1.0f];
                    NSString *growlVoiceThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:GrowlVoice.tiff", [r uniqueId]];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:growlVoiceThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        growlVoiceThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:GrowlVoice.tiff"];
                        // generate default thumbnails
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:growlVoiceThumbnailPath withColor:color hasShadow:NO];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableArray *bufferedResults = [NSMutableArray array];
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [ims valueAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processPhoneLabel:[ims labelAtIndex:i]];
                            
                            [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:GrowlVoice\" arg=\"[CTGrowlVoice]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Google Voice call to phone number: %@ %@ via GrowlVoice</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, processedPhoneLabels[@"toDisplay"], phoneNum, growlVoiceThumbnailPath]];
                        }
                        
                        if ([self fillResults:results withBufferedResults:bufferedResults])
                            goto end_result_generation;
                    }
                    
                    break;
                }
                case CTCallTrunk: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.082353f green:0.278431f blue:0.235294f alpha:1.0f];
                    NSString *callTrunkThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:CallTrunk.tiff", [r uniqueId]];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:callTrunkThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        callTrunkThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:CallTrunk.tiff"];
                        // generate default thumbnails
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:callTrunkThumbnailPath withColor:color hasShadow:NO];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableArray *bufferedResults = [NSMutableArray array];
                        
                        NSString *country = nil;
                        if (extraParameter_) {
                            country = [extraParameter_ uppercaseString];
                        }
                        if (!country) {
                            country = config_[@"callTrunkDefaultCountry"];
                            if (!country) {
                                NSDictionary *candidate = [self checkAvailableCallTrunkCountries];
                                if ([candidate count] > 0) {
                                    country = [candidate allValues][0]; // randomly pick an available one
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
                            NSString *phoneNum = [ims valueAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processPhoneLabel:[ims labelAtIndex:i]];
                            
                            [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:CallTrunk\" arg=\"[CTCallTrunk]%@/%@\" autocomplete=\"%@\"><title>%@</title><subtitle>CallTrunk call to phone number: %@ %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, country, phoneNum, outDisplayName, processedPhoneLabels[@"toDisplay"], phoneNum, callTrunkThumbnailPath]];
                        }
                        
                        if ([self fillResults:results withBufferedResults:bufferedResults])
                            goto end_result_generation;
                    }
                    
                    break;
                }
                case CTFritzBox: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:0.81961f green:0.25490f blue:0.21569f alpha:1.0f];
                    NSString *fritzBoxThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:Fritz!Box.tiff", [r uniqueId]];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:fritzBoxThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        fritzBoxThumbnailPath = [[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail:Fritz!Box.tiff"];
                        // generate default thumbnails
//                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:fritzBoxThumbnailPath withColor:color hasShadow:NO];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableArray *bufferedResults = [NSMutableArray array];
                        
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [ims valueAtIndex:i];
                            NSDictionary *processedPhoneLabels = [self processPhoneLabel:[ims labelAtIndex:i]];
                            
                            [bufferedResults addObject:[NSString stringWithFormat:@"<item uid=\"%@:Fritz!Box\" arg=\"[CTFritzBox]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Fritz!Box call to phone number: %@ %@ via Frizzix</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, processedPhoneLabels[@"toDisplay"], phoneNum, fritzBoxThumbnailPath]];
                        }
                        
                        if ([self fillResults:results withBufferedResults:bufferedResults])
                            goto end_result_generation;
                    }
                    
                    break;
                }
            }
        }
    }
end_result_generation:
    
    if (callType_ & CTBuildFullThumbnailCache) {
        //        [self releaseExecutionLock];
        //        [self pushNotificationWithTitle:@"Finished" andMessage:@"building full thumbnail cache" andDetail:@"You have successfully used Uni Call option -#."];
        return @"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"done\" arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --buildfullthumbnailcache</title><subtitle>Done. Contact thumbnail cache is now fully built</subtitle><icon>buildFullThumbnailCache.png</icon></item></items>\n";
    } else {
        if ([peopleFound count] == 0) {
//            query = (__bridge NSString *)CFXMLCreateStringByEscapingEntities(NULL, (__bridge CFStringRef)query, NULL);
            query = [self xmlSimpleEscape:query];
            
            for (int i = 0; i < [callTypes_ count]; i++) {
                switch ([callTypes_[i] integerValue]) {
                    case CTSkype:
                        [results appendFormat:@"<item uid=\"%@:Skype\" arg=\"[CTSkype]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to: %@ (unidentified in Apple Contacts)</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>", query, query, query, query, query];
                        break;
                    case CTFaceTime:
                        [results appendFormat:@"<item uid=\"%@:FaceTime\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime call to: %@ (unidentified in Apple Contacts)</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>", query, query, query, query, query];
                        break;
                    case CTPhoneAmego: {
                        NSString *deviceLabel = nil;
                        if (extraParameter_) {
                            deviceLabel = config_[@"phoneAmegoDeviceAliases"][extraParameter_];
                        }
                        
                        [results appendFormat:@"<item uid=\"%@:PhoneAmego\" arg=\"[CTPhoneAmego]%@%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Bluetooth phone call to: %@ via Phone Amego (unidentified in Apple Contacts)</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>", query, query, deviceLabel ? [NSString stringWithFormat:@";device=%@", deviceLabel] : @"", query, query, query];
                        break;
                    }
                    case CTSIP: {
                        if([query rangeOfString:@"@"].location != NSNotFound) {
                            NSString *sIPUrl = query;
                            if ([sIPUrl hasPrefix:@"sip:"]) {
                                sIPUrl = [sIPUrl substringFromIndex:4];
                            }
                            [results appendFormat:@"<item uid=\"%@:SIP\" arg=\"[CTSIP]sip:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>SIP call to: %@ (unidentified in Apple Contacts)</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5.png</icon></item>", sIPUrl, sIPUrl, sIPUrl, sIPUrl, sIPUrl];
                        } else {
                            NSString *sIPUrl = query;
                            if ([sIPUrl hasPrefix:@"tel:"]) {
                                if ([sIPUrl length] >= 4)
                                    sIPUrl = [sIPUrl substringFromIndex:4];
                                else
                                    sIPUrl = @"";
                            }
                            [results appendFormat:@"<item uid=\"%@:SIP\" arg=\"[CTSIP]tel:%@\" autocomplete=\"%@\"><title>%@</title><subtitle>SIP call to: %@ (unidentified in Apple Contacts)</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5.png</icon></item>", sIPUrl, sIPUrl, sIPUrl, sIPUrl, sIPUrl];
                        }
                        
                        break;
                    }
                    case CTPushDialer:
                        [results appendFormat:@"<item uid=\"%@:PushDialer\" arg=\"[CTPushDialer]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>PushDialer call to: %@ (unidentified in Apple Contacts)</subtitle><icon>4E251686-06AC-44A9-8C74-C6A03158E9DC.png</icon></item>", query, query, query, query, query];
                        break;
                    case CTGrowlVoice:
                        [results appendFormat:@"<item uid=\"%@:GrowlVoice\" arg=\"[CTGrowlVoice]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Google Voice call to: %@ via GrowlVoice (unidentified in Apple Contacts)</subtitle><icon>07913B02-FCA2-4435-B010-A160ECC14BDF.png</icon></item>", query, query, query, query, query];
                        break;
                    case CTCallTrunk: {
                        NSString *country = nil;
                        if (extraParameter_) {
                            country = [extraParameter_ uppercaseString];
                        }
                        if (!country) {
                            country = config_[@"callTrunkDefaultCountry"];
                            if (!country) {
                                NSDictionary *candidate = [self checkAvailableCallTrunkCountries];
                                if ([candidate count] > 0) {
                                    country = [candidate allValues][0]; // randomly pick an available one
                                    [config_ setObject:country forKey:@"callTrunkDefaultCountry"];
                                    [config_ writeToFile:[self configPlistPath] atomically:YES];
                                } else {
                                    country = @"US";
                                }
                            }
                        }
                        
                        [results appendFormat:@"<item uid=\"%@:CallTrunk\" arg=\"[CTCallTrunk]%@/%@\" autocomplete=\"%@\"><title>%@</title><subtitle>CallTrunk call to: %@ (unidentified in Apple Contacts)</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>", query, query, country, query, query, query];
                        break;
                    }
                    case CTFritzBox:
                        [results appendFormat:@"<item uid=\"%@:Fritz!Box\" arg=\"[CTFritzBox]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Fritz!Box call to: %@ via Frizzix (unidentified in Apple Contacts)</subtitle><icon>05088DC0-D882-4E8B-B130-F087F7C04FC2.png</icon></item>", query, query, query, query, query];
                        break;
                }
            }
        }
        
        [results appendString:@"</items>\n"];
        return results;
    }
}

-(BOOL)fillResults:(NSMutableString *)results withBufferedResults:(NSMutableArray *)bufferedResults
{
    int numOfResultsToFillIn = (int)[bufferedResults count];
    
    if (hasGeneratedOutputsForFirstContact_) {
        int quota = MAX(RESULT_NUM_LIMIT - resultCount_, 0);
        int numOfResultsToDiscard = numOfResultsToFillIn - quota;
        
        if (numOfResultsToDiscard > 0) {
            // can't fill in all buffer
            numOfResultsToFillIn -= numOfResultsToDiscard;
            [bufferedResults removeObjectsInRange:NSMakeRange(numOfResultsToFillIn, numOfResultsToDiscard)];
        }
    }
    
    [results appendString:[bufferedResults componentsJoinedByString:@""]];
    resultCount_ += numOfResultsToFillIn;
    return hasGeneratedOutputsForFirstContact_ ? resultCount_ >= RESULT_NUM_LIMIT : NO;
}

#pragma mark -
#pragma mark Process Options

- (NSString *)skypeCallOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-s\" valid=\"no\"><title>Uni Call Option -s</title><subtitle>Make a Skype call to your contact</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>";
    
    return help;
}

- (NSString *)faceTimeCallOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-f\" valid=\"no\"><title>Uni Call Option -f</title><subtitle>Make a FaceTime call to your contact</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>";
    
    return help;
}

- (NSString *)phoneAmegoCallOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-p\" valid=\"no\"><title>Uni Call Option -p</title><subtitle>Make a bluetooth phone call to your contact via Phone Amego</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>";
    
    return help;
}

- (NSString *)phoneAmegoMapOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-p-map\" valid=\"no\"><title>Phone Amego Call Option --map</title><subtitle>Use \"callp --map ALIAS to DEVICE_LABEL yes\" to assign an alias to a bluetooth device</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>";
    
    return help;
}

- (NSString *)phoneAmegoUnmapOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-p-unmap\" valid=\"no\"><title>Phone Amego Call Option --unmap</title><subtitle>Use \"callp --unmap ALIAS yes\" to remove the assigned alias</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>";
    
    return help;
}

- (NSString *)phoneAmegoLongOptionHelp
{
    static NSString *help = nil;
    
    if (!help) {
        help = [@[[self phoneAmegoMapOptionHelp],
                   [self phoneAmegoUnmapOptionHelp]] componentsJoinedByString:@""];
    }
    
    return help;
}

- (NSString *)sIPCallOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-i\" valid=\"no\"><title>Uni Call Option -i</title><subtitle>Make a SIP call to your contact via Telephone</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5.png</icon></item>";
    
    return help;
}

- (NSString *)pushDialerCallOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-d\" valid=\"no\"><title>Uni Call Option -d</title><subtitle>Make a PushDialer call to your contact</subtitle><icon>4E251686-06AC-44A9-8C74-C6A03158E9DC.png</icon></item>";
    
    return help;
}

- (NSString *)growlVoiceCallOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-g\" valid=\"no\"><title>Uni Call Option -g</title><subtitle>Make a Google Voice call to your contact via GrowlVoice</subtitle><icon>07913B02-FCA2-4435-B010-A160ECC14BDF.png</icon></item>";
    
    return help;
}

- (NSString *)callTrunkCallOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-k\" valid=\"no\"><title>Uni Call Option -k</title><subtitle>Make a CallTrunk call to your contact</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>";
    
    return help;
}

- (NSString *)callTrunkSetDefaultCountryOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-k-setdefaultcountry\" valid=\"no\"><title>CallTrunk Call Option --setdefaultcountry</title><subtitle>Use \"callk --setdefaultcountry COUNTRY_CODE yes\" to set the default country</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>";
    
    return help;
}

- (NSString *)callTrunkLongOptionHelp
{
    static NSString *help = nil;
    
    if (!help) {
        help = [self callTrunkSetDefaultCountryOptionHelp];
    }
    
    return help;
}

- (NSString *)fritzBoxCallOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"-z\" valid=\"no\"><title>Uni Call Option -z</title><subtitle>Make a Fritz!Box call to your contact via Frizzix</subtitle><icon>05088DC0-D882-4E8B-B130-F087F7C04FC2.png</icon></item>";
    
    return help;
}

- (NSString *)noThumbnailCacheOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" valid=\"no\"><title>Uni Call Option -!</title><subtitle>Prohibit contact thumbnails caching</subtitle><icon>shouldNotCacheThumbnail.png</icon></item>";
    
    return help;
}

- (NSString *)buildFullThumbnailCacheOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"--buildfullthumbnailcache\" valid=\"no\"><title>Uni Call Option --buildfullthumbnailcache</title><subtitle>Use \"call --buildfullthumbnailcache yes\" to start building full contact thumbnail cache</subtitle><icon>buildFullThumbnailCache.png</icon></item>";
    
    return help;
}

- (NSString *)destroyThumbnailCacheOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"--destroythumbnailcache\" valid=\"no\"><title>Uni Call Option --destroythumbnailcache</title><subtitle>Use \"call --destroythumbnailcache yes\" to start destroying contact thumbnail cache</subtitle><icon>destroyThumbnailCache.png</icon></item>";
    
    return help;
}

- (NSString *)enableOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"--enable\" valid=\"no\"><title>Uni Call Option --enable</title><subtitle>Use \"call --enable COMPONENT_CODES yes\" to enable call components</subtitle><icon>enableCallComponents.png</icon></item>";
    
    return help;
}

- (NSString *)disableOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"--disable\" valid=\"no\"><title>Uni Call Option --disable</title><subtitle>Use \"call --disable COMPONENT_CODES yes\" to disable call components</subtitle><icon>disableCallComponents.png</icon></item>";
    
    return help;
}

- (NSString *)updateAlfredPreferencesOptionHelp
{
    static NSString *help = @"<item uid=\"\" arg=\"\" autocomplete=\"--updatealfredpreferences\" valid=\"no\"><title>Uni Call Option --updatealfredpreferences</title><subtitle>Use \"call --updatealfredpreferences yes\" to update Alfred Preferences to reflect your call component settings</subtitle><icon>updateAlfredPreferences.png</icon></item>";
    
    return help;
}

- (NSString *)longOptionHelp
{
    static NSString *help = nil;
    
    if (!help) {
        help = [@[[self enableOptionHelp],
                  [self disableOptionHelp],
                  [self updateAlfredPreferencesOptionHelp],
                  [self buildFullThumbnailCacheOptionHelp],
                  [self destroyThumbnailCacheOptionHelp]] componentsJoinedByString:@""];
    }
    
    return help;
}

- (NSString *)outputHelpOnOptions
{
    return [@[[NSString stringWithFormat:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"\" arg=\"\" valid=\"no\"><title>List of Uni Call Options</title><subtitle>%@: use any combination of %@a!; use -- for long options</subtitle><icon>listOfUniCallOptions.png</icon></item>", VERSION, [self getOptionsFromCallType:enabledCallType_]], [self noThumbnailCacheOptionHelp], @"<item uid=\"\" arg=\"\" autocomplete=\"-a\" valid=\"no\"><title>Uni Call Option -a (default)</title><subtitle>Lay out all possible call options for your contact</subtitle><icon>icon.png</icon></item>",
                    enabledCallType_ & CTSkype ? [self skypeCallOptionHelp] : @"",
                    enabledCallType_ & CTFaceTime ? [self faceTimeCallOptionHelp] : @"",
                    enabledCallType_ & CTPhoneAmego ?[self phoneAmegoCallOptionHelp] : @"",
                    enabledCallType_ & CTSIP ? [self sIPCallOptionHelp] : @"",
                    enabledCallType_ & CTPushDialer ? [self pushDialerCallOptionHelp] : @"",
                    enabledCallType_ & CTGrowlVoice ? [self growlVoiceCallOptionHelp] : @"",
                    enabledCallType_ & CTCallTrunk ? [self callTrunkCallOptionHelp] : @"",
                    enabledCallType_ & CTFritzBox ? [self fritzBoxCallOptionHelp] : @"",
                   [self longOptionHelp],
                    @"</items>\n"] componentsJoinedByString:@""];
}

- (NSString *)getOptionsFromCallType:(CallType)callType
{
    NSMutableString *results = [NSMutableString stringWithString:@"-"];
    if (callType & CTSkype)
        [results appendString:@"s"];
    if (callType & CTFaceTime)
        [results appendString:@"f"];
    if (callType & CTPhoneAmego)
        [results appendString:@"p"];
    if (callType & CTSIP)
        [results appendString:@"i"];
    if (callType & CTPushDialer)
        [results appendString:@"d"];
    if (callType & CTGrowlVoice)
        [results appendString:@"g"];
    if (callType & CTCallTrunk)
        [results appendFormat:@"k"];
    if (callType & CTFritzBox)
        [results appendFormat:@"z"];
    return results;
}

- (CallType)getCallTypeFromComponentCodes:(NSString *)codes
{
    CallType tmp = 0;
    for (int i = 0; i < [codes length]; i++) {
        switch ([codes characterAtIndex:i]) {
            case 's':
                tmp |= CTSkype;
                break;
            case 'f':
                tmp |= CTFaceTime;
                break;
            case 'p':
                tmp |= CTPhoneAmego;
                break;
            case 'i':
                tmp |= CTSIP;
                break;
            case 'd':
                tmp |= CTPushDialer;
                break;
            case 'g':
                tmp |= CTGrowlVoice;
                break;
            case 'k':
                tmp |= CTCallTrunk;
                break;
            case 'z':
                tmp |= CTFritzBox;
                break;
        }
    }
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
        switch ([options characterAtIndex:i]) {
            case '-':
                if (callType_ & CTPhoneAmego) {
                    [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items>"];
                    if (i + 1 < [options length]) {
                        NSString *longOption = [options substringFromIndex:i + 1];
                        
                        if ([@"map" hasPrefix:longOption]) {
                            if ([longOption isEqualToString:@"map"]) {
                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items>"];
                                [results appendString:[self phoneAmegoMapOptionHelp]];
                                
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
                                    
                                    [results setString:[NSString stringWithFormat:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"done\" arg=\"\" autocomplete=\"-p-\" valid=\"no\"><title>Phone Amego Call Option --map</title><subtitle>Done. Assigned alias %@ to device %@</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>", chosenAlias, deviceLabel]];
                                } else if (restQueryMatches && [restQueryMatches count] >= 3 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"to"]) {
                                    // alias has chosen
                                    NSString *chosenAlias = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                    NSString *deviceLabel = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[2]]];
                                    
                                    [results appendFormat:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>%@ to %@</title><subtitle>Use \"callp TARGET /%@\" to call the TARGET through device %@</subtitle><icon>edit-active.png</icon></item>", chosenAlias, deviceLabel, chosenAlias, deviceLabel];
                                } else if (restQueryMatches && [restQueryMatches count] >= 1) {
                                    // show existing mappings whose prefixes match the typed alias
                                    BOOL hasMatch = NO;
                                    NSString *chosenAlias = [query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]];
                                    
                                    for (NSString *key in [phoneAmegoDeviceAliases allKeys]) {
                                        if ([key hasPrefix:chosenAlias]) {
                                            hasMatch = YES;
                                            NSString *value = phoneAmegoDeviceAliases[key];
                                            [results appendFormat:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>%@ to %@</title><subtitle>Use \"callp TARGET /%@\" to call the TARGET through device %@</subtitle><icon>edit-inactive.png</icon></item>", key, value, key, value];
                                        }
                                    }
                                    
                                    if (!hasMatch)
                                        [results appendFormat:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>%@ to SOME_DEVICE</title><subtitle>Use \"callp TARGET /%@\" to call the TARGET through device SOME_DEVICE</subtitle><icon>edit-active.png</icon></item>", chosenAlias, chosenAlias];
                                } else {
                                    // show all alias
                                    for (NSString *key in [phoneAmegoDeviceAliases allKeys]) {
                                        NSString *value = phoneAmegoDeviceAliases[key];
                                        [results appendFormat:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>%@ to %@</title><subtitle>Use \"callp TARGET /%@\" to call the TARGET through device %@</subtitle><icon>edit-inactive.png</icon></item>", key, value, key, value];
                                    }
                                }
                                
                                return YES;
                            } else {
                                [results appendString:[self phoneAmegoMapOptionHelp]];
                            }
                        }
                        
                        if ([@"unmap" hasPrefix:longOption]) {
                            if ([longOption isEqualToString:@"unmap"]) {
                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items>"];
                                [results appendString:[self phoneAmegoUnmapOptionHelp]];
                                
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
                                        [results setString:[NSString stringWithFormat:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"done\" arg=\"\" autocomplete=\"-p-\" valid=\"no\"><title>Phone Amego Call Option --unmap</title><subtitle>Done. Removed alias %@ to device %@</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>", actualAlias, phoneAmegoDeviceAliases[actualAlias]]];
                                        
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
                                            [results appendFormat:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>%@ to %@</title><subtitle>Use \"callp TARGET /%@\" to call the TARGET through device %@</subtitle><icon>edit-%@.png</icon></item>", key, value, key, value, isFirstMatch ? @"active" : @"inactive"];
                                            isFirstMatch = NO;
                                        }
                                    }
                                } else {
                                    // show all alias
                                    for (NSString *key in [phoneAmegoDeviceAliases allKeys]) {
                                        NSString *value = phoneAmegoDeviceAliases[key];
                                        [results appendFormat:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>%@ to %@</title><subtitle>Use \"callp TARGET /%@\" to call the TARGET through device %@</subtitle><icon>edit-inactive.png</icon></item>", key, value, key, value];
                                    }
                                }
                                
                                return YES;
                            } else {
                                [results appendString:[self phoneAmegoUnmapOptionHelp]];
                            }
                        }
                        
                        if ([results isEqualToString:@"\n<?xml version=\"1.0\"?>\n\n<items>"])
                            [results appendString:[self phoneAmegoLongOptionHelp]];
                    } else {
                        [results appendString:[self phoneAmegoLongOptionHelp]];
                    }
                    
                    return YES;
                } else if (callType_ & CTCallTrunk) {
                    [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items>"];
                    if (i + 1 < [options length]) {
                        NSString *longOption = [options substringFromIndex:i + 1];
                        
                        if ([@"setdefaultcountry" hasPrefix:longOption]) {
                            if ([longOption isEqualToString:@"setdefaultcountry"]) {
                                NSDictionary *availableCountries = [self checkAvailableCallTrunkCountries];
                                
                                if (restQueryMatches && [restQueryMatches count] == 2 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"yes"]) {
                                    NSString *chosenCountry = [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] uppercaseString];
                                    if (availableCountries[chosenCountry]) {
                                        [config_ setObject:chosenCountry forKey:@"callTrunkDefaultCountry"];
                                        [config_ writeToFile:[self configPlistPath] atomically:YES];
                                        
                                        [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"done\" arg=\"\" autocomplete=\"-\" valid=\"no\"><title>CallTrunk Call Option --setdefaultcountry</title><subtitle>Done. The default country for CallTrunk has now been set.</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>"];
                                    } else {
                                        [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"error\" arg=\"\" valid=\"no\"><title>CallTrunk Call Option --setdefaultcountry</title><subtitle>Error: the country code is invalid! Please make sure you have installed the country specific Call Trunck app</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>"];
                                    }
                                } else {
                                    [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items>"];
                                    [results appendString:[self callTrunkSetDefaultCountryOptionHelp]];
                                    
                                    NSString *callTrunkDefaultCountry = config_[@"callTrunkDefaultCountry"];
                                    NSString *previewCountry = nil;
                                    
                                    if (restQueryMatches && [restQueryMatches count] > 0) {
                                        previewCountry = [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] uppercaseString];
                                    }
                                    
                                    for (NSString *c in availableCountries) {
                                        [results appendFormat:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Country Code %@</title><subtitle>%@</subtitle><icon>country%@.png</icon></item>", c, [c isEqualToString:callTrunkDefaultCountry] ? [NSString stringWithFormat:@"%@ (current default)", availableCountries[c]] : availableCountries[c], [c isEqualToString:previewCountry] || (!previewCountry && [c isEqualToString:callTrunkDefaultCountry]) ? [NSString stringWithFormat:@"%@-chosen", c] : c];
                                    }
                                }
                                
                                return YES;
                            } else {
                                [results appendString:[self callTrunkSetDefaultCountryOptionHelp]];
                            }
                        }
                        
                        if ([results isEqualToString:@"\n<?xml version=\"1.0\"?>\n\n<items>"])
                            [results appendString:[self callTrunkLongOptionHelp]];
                    } else {
                        [results appendString:[self callTrunkLongOptionHelp]];
                    }
                    
                    return YES;
                } else {
                    if (i + 1 < [options length]) {
                        [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items>"];
                        NSString *longOption = [options substringFromIndex:i + 1];
                        
                        if ([@"enable" hasPrefix:longOption]) {
                            if ([longOption isEqualToString:@"enable"]) {
                                if (restQueryMatches && [restQueryMatches count] == 2 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[1]]] isEqualToString:@"yes"]) {
                                    CallType selectedCodes = [self getCallTypeFromComponentCodes:[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]]];
                                    CallType changedCodes = enabledCallType_;
                                    enabledCallType_ |= selectedCodes;
                                    changedCodes ^= enabledCallType_;
                                    NSString *operation = @"add";
                                    
                                    NSMutableDictionary *infoPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"]];
                                    NSDictionary *prefLibPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/prefLib.plist"]];
                                    if (changedCodes & CTFritzBox)
                                        [self manipulateInfoPlistWithComponentName:@"Fritz!Box Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTCallTrunk)
                                        [self manipulateInfoPlistWithComponentName:@"CallTrunk Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTGrowlVoice)
                                        [self manipulateInfoPlistWithComponentName:@"GrowlVoice Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTPushDialer)
                                        [self manipulateInfoPlistWithComponentName:@"PushDialer Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTSIP)
                                        [self manipulateInfoPlistWithComponentName:@"SIP Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTPhoneAmego)
                                        [self manipulateInfoPlistWithComponentName:@"Phone Amego Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTFaceTime)
                                        [self manipulateInfoPlistWithComponentName:@"FaceTime Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTSkype)
                                        [self manipulateInfoPlistWithComponentName:@"Skype Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    [infoPlist writeToFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"] atomically:YES];
                                    
                                    [config_ setObject:[NSNumber numberWithInteger:(enabledCallType_ >> CALLTYPE_BOUNDARY)] forKey:@"callComponentStatus"];
                                    [config_ writeToFile:[self configPlistPath] atomically:YES];
                                    
                                    [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"done\" arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --enable</title><subtitle>Done. Now your selected call components are enabled</subtitle><icon>enableCallComponents.png</icon></item>"];
                                } else {
                                    [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items>"];
                                    [results appendString:[self enableOptionHelp]];
                                    CallType previewCodes = 0;
                                    if (restQueryMatches && [restQueryMatches count] > 0)
                                        previewCodes = [self getCallTypeFromComponentCodes:[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]]];
                                    if (!(enabledCallType_ & CTFritzBox)) {
                                        if (previewCodes & CTFritzBox)
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Fritz!Box Call Component Code z</title><subtitle>Make a Fritz!Box call to your contact via Frizzix</subtitle><icon>05088DC0-D882-4E8B-B130-F087F7C04FC2.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Fritz!Box Call Component Code z</title><subtitle>Make a Fritz!Box call to your contact via Frizzix</subtitle><icon>05088DC0-D882-4E8B-B130-F087F7C04FC2-disabled.png</icon></item>"];
                                    }
                                    if (!(enabledCallType_ & CTCallTrunk)) {
                                        if (previewCodes & CTCallTrunk)
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>CallTrunk Call Component Code k</title><subtitle>Make a CallTrunk call to your contact</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>CallTrunk Call Component Code k</title><subtitle>Make a CallTrunk call to your contact</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5-disabled.png</icon></item>"];
                                    }
                                    if (!(enabledCallType_ & CTGrowlVoice)) {
                                        if (previewCodes & CTGrowlVoice)
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>GrowlVoice Call Component Code g</title><subtitle>Make a Google Voice call to your contact via GrowlVoice</subtitle><icon>07913B02-FCA2-4435-B010-A160ECC14BDF.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>GrowlVoice Call Component Code g</title><subtitle>Make a Google Voice call to your contact via GrowlVoice</subtitle><icon>07913B02-FCA2-4435-B010-A160ECC14BDF-disabled.png</icon></item>"];
                                    }
                                    if (!(enabledCallType_ & CTPushDialer)) {
                                        if (previewCodes & CTPushDialer)
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>PushDialer Call Component Code d</title><subtitle>Make a PushDialer call to your contact</subtitle><icon>4E251686-06AC-44A9-8C74-C6A03158E9DC.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>PushDialer Call Component Code d</title><subtitle>Make a PushDialer call to your contact</subtitle><icon>4E251686-06AC-44A9-8C74-C6A03158E9DC-disabled.png</icon></item>"];
                                    }
                                    if (!(enabledCallType_ & CTSIP)) {
                                        if (previewCodes & CTSIP)
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>SIP Call Component Code i</title><subtitle>Make a SIP call to your contact via Telephone</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>SIP Call Component Code i</title><subtitle>Make a SIP call to your contact via Telephone</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5-disabled.png</icon></item>"];
                                    }
                                    if (!(enabledCallType_ & CTPhoneAmego)) {
                                        if (previewCodes & CTPhoneAmego)
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Phone Amego Call Component Code p</title><subtitle>Make a bluetooth phone call to your contact via Phone Amego</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Phone Amego Call Component Code p</title><subtitle>Make a bluetooth phone call to your contact via Phone Amego</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39-disabled.png</icon></item>"];
                                    }
                                    if (!(enabledCallType_ & CTFaceTime)) {
                                        if (previewCodes & CTFaceTime)
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>FaceTime Call Component Code f</title><subtitle>Make a FaceTime call to your contact</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>FaceTime Call Component Code f</title><subtitle>Make a FaceTime call to your contact</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA-disabled.png</icon></item>"];
                                    }
                                    if (!(enabledCallType_ & CTSkype)) {
                                        if (previewCodes & CTSkype)
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Skype Call Component Code s</title><subtitle>Make a Skype call to your contact</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Skype Call Component Code s</title><subtitle>Make a Skype call to your contact</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B-disabled.png</icon></item>"];
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
                                    changedCodes &= selectedCodes;
                                    NSString *operation = @"remove";
                                    
                                    NSMutableDictionary *infoPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"]];
                                    NSDictionary *prefLibPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/prefLib.plist"]];
                                    if (changedCodes & CTFritzBox)
                                        [self manipulateInfoPlistWithComponentName:@"Fritz!Box Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTCallTrunk)
                                        [self manipulateInfoPlistWithComponentName:@"CallTrunk Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTGrowlVoice)
                                        [self manipulateInfoPlistWithComponentName:@"GrowlVoice Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTPushDialer)
                                        [self manipulateInfoPlistWithComponentName:@"PushDialer Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTSIP)
                                        [self manipulateInfoPlistWithComponentName:@"SIP Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTPhoneAmego)
                                        [self manipulateInfoPlistWithComponentName:@"Phone Amego Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTFaceTime)
                                        [self manipulateInfoPlistWithComponentName:@"FaceTime Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    if (changedCodes & CTSkype)
                                        [self manipulateInfoPlistWithComponentName:@"Skype Call" andOperation:operation andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                    [infoPlist writeToFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"] atomically:YES];
                                    
                                    [config_ setObject:[NSNumber numberWithInteger:(enabledCallType_ >> CALLTYPE_BOUNDARY)] forKey:@"callComponentStatus"];
                                    [config_ writeToFile:[self configPlistPath] atomically:YES];
                                    
                                    [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"done\" arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --disable</title><subtitle>Done. Now your selected call components are disabled</subtitle><icon>disableCallComponents.png</icon></item>"];
                                } else {
                                    [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items>"];
                                    [results appendString:[self disableOptionHelp]];
                                    CallType previewCodes = 0;
                                    if (restQueryMatches && [restQueryMatches count] > 0)
                                        previewCodes = [self getCallTypeFromComponentCodes:[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]]];
                                    if (enabledCallType_ & CTFritzBox) {
                                        if (!(previewCodes & CTFritzBox))
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Fritz!Box Call Component Code z</title><subtitle>Make a Fritz!Box call to your contact via Frizzix</subtitle><icon>05088DC0-D882-4E8B-B130-F087F7C04FC2.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Fritz!Box Call Component Code z</title><subtitle>Make a Fritz!Box call to your contact via Frizzix</subtitle><icon>05088DC0-D882-4E8B-B130-F087F7C04FC2-disabled.png</icon></item>"];
                                    }
                                    if (enabledCallType_ & CTCallTrunk) {
                                        if (!(previewCodes & CTCallTrunk))
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>CallTrunk Call Component Code k</title><subtitle>Make a CallTrunk call to your contact</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>CallTrunk Call Component Code k</title><subtitle>Make a CallTrunk call to your contact</subtitle><icon>40A993D6-613C-4D0B-9083-E73ADD85C9B5-disabled.png</icon></item>"];
                                    }
                                    if (enabledCallType_ & CTGrowlVoice) {
                                        if (!(previewCodes & CTGrowlVoice))
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>GrowlVoice Call Component Code g</title><subtitle>Make a Google Voice call to your contact via GrowlVoice</subtitle><icon>07913B02-FCA2-4435-B010-A160ECC14BDF.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>GrowlVoice Call Component Code g</title><subtitle>Make a Google Voice call to your contact via GrowlVoice</subtitle><icon>07913B02-FCA2-4435-B010-A160ECC14BDF-disabled.png</icon></item>"];
                                    }
                                    if (enabledCallType_ & CTPushDialer) {
                                        if (!(previewCodes & CTPushDialer))
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>PushDialer Call Component Code d</title><subtitle>Make a PushDialer call to your contact</subtitle><icon>4E251686-06AC-44A9-8C74-C6A03158E9DC.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>PushDialer Call Component Code d</title><subtitle>Make a PushDialer call to your contact</subtitle><icon>4E251686-06AC-44A9-8C74-C6A03158E9DC-disabled.png</icon></item>"];
                                    }
                                    if (enabledCallType_ & CTSIP) {
                                        if (!(previewCodes & CTSIP))
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>SIP Call Component Code i</title><subtitle>Make a SIP call to your contact via Telephone</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>SIP Call Component Code i</title><subtitle>Make a SIP call to your contact via Telephone</subtitle><icon>D825394C-284F-4BC0-A8C8-3A00988225E5-disabled.png</icon></item>"];
                                    }
                                    if (enabledCallType_ & CTPhoneAmego) {
                                        if (!(previewCodes & CTPhoneAmego))
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Phone Amego Call Component Code p</title><subtitle>Make a bluetooth phone call to your contact via Phone Amego</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Phone Amego Call Component Code p</title><subtitle>Make a bluetooth phone call to your contact via Phone Amego</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39-disabled.png</icon></item>"];
                                    }
                                    if (enabledCallType_ & CTFaceTime) {
                                        if (!(previewCodes & CTFaceTime))
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>FaceTime Call Component Code f</title><subtitle>Make a FaceTime call to your contact</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>FaceTime Call Component Code f</title><subtitle>Make a FaceTime call to your contact</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA-disabled.png</icon></item>"];
                                    }
                                    if (enabledCallType_ & CTSkype) {
                                        if (!(previewCodes & CTSkype))
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Skype Call Component Code s</title><subtitle>Make a Skype call to your contact</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>"];
                                        else
                                            [results appendString:@"<item uid=\"\" arg=\"\" valid=\"no\"><title>Skype Call Component Code s</title><subtitle>Make a Skype call to your contact</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B-disabled.png</icon></item>"];
                                    }
                                }
                                return YES;
                            } else {
                                [results appendString:[self disableOptionHelp]];
                            }
                        }
                        
                        if ([@"updatealfredpreferences" hasPrefix:longOption]) {
                            if ([longOption isEqualToString:@"updatealfredpreferences"] && restQueryMatches && [restQueryMatches count] == 1 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] isEqualToString:@"yes"]) {
                                NSMutableDictionary *infoPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"]];
                                NSDictionary *prefLibPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingPathComponent:@"/prefLib.plist"]];
                                if (enabledCallType_ & CTSkype)
                                    [self manipulateInfoPlistWithComponentName:@"Skype Call" andOperation:@"add" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                else
                                    [self manipulateInfoPlistWithComponentName:@"Skype Call" andOperation:@"remove" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                if (enabledCallType_ & CTFaceTime)
                                    [self manipulateInfoPlistWithComponentName:@"FaceTime Call" andOperation:@"add" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                else
                                    [self manipulateInfoPlistWithComponentName:@"FaceTime Call" andOperation:@"remove" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                if (enabledCallType_ & CTPhoneAmego)
                                    [self manipulateInfoPlistWithComponentName:@"Phone Amego Call" andOperation:@"add" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                else
                                    [self manipulateInfoPlistWithComponentName:@"Phone Amego Call" andOperation:@"remove" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                if (enabledCallType_ & CTSIP)
                                    [self manipulateInfoPlistWithComponentName:@"SIP Call" andOperation:@"add" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                else
                                    [self manipulateInfoPlistWithComponentName:@"SIP Call" andOperation:@"remove" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                if (enabledCallType_ & CTPushDialer)
                                    [self manipulateInfoPlistWithComponentName:@"PushDialer Call" andOperation:@"add" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                else
                                    [self manipulateInfoPlistWithComponentName:@"PushDialer Call" andOperation:@"remove" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                if (enabledCallType_ & CTGrowlVoice)
                                    [self manipulateInfoPlistWithComponentName:@"GrowlVoice Call" andOperation:@"add" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                else
                                    [self manipulateInfoPlistWithComponentName:@"GrowlVoice Call" andOperation:@"remove" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                if (enabledCallType_ & CTCallTrunk)
                                    [self manipulateInfoPlistWithComponentName:@"CallTrunk Call" andOperation:@"add" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                else
                                    [self manipulateInfoPlistWithComponentName:@"CallTrunk Call" andOperation:@"remove" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                if (enabledCallType_ & CTFritzBox)
                                    [self manipulateInfoPlistWithComponentName:@"Fritz!Box Call" andOperation:@"add" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];
                                else
                                    [self manipulateInfoPlistWithComponentName:@"Fritz!Box Call" andOperation:@"remove" andInfoPlist:infoPlist andPrefLibPlist:prefLibPlist];

                                [infoPlist writeToFile:[[self workflowPath] stringByAppendingPathComponent:@"/info.plist"] atomically:YES];
                                
                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"done\" arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --updatealfredpreferences</title><subtitle>Done. Your Alfred Preferences are now updated to reflect your call component settings</subtitle><icon>updateAlfredPreferences.png</icon></item>"];
                                return YES;
                            } else {
                                [results appendString:[self updateAlfredPreferencesOptionHelp]];
                            }
                        }
                        
                        if ([@"buildfullthumbnailcache" hasPrefix:longOption]) {
                            if ([longOption isEqualToString:@"buildfullthumbnailcache"] && restQueryMatches && [restQueryMatches count] == 1 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] isEqualToString:@"yes"]) {
                                callType_ |= CTBuildFullThumbnailCache;
                                // carry out CTBuildFullThumbnailCache operation
                                //                    [self pushNotificationWithTitle:@"Started" andMessage:@"building full thumbnail cache" andDetail:@"Please sit tight. You are using Uni Call option -#."];
                                return NO;
                            } else {
                                [results appendString:[self buildFullThumbnailCacheOptionHelp]];
                            }
                        }
                        
                        if ([@"destroythumbnailcache" hasPrefix:longOption]) {
                            if ([longOption isEqualToString:@"destroythumbnailcache"] && restQueryMatches && [restQueryMatches count] == 1 && [[query substringWithRange:[self getRangeFromQueryMatch:restQueryMatches[0]]] isEqualToString:@"yes"]) {
                                // carry out CTDestroyThumbnailCache operation
                                //                    [self pushNotificationWithTitle:@"Started" andMessage:@"destroying thumbnail cache" andDetail:@"Please sit tight. You are using Uni Call option -$."];
                                [[self fileManager] removeItemAtPath:[self thumbnailCachePath] error:nil];
                                [results setString:@"\n<?xml version=\"1.0\"?>\n\n<items><item uid=\"done\" arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option --destroythumbnailcache</title><subtitle>Done. Contact thumbnail cache is now destroyed</subtitle><icon>destroyThumbnailCache.png</icon></item>"];
                                return YES;
                            } else {
                                [results appendString:[self destroyThumbnailCacheOptionHelp]];
                            }
                        }
                        
                        if ([results isEqualToString:@"\n<?xml version=\"1.0\"?>\n\n<items>"])
                            [results appendString:[self longOptionHelp]];
                    } else {
                        [results appendString:[self longOptionHelp]];
                    }
                    
                    return YES;
                }
            case 'a':
                [self processOptions:[self getOptionsFromCallType:enabledCallType_] withRestQueryMatches:restQueryMatches andQuery:query andResults:results];
                break;
            case 's':
                if ((enabledCallType_ & CTSkype) && !(callType_ & CTSkype)) {
                    callType_ |= CTSkype;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTSkype]];
                    [results appendString:[self skypeCallOptionHelp]];
                }
                break;
            case 'f':
                if ((enabledCallType_ & CTFaceTime) && !(callType_ & CTFaceTime)) {
                    callType_ |= CTFaceTime;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTFaceTime]];
                    [results appendString:[self faceTimeCallOptionHelp]];
                }
                break;
            case 'p':
                if ((enabledCallType_ & CTPhoneAmego) && !(callType_ & CTPhoneAmego)) {
                    callType_ |= CTPhoneAmego;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTPhoneAmego]];
                    [results appendString:[self phoneAmegoCallOptionHelp]];
                }
                break;
            case 'i':
                if ((enabledCallType_ & CTSIP) && !(callType_ & CTSIP)) {
                    callType_ |= CTSIP;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTSIP]];
                    [results appendString:[self sIPCallOptionHelp]];
                }
                break;
            case 'd':
                if ((enabledCallType_ & CTPushDialer) && !(callType_ & CTPushDialer)) {
                    callType_ |= CTPushDialer;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTPushDialer]];
                    [results appendString:[self pushDialerCallOptionHelp]];
                }
                break;
            case 'g':
                if ((enabledCallType_ & CTGrowlVoice) && !(callType_ & CTGrowlVoice)) {
                    callType_ |= CTGrowlVoice;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTGrowlVoice]];
                    [results appendString:[self growlVoiceCallOptionHelp]];
                }
                break;
            case 'k':
                if ((enabledCallType_ & CTCallTrunk) && !(callType_ & CTCallTrunk)) {
                    callType_ |= CTCallTrunk;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTCallTrunk]];
                    [results appendString:[self callTrunkCallOptionHelp]];
                }
                break;
            case 'z':
                if ((enabledCallType_ & CTFritzBox) && !(callType_ & CTFritzBox)) {
                    callType_ |= CTFritzBox;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTFritzBox]];
                    [results appendString:[self fritzBoxCallOptionHelp]];
                }
                break;
            case '!':
                if (!(callType_ & CTNoThumbnailCache)) {
                    callType_ |= CTNoThumbnailCache;
                    [results appendString:[self noThumbnailCacheOptionHelp]];
                }
                break;
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
		if(appURL)
		    CFRelease(appURL);
    }
    
    return availableCountries;
}

#pragma mark -
#pragma mark Handle Apple Contacts Searches

-(ABSearchElement *)generateOrSearchingElementForQueryPart:(NSString *)queryPart
{
    NSMutableArray *searchElements = [NSMutableArray array];
    
    // first name
    [searchElements addObject:[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:queryPart comparison:kABPrefixMatchCaseInsensitive]];
    // first name phonetic
    [searchElements addObject:[ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPart comparison:kABPrefixMatchCaseInsensitive]];
    // last name
    [searchElements addObject:[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:queryPart comparison:kABPrefixMatchCaseInsensitive]];
    // last name phonetic
    [searchElements addObject:[ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPart comparison:kABPrefixMatchCaseInsensitive]];
    // phone number
    [searchElements addObject:[ABPerson searchElementForProperty:kABPhoneProperty label:nil key:nil value:queryPart comparison:kABContainsSubStringCaseInsensitive]];
    
    return [ABSearchElement searchElementForConjunction:kABSearchOr children:searchElements];
}

-(ABSearchElement *)generateOrSearchingElementForQuery:(NSString *)query
{
    NSMutableArray *searchElements = [NSMutableArray array];
    
    // organization
    [searchElements addObject:[ABPerson searchElementForProperty:kABOrganizationProperty label:nil key:nil value:query comparison:kABPrefixMatchCaseInsensitive]];
    // first name
    // * some Chinese users often put contact's first name and last name together in either first or last name field
    [searchElements addObject:[ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:query comparison:kABPrefixMatchCaseInsensitive]];
    // last name
    // * some Chinese users often put contact's first name and last name together in either first or last name field
    [searchElements addObject:[ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:query comparison:kABPrefixMatchCaseInsensitive]];
    // nickname
    [searchElements addObject:[ABPerson searchElementForProperty:kABNicknameProperty label:nil key:nil value:query comparison:kABPrefixMatchCaseInsensitive]];
    // phone number
    [searchElements addObject:[ABPerson searchElementForProperty:kABPhoneProperty label:nil key:nil value:query comparison:kABContainsSubStringCaseInsensitive]];
    // skype username
    if (callType_ & CTSkype) {
        ABSearchElement *skypeUsername = [ABPerson searchElementForProperty:kABInstantMessageProperty label:nil key:kABInstantMessageUsernameKey value:query comparison:kABPrefixMatchCaseInsensitive];
        ABSearchElement *skypeService = [ABPerson searchElementForProperty:kABInstantMessageProperty label:nil key:kABInstantMessageServiceKey value:kABInstantMessageServiceSkype comparison:kABEqual];
        [searchElements addObject:[ABSearchElement searchElementForConjunction:kABSearchAnd children:@[skypeUsername, skypeService]]];
    }
    // email
    if (callType_ & CTFaceTime)
        [searchElements addObject:[ABPerson searchElementForProperty:kABEmailProperty label:nil key:nil value:query comparison:kABPrefixMatchCaseInsensitive]];
    // sip url
    if (callType_ & CTSIP)
        [searchElements addObject:[ABPerson searchElementForProperty:kABURLsProperty label:@"sip" key:nil value:query comparison:kABContainsSubStringCaseInsensitive]];
        
    return [ABSearchElement searchElementForConjunction:kABSearchOr children:searchElements];
}

#pragma mark -
#pragma mark Handle Thumbnails

+(NSString *)runCommand:(NSString *)commandToRun
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
                              
- (void)checkAndUpdateDefaultThumbnailIfNeededAtPath:(NSString *)path withColor:(NSColor *)color hasShadow:(BOOL)hasShadow
{
    if (![[self fileManager] fileExistsAtPath:path])
        [[[self newThumbnailFrom:[self defaultContactThumbnail] withColor:color hasShadow:hasShadow] TIFFRepresentation] writeToFile:path atomically:NO];
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
            [[[self newThumbnailFrom:thumbnail withColor:color hasShadow:hasShadow] TIFFRepresentation] writeToFile:path atomically:NO];
        else
            return NO;
    }
    
    return YES;
}

- (NSFileManager *)fileManager
{
    static NSFileManager *FM = nil;
    
    if (!FM) {
        FM = [[NSFileManager alloc] init];
    }
    
    return FM;
}

- (NSImage *)thumbnailForRecord:(ABRecord *)record
{
    static NSImage *thumbnail = nil;
    static ABRecord *prevRecord = nil;
    
    if (record != prevRecord) {
        thumbnail = [[NSImage alloc] initWithData:[(ABPerson *)record imageData]];
        if (thumbnail)
            thumbnail = [self makeThumbnailUsing:thumbnail];
        prevRecord = record;
    }
    
    return thumbnail;
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

- (NSString *)thumbnailCachePath
{
    static NSString *path = nil;
    if (!path) {
        path = [[self dataPath] stringByAppendingPathComponent:@"/thumbnails"];
    }
    return path;
}

- (BOOL)executionLockPresents
{
    return [[self fileManager] fileExistsAtPath:[self executionLockPath]];
}

- (void)releaseExecutionLock
{
    [[self fileManager] removeItemAtPath:[self executionLockPath] error:nil];
}

- (void)acquireExecutionLock
{
    NSString* str = @"I belong to Uni Call (http://guiguan.github.io/Uni-Call/), and I serve as an execution lock for some of Uni Call's functionalities. I should be deleted automatically by Uni Call at some point. Please delete me if I am stuck here. Thanks!";
    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [[self fileManager] createFileAtPath:[self executionLockPath] contents:data attributes:nil];
}

- (NSString *)executionLockPath
{
    static NSString *path = nil;
    if (!path) {
        path = [NSHomeDirectory() stringByAppendingString:@"/uniCallExecutionLock"];
    }
    return path;
}

- (NSImage *)defaultContactThumbnail
{
    static NSImage *image = nil;
    if (!image) {
        image = [[NSImage alloc] initWithContentsOfFile:[[self workflowPath] stringByAppendingString:@"/defaultContactThumbnail.png"]];
    }
    return image;
}

- (void)pushNotificationWithTitle:(NSString *)title andMessage:(NSString *)message andDetail:(NSString *)detail
{
    static NSString *qNotifierHelperPath = nil;
    if (!qNotifierHelperPath) {
        qNotifierHelperPath = [[UniCall workingPath] stringByAppendingString:@"/q_notifier.helper"];
    }
    [UniCall runCommand:[NSString stringWithFormat:@"\"%@\" com.runningwithcrayons.Alfred-2 \"%@\" \"%@\" \"%@\"", qNotifierHelperPath, title, message, detail]];
}

- (NSString *)skypeScptPath
{
    static NSString *path = nil;
    if (!path) {
        path = [[UniCall workingPath] stringByAppendingString:@"/skypecall.scpt"];
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
        path = [[NSBundle mainBundle] bundlePath];
    }
    return path;
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

- (NSString*) xmlSimpleEscape:(NSString*)unescapedStr
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
        char c = [unescapedStr characterAtIndex:i];
        NSString *replaceWithStr = nil;
        
        if (c == '\"')
        {
            replaceWithStr = @"&quot;";
        }
        else if (c == '\'')
        {
            replaceWithStr = @"&#x27;";
        }
        else if (c == '<')
        {
            replaceWithStr = @"&lt;";
        }
        else if (c == '>')
        {
            replaceWithStr = @"&gt;";
        }
        else if (c == '&')
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
