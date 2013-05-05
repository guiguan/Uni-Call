//
//  UniCall.m
//  Uni Call
//
//  Created by Guan Gui on 5/05/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <AppKit/AppKit.h>

#import "UniCall.h"

#define IDENTIFIER @"net.guiguan.Uni-Call"
#define THUMBNAIL_CACHE_RELATIVE_PATH IDENTIFIER "/thumbnails"
#define THUMBNAIL_CACHE_LIFESPAN 604800 // 1 week time

typedef enum CallType_
{
    CTNoThumbnailCache              = 1 << 0,
    CTBuildFullThumbnailCache       = 1 << 1,
    CTDestroyThumbnailCache         = 1 << 2,
    CTSkype                         = 1 << 3,
    CTFaceTime                      = 1 << 4,
    CTPhoneAmego                    = 1 << 5
} CallType;

@implementation NSImage(saveAsJpegWithName)

- (void) saveAsJpegWithName:(NSString*) fileName
{
    // Cache the reduced image
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    [imageData writeToFile:fileName atomically:NO];
}

@end

@implementation UniCall

static NSSize sThumbnailSize;
CallType callType_;
NSMutableArray *callTypes_;

+ (void)initialize
{
    sThumbnailSize = NSMakeSize(32, 32);
}

- (NSString *)outputHelpOnOptions
{
    return @"<?xml version=\"1.0\"?><items><item uid=\"helpOnOptions\" arg=\"\" valid=\"no\"><title>Uni Call Options</title><subtitle>You can use any combination of the -asfp! options</subtitle><icon>icon.png</icon></item><item uid=\"helpOnOptions\" arg=\"\" autocomplete=\"-a\" valid=\"no\"><title>Uni Call Option -a (default)</title><subtitle>Lay out all possible call options for your contact</subtitle><icon>icon.png</icon></item><item uid=\"helpOnOptions\" arg=\"\" autocomplete=\"-s\" valid=\"no\"><title>Uni Call Option -s</title><subtitle>Make a Skype call to your contact</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item><item uid=\"helpOnOptions\" arg=\"\" autocomplete=\"-f\" valid=\"no\"><title>Uni Call Option -f</title><subtitle>Make a FaceTime call to your contact</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item><item uid=\"helpOnOptions\" arg=\"\" autocomplete=\"-p\" valid=\"no\"><title>Uni Call Option -p</title><subtitle>Make a bluetooth phone call to your contact via Phone Amego</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item><item uid=\"helpOnOptions\" arg=\"\" autocomplete=\"-!\" valid=\"no\"><title>Uni Call Option -!</title><subtitle>Prohibit contact thumbnails caching</subtitle><icon>shouldNotCacheThumbnail.png</icon></item><item uid=\"helpOnOptions\" arg=\"\" autocomplete=\"-#\" valid=\"no\"><title>Uni Call Option -#</title><subtitle>Build full contact thumbnail cache</subtitle><icon>buildFullThumbnailCache.png</icon></item><item uid=\"helpOnOptions\" arg=\"\" autocomplete=\"-$\" valid=\"no\"><title>Uni Call Option -$</title><subtitle>Destroy contact thumbnail cache</subtitle><icon>destroyThumbnailCache.png</icon></item></items>";
}

// YES: should exit immediately
-(BOOL)processOptions:(NSString *)options withQuery:(NSString *)query andQueryMatches:(NSArray *)queryMatches andResults:(NSMutableString *)results
{
    for (int i = 1; i < [options length]; i++) {
        switch ([options characterAtIndex:i]) {
            case 'a':
                [self processOptions:@"-sfp" withQuery:query andQueryMatches:queryMatches andResults:results];
                break;
            case 's':
                if (!(callType_ & CTSkype)) {
                    callType_ |= CTSkype;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTSkype]];
                    [results appendFormat:@"<item uid=\"%@\" arg=\"\" autocomplete=\"-s\" valid=\"no\"><title>Skype Call</title><subtitle>Make a Skype call to your contact</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>", options];
                }
                break;
            case 'f':
                if (!(callType_ & CTFaceTime)) {
                    callType_ |= CTFaceTime;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTFaceTime]];
                    [results appendFormat:@"<item uid=\"%@\" arg=\"\" autocomplete=\"-f\" valid=\"no\"><title>FaceTime Call</title><subtitle>Make a FaceTime call to your contact</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>", options];
                }
                break;
            case 'p':
                if (!(callType_ & CTPhoneAmego)) {
                    callType_ |= CTPhoneAmego;
                    [callTypes_ addObject:[NSNumber numberWithInt:CTPhoneAmego]];
                    [results appendFormat:@"<item uid=\"%@\" arg=\"\" autocomplete=\"-p\" valid=\"no\"><title>Phone Amego Call</title><subtitle>Make a bluetooth phone call to your contact via Phone Amego</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>", options];
                }
                break;
            case '!':
                if (!(callType_ & CTNoThumbnailCache)) {
                    callType_ |= CTNoThumbnailCache;
                    [results appendFormat:@"<item uid=\"%@\" arg=\"\" autocomplete=\"%@\" valid=\"no\"><title>Uni Call Option -!</title><subtitle>Prohibit contact thumbnails caching</subtitle><icon>shouldNotCacheThumbnail.png</icon></item>", options, options];
                }
                break;
            case '#':
                callType_ |= CTBuildFullThumbnailCache;
                if ([queryMatches count] == 2 && [[query substringWithRange:((NSTextCheckingResult *)queryMatches[1]).range] isEqualToString:@"yes"]) {
                    // carry out CTBuildFullThumbnailCache operation
//                    [self pushNotificationWithTitle:@"Started" andMessage:@"building full thumbnail cache" andDetail:@"Please sit tight. You are using Uni Call option -#."];
                    return NO;
                } else {
                    [results setString:@"<?xml version=\"1.0\"?><items><item uid=\"%@\" arg=\"\" autocomplete=\"-#\" valid=\"no\"><title>Uni Call Option -#</title><subtitle>Use \"call -# yes\" to start building full contact thumbnail cache</subtitle><icon>buildFullThumbnailCache.png</icon></item>"];
                    return YES;
                }
            case '$':
                callType_ |= CTDestroyThumbnailCache;
                if ([queryMatches count] == 2 && [[query substringWithRange:((NSTextCheckingResult *)queryMatches[1]).range] isEqualToString:@"yes"]) {
                    // carry out CTDestroyThumbnailCache operation
//                    [self pushNotificationWithTitle:@"Started" andMessage:@"destroying thumbnail cache" andDetail:@"Please sit tight. You are using Uni Call option -$."];
                    return NO;
                } else {
                    [results setString:@"<?xml version=\"1.0\"?><items><item uid=\"%@\" arg=\"\" autocomplete=\"-$\" valid=\"no\"><title>Uni Call Option -$</title><subtitle>Use \"call -$ yes\" to start destroying contact thumbnail cache</subtitle><icon>destroyThumbnailCache.png</icon></item>"];
                    return YES;
                }
        }
    }
    
    return NO;
}

-(NSString *)process:(NSString *)query
{
//    if ([self executionLockPresents])
//        return [NSString stringWithFormat:@"<?xml version=\"1.0\"?><items><item uid=\"\" arg=\"\" autocomplete=\"\" valid=\"no\"><title>Please wait for another Uni Call process to terminate</title><subtitle>Error: uniCallExecutionLock detected at %@</subtitle><icon>icon.png</icon></item>", NSHomeDirectory()];
    
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"[^ ]+" options:0 error:nil];
    NSArray *queryMatches = [re matchesInString:query options:0 range:NSMakeRange(0, [query length])];
    
    if ([queryMatches count] == 0)
        return [self outputHelpOnOptions];
    
    NSMutableString *results = [NSMutableString stringWithString:@"<?xml version=\"1.0\"?><items>"];
    NSString *options = [query substringWithRange:((NSTextCheckingResult *)queryMatches[0]).range];
    callTypes_ = [NSMutableArray array];
    int i = 0;
    
    if ([options hasPrefix:@"-"]) {
        if ([self processOptions:options withQuery:query andQueryMatches:queryMatches andResults:results]) {
            // option has asked to exit immediately
            [results appendFormat:@"</items>"];
            return results;
        }
        
        if (callType_ & CTBuildFullThumbnailCache) {
//            [self acquireExecutionLock];
            callType_ = CTBuildFullThumbnailCache;
            [self processOptions:@"-a" withQuery:query andQueryMatches:queryMatches andResults:results];
        } else if (callType_ & CTDestroyThumbnailCache) {
            [[NSFileManager defaultManager] removeItemAtPath:[self cachePath] error:nil];
            return @"<?xml version=\"1.0\"?><items><item uid=\"\" arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option -$</title><subtitle>Done. Contact thumbnail cache is now destroyed</subtitle><icon>destroyThumbnailCache.png</icon></item></items>";
        } else if (callType_ <= (CTNoThumbnailCache | CTBuildFullThumbnailCache | CTDestroyThumbnailCache)) {
            // no valid options provided
            return [self outputHelpOnOptions];
        } else {
            i = 1;
            
            if ([queryMatches count] == 1) {
                // only options, no query provided
                [results appendFormat:@"</items>"];
                return results;
            }
        }
    } else {
        [self processOptions:@"-a" withQuery:query andQueryMatches:queryMatches andResults:results];
    }
    
    ABAddressBook *AB = [ABAddressBook sharedAddressBook];
    NSArray *peopleFound;
    int population;
    if (callType_ & CTBuildFullThumbnailCache) {
        peopleFound = [AB people];
        population = (int)[peopleFound count];
    } else {
        NSMutableArray *searchTerms = [[NSMutableArray alloc] initWithCapacity:[queryMatches count]];
        NSMutableString *newQuery = [NSMutableString string];
        
        for (; i < [queryMatches count]; i++) {
            NSString *queryPart = [query substringWithRange:((NSTextCheckingResult *)queryMatches[i]).range];
            [searchTerms addObject:[self generateOrSearchingElementForQueryPart: queryPart]];
            [newQuery appendFormat:@"%@ ", queryPart];
        }
        
        query = [newQuery substringToIndex:[newQuery length] - 1];
        
        ABSearchElement *searchEl = [ABSearchElement searchElementForConjunction:kABSearchOr children:@[[self generateOrSearchingElementForQuery:query], [ABSearchElement searchElementForConjunction:kABSearchAnd children:searchTerms]]];
        
        peopleFound = [AB recordsMatchingSearchElement:searchEl];
        population = MIN((int)[peopleFound count], MIN((int)[query length]*2, 10));
        [results setString:@"<?xml version=\"1.0\"?><items>"];
        
        if (!(callType_ & CTNoThumbnailCache) && ![[NSFileManager defaultManager] fileExistsAtPath:[self thumbnailCachePath]]) {
            //create the folder if it doesn't exist
            [[NSFileManager defaultManager] createDirectoryAtPath:[self thumbnailCachePath] withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }

    for (int j = 0; j < population; j++) {
        ABRecord *r = peopleFound[j];
        NSMutableString *outDisplayName = [NSMutableString string];
        
        if (!(callType_ & CTBuildFullThumbnailCache)) {
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
                        skypeThumbnailPath = [[self workingPath] stringByAppendingString:@"/defaultContactThumbnail:Skype.tiff"];
                        skypeOnlineThumbnailPath = [[self workingPath] stringByAppendingString:@"/defaultContactThumbnail:Skype:Online.tiff"];
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:skypeThumbnailPath withColor:color hasShadow:NO];
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:skypeOnlineThumbnailPath withColor:color hasShadow:YES];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        NSMutableString *bufferedResults = [NSMutableString string];
                        
                        // output Skype usernames
                        ABMultiValue *ims = [r valueForProperty:kABInstantMessageProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSDictionary *entry = [ims valueAtIndex:i];
                            if ([entry[kABInstantMessageServiceKey] isEqualToString: kABInstantMessageServiceSkype]) {
                                NSString *username = entry[kABInstantMessageUsernameKey];
                                BOOL isOnline = [[self runCommand:[NSString stringWithFormat:@"/usr/bin/osascript %@ [STATUS]%@", [self skypeScptPath], username]] hasPrefix:@"1"];
                                if (isOnline)
                                    [results appendFormat:@"<item uid=\"%@:Skype:Online\" arg=\"[CTSkype]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to Skype username: %@ (online)</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], username, username, outDisplayName, username, skypeOnlineThumbnailPath];
                                else
                                    [bufferedResults appendFormat:@"<item uid=\"%@:Skype\" arg=\"[CTSkype]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to Skype username: %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], username, username, outDisplayName, username, skypeThumbnailPath];
                            }
                        }
                        
                        // output phone numbers
                        ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [ims valueAtIndex:i];
                            [results appendFormat:@"<item uid=\"%@:Skype\" arg=\"[CTSkype]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to phone number: %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, phoneNum, skypeThumbnailPath];
                        }
                        
                        [results appendString:bufferedResults];
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
                        faceTimeThumbnailPath = [[self workingPath] stringByAppendingString:@"/defaultContactThumbnail:FaceTime.tiff"];
                        faceTimeNominatedThumbnailPath = [[self workingPath] stringByAppendingString:@"/defaultContactThumbnail:FaceTime:Nominated.tiff"];
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:faceTimeThumbnailPath withColor:color hasShadow:NO];
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:faceTimeNominatedThumbnailPath withColor:color hasShadow:YES];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        // output phone numbers
                        NSMutableString *bufferedPhoneResults = [NSMutableString string];
                        BOOL hasNominatedFaceTimePhone = NO;
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [ims valueAtIndex:i];
                            
                            if ([[ims labelAtIndex:i] caseInsensitiveCompare:@"FaceTime"] == NSOrderedSame || [[ims labelAtIndex:i] caseInsensitiveCompare:@"iPhone"] == NSOrderedSame || [[ims labelAtIndex:i] caseInsensitiveCompare:@"iDevice"] == NSOrderedSame) {
                                hasNominatedFaceTimePhone = YES;
                                
                                [results appendFormat:@"<item uid=\"%@:FaceTime:Nominated\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime call to phone number: %@ (nominated)</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, phoneNum, faceTimeNominatedThumbnailPath];
                            } else
                                [bufferedPhoneResults appendFormat:@"<item uid=\"%@:FaceTime\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime call to phone number: %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, phoneNum, faceTimeThumbnailPath];
                        }
                        
                        // output emails
                        NSMutableString *bufferedEmailResults = [NSMutableString string];
                        BOOL hasNominatedFaceTimeEmail = NO;
                        ims = [r valueForProperty:kABEmailProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *email = [ims valueAtIndex:i];
                            
                            if ([[ims labelAtIndex:i] caseInsensitiveCompare:@"FaceTime"] == NSOrderedSame || [[ims labelAtIndex:i] caseInsensitiveCompare:@"iPhone"] == NSOrderedSame || [[ims labelAtIndex:i] caseInsensitiveCompare:@"iDevice"] == NSOrderedSame) {
                                hasNominatedFaceTimeEmail = YES;
                                
                                [results appendFormat:@"<item uid=\"%@:FaceTime:Nominated\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime call to email address: %@ (nominated)</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], email, email, outDisplayName, email, faceTimeNominatedThumbnailPath];
                            } else
                                [bufferedEmailResults appendFormat:@"<item uid=\"%@:FaceTime\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime call to email address: %@</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], email, email, outDisplayName, email, faceTimeThumbnailPath];
                        }
                        
                        if (!hasNominatedFaceTimePhone && !hasNominatedFaceTimeEmail) {
                            [results appendString:bufferedPhoneResults];
                            [results appendString:bufferedEmailResults];
                        }
                    }
                    
                    break;
                }
                case CTPhoneAmego: {
                    BOOL isThumbNailOkay = NO;
                    NSColor *color = [NSColor colorWithCalibratedRed:1.00000f green:0.74118f blue:0.30196f alpha:1.0f];
                    NSString *phoneAmegoThumbnailPath = [[self thumbnailCachePath] stringByAppendingFormat:@"/%@:PhoneAmego.tiff", [r uniqueId]];
                    isThumbNailOkay = [self checkAndUpdateThumbnailIfNeededAtPath:phoneAmegoThumbnailPath forRecord:r withColor:color hasShadow:NO];
                    
                    if (!isThumbNailOkay) {
                        phoneAmegoThumbnailPath = [[self workingPath] stringByAppendingString:@"/defaultContactThumbnail:PhoneAmego.tiff"];
                        [self checkAndUpdateDefaultThumbnailIfNeededAtPath:phoneAmegoThumbnailPath withColor:color hasShadow:NO];
                    }
                    
                    if (!(callType_ & CTBuildFullThumbnailCache)) {
                        // output phone numbers
                        ABMultiValue *ims = [r valueForProperty:kABPhoneProperty];
                        for (int i = 0; i < [ims count]; i++) {
                            NSString *phoneNum = [ims valueAtIndex:i];
                            
                            [results appendFormat:@"<item uid=\"%@:PhoneAmego\" arg=\"[CTPhoneAmego]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Bluetooth phone call to phone number: %@ via Phone Amego</subtitle><icon>%@</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, phoneNum, phoneAmegoThumbnailPath];
                        }
                    }
                    
                    break;
                }
            }
        }
    }
    
    if (callType_ & CTBuildFullThumbnailCache) {
//        [self releaseExecutionLock];
//        [self pushNotificationWithTitle:@"Finished" andMessage:@"building full thumbnail cache" andDetail:@"You have successfully used Uni Call option -#."];
        return @"<?xml version=\"1.0\"?><items><item uid=\"\" arg=\"\" autocomplete=\"-\" valid=\"no\"><title>Uni Call Option -#</title><subtitle>Done. Contact thumbnail cache is now fully built</subtitle><icon>buildFullThumbnailCache.png</icon></item></items>";
    } else {
        if ([peopleFound count] == 0) {
            for (int i = 0; i < [callTypes_ count]; i++) {
                switch ([callTypes_[i] integerValue]) {
                    case CTSkype:
                        [results appendFormat:@"<item uid=\"%@\" arg=\"[CTSkype]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to: %@ (unidentified in Apple Contacts)</subtitle><icon>7016D8DA-6748-4E96-BDA2-FBF05F0BAD5B.png</icon></item>", query, query, query, query, query];
                        break;
                    case CTFaceTime:
                        [results appendFormat:@"<item uid=\"%@\" arg=\"[CTFaceTime]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>FaceTime call to: %@ (unidentified in Apple Contacts)</subtitle><icon>674DE779-72F5-4632-932B-FD1404CBE0FA.png</icon></item>", query, query, query, query, query];
                        break;
                    case CTPhoneAmego:
                        [results appendFormat:@"<item uid=\"%@\" arg=\"[CTPhoneAmego]%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Bluetooth phone call to: %@ via Phone Amego (unidentified in Apple Contacts)</subtitle><icon>54C2F3DC-1B4B-476D-9E47-214A16D51F39.png</icon></item>", query, query, query, query, query];
                        break;
                }
            }
        }
        
        [results appendString:@"</items>"];
        return results;
    }
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
        
    return [ABSearchElement searchElementForConjunction:kABSearchOr children:searchElements];
}

#pragma mark -
#pragma mark Handle Thumbnails

-(NSString *)runCommand:(NSString *)commandToRun
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
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        [[[self newThumbnailFrom:[self defaultContactThumbnail] withColor:color hasShadow:hasShadow] TIFFRepresentation] writeToFile:path atomically:NO];
}

- (BOOL)checkAndUpdateThumbnailIfNeededAtPath:(NSString *)path forRecord:(ABRecord *)record withColor:(NSColor *)color hasShadow:(BOOL)hasShadow
{
    if (callType_ & CTNoThumbnailCache)
        return NO;
    
    static NSCalendar *gregorian = nil;
    static NSFileManager *FM = nil;
    if (!gregorian) {
        gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        FM = [NSFileManager defaultManager];
    }
    
    NSTimeInterval timeNow = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeSinceLastUpdated = [[[FM attributesOfItemAtPath:path error:nil] fileModificationDate] timeIntervalSince1970];

    // output the person's thumbnail if it hasn't been cached
    if (![FM fileExistsAtPath:path] ||  (timeNow - timeSinceLastUpdated) > THUMBNAIL_CACHE_LIFESPAN) {
        NSImage *thumbnail = [self thumbnailForRecord:record];
        if (thumbnail)
            [[[self newThumbnailFrom:thumbnail withColor:color hasShadow:hasShadow] TIFFRepresentation] writeToFile:path atomically:NO];
        else
            return NO;
    }
    
    return YES;
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

- (NSString *)cachePath
{
    static NSString *path = nil;
    if (!path) {
        //cache folder
        path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        
        path = [path stringByAppendingPathComponent:IDENTIFIER];
    }
    return path;
}

- (NSString *)thumbnailCachePath
{
    static NSString *path = nil;
    if (!path) {
        //cache folder
        path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        
        path = [path stringByAppendingPathComponent:THUMBNAIL_CACHE_RELATIVE_PATH];
    }
    return path;
}

- (BOOL)executionLockPresents
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self executionLockPath]];
}

- (void)releaseExecutionLock
{
    [[NSFileManager defaultManager] removeItemAtPath:[self executionLockPath] error:nil];
}

- (void)acquireExecutionLock
{
    NSString* str = @"I belong to Uni Call (http://guiguan.github.io/Uni-Call/), and I serve as an execution lock for some of Uni Call's functionalities. I should be deleted automatically by Uni Call at some point. Please delete me if I am stuck here. Thanks!";
    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [[NSFileManager defaultManager] createFileAtPath:[self executionLockPath] contents:data attributes:nil];
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
        image = [[NSImage alloc] initWithContentsOfFile:[[self workingPath] stringByAppendingString:@"/defaultContactThumbnail.png"]];
    }
    return image;
}

- (NSString *)skypeScptPath
{
    static NSString *path = nil;
    if (!path) {
        path = [[self workingPath] stringByAppendingString:@"/skypecall.scpt"];
    }
    return path;
}

- (void)pushNotificationWithTitle:(NSString *)title andMessage:(NSString *)message andDetail:(NSString *)detail
{
    static NSString *qNotifierHelperPath = nil;
    if (!qNotifierHelperPath) {
        qNotifierHelperPath = [[self workingPath] stringByAppendingString:@"/bin/q_notifier.helper"];
    }
    [self runCommand:[NSString stringWithFormat:@"%@ com.runningwithcrayons.Alfred-2 \"%@\" \"%@\" \"%@\"", qNotifierHelperPath, title, message, detail]];
}

- (NSString *)workingPath
{
    static NSString *path = nil;
    if (!path) {
        path = [[NSFileManager defaultManager] currentDirectoryPath];
    }
    return path;
}

@end
