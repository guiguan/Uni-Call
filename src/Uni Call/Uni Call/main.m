//
//  main.m
//  Skype Call
//
//  Created by Guan Gui on 25/04/13.
//  Copyright (c) 2013 Guan Gui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

NSString *runCommand(NSString *commandToRun)
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

ABSearchElement *generateOrSearchingElementForQueryPart(NSString *queryPart)
{
    ABSearchElement *firstName = [ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:queryPart comparison:kABPrefixMatchCaseInsensitive];
    ABSearchElement *firstNamePhonetic = [ABPerson searchElementForProperty:kABFirstNamePhoneticProperty label:nil key:nil value:queryPart comparison:kABPrefixMatchCaseInsensitive];
    ABSearchElement *lastName = [ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:queryPart comparison:kABPrefixMatchCaseInsensitive];
    ABSearchElement *lastNamePhonetic = [ABPerson searchElementForProperty:kABLastNamePhoneticProperty label:nil key:nil value:queryPart comparison:kABPrefixMatchCaseInsensitive];
    ABSearchElement *phoneNumber = [ABPerson searchElementForProperty:kABPhoneProperty label:nil key:nil value:queryPart comparison:kABContainsSubStringCaseInsensitive];
    
    return [ABSearchElement searchElementForConjunction:kABSearchOr children:@[firstName, firstNamePhonetic, lastName, lastNamePhonetic, phoneNumber]];
}

ABSearchElement *generateOrSearchingElementForQuery(NSString *query)
{
    ABSearchElement *organization = [ABPerson searchElementForProperty:kABOrganizationProperty label:nil key:nil value:query comparison:kABPrefixMatchCaseInsensitive];
    ABSearchElement *firstName = [ABPerson searchElementForProperty:kABFirstNameProperty label:nil key:nil value:query comparison:kABPrefixMatchCaseInsensitive];
    ABSearchElement *lastName = [ABPerson searchElementForProperty:kABLastNameProperty label:nil key:nil value:query comparison:kABPrefixMatchCaseInsensitive];
    ABSearchElement *nickname = [ABPerson searchElementForProperty:kABNicknameProperty label:nil key:nil value:query comparison:kABPrefixMatchCaseInsensitive];
    ABSearchElement *phoneNumber = [ABPerson searchElementForProperty:kABPhoneProperty label:nil key:nil value:query comparison:kABContainsSubStringCaseInsensitive];
    ABSearchElement *skypeUsername = [ABPerson searchElementForProperty:kABInstantMessageProperty label:nil key:kABInstantMessageUsernameKey value:query comparison:kABPrefixMatchCaseInsensitive];
    ABSearchElement *skypeService = [ABPerson searchElementForProperty:kABInstantMessageProperty label:nil key:kABInstantMessageServiceKey value:kABInstantMessageServiceSkype comparison:kABEqual];
    ABSearchElement *skype = [ABSearchElement searchElementForConjunction:kABSearchAnd children:@[skypeUsername, skypeService]];
    
    return [ABSearchElement searchElementForConjunction:kABSearchOr children:@[firstName, lastName, nickname, organization, skype, phoneNumber]];
}

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        NSString *skypeScptPath = [[[[NSFileManager alloc] init] currentDirectoryPath] stringByAppendingString:@"/skypecall.scpt"];
        NSString *query = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"[^ ]+" options:0 error:nil];
        NSArray *queryMatches = [re matchesInString:query options:0 range:NSMakeRange(0, [query length])];
        
        if ([queryMatches count] == 0)
            return 0;
        
        ABAddressBook *AB = [ABAddressBook sharedAddressBook];
        NSMutableArray *searchTerms = [[NSMutableArray alloc] initWithCapacity:[queryMatches count]];
        
        for (int i = 0; i < [queryMatches count]; i++) {
            NSString *queryPart = [query substringWithRange:((NSTextCheckingResult *)queryMatches[i]).range];
            [searchTerms addObject:generateOrSearchingElementForQueryPart(queryPart)];
        }
        
        ABSearchElement *searchEl = [ABSearchElement searchElementForConjunction:kABSearchOr children:@[generateOrSearchingElementForQuery(query), [ABSearchElement searchElementForConjunction:kABSearchAnd children:searchTerms]]];

        NSArray *peopleFound = [AB recordsMatchingSearchElement:searchEl];
        NSMutableString *results = [NSMutableString stringWithString:@"<?xml version=\"1.0\"?><items>"];
        
        for (int j = 0; j < MIN([peopleFound count], 20); j++) {
            ABRecord *r = peopleFound[j];
            
            NSString *lastName = [r valueForProperty:kABLastNameProperty];
            NSString *firstName = [r valueForProperty:kABFirstNameProperty];
            NSString *middleName = [r valueForProperty:kABMiddleNameProperty];
            int nameOrdering = ([[r valueForProperty:kABPersonFlags] intValue] & kABNameOrderingMask);
            if (nameOrdering == kABDefaultNameOrdering)
                nameOrdering = (int)[[ABAddressBook sharedAddressBook] defaultNameOrdering];
            NSMutableString *outDisplayName = [NSMutableString string];
            
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
            
            NSMutableString *bufferedResults = [NSMutableString string];
            
            // output Skype usernames
            ABMultiValue *ims = [r valueForProperty:kABInstantMessageProperty];
            for (int i = 0; i < [ims count]; i++) {
                NSDictionary *entry = [ims valueAtIndex:i];
                if ([entry[kABInstantMessageServiceKey] isEqualToString: kABInstantMessageServiceSkype]) {
                    NSString *username = entry[kABInstantMessageUsernameKey];
                    BOOL isOnline = [runCommand([NSString stringWithFormat:@"/usr/bin/osascript %@ [STATUS]%@", skypeScptPath, username]) hasPrefix:@"1"];
                    if (isOnline)
                        [results appendFormat:@"<item uid=\"%@\" arg=\"%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to Skype username: %@ (online)</subtitle><icon>contactOnline.icns</icon></item>", [ims identifierAtIndex:i], username, username, outDisplayName, username];
                    else
                        [bufferedResults appendFormat:@"<item uid=\"%@\" arg=\"%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to Skype username: %@</subtitle><icon>contact.icns</icon></item>", [ims identifierAtIndex:i], username, username, outDisplayName, username];
                }
            }
            
            // output phone numbers
            ims = [r valueForProperty:kABPhoneProperty];
            for (int i = 0; i < [ims count]; i++) {
                NSString *phoneNum = [ims valueAtIndex:i];
                [results appendFormat:@"<item uid=\"%@\" arg=\"%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to phone number: %@</subtitle><icon>contact.icns</icon></item>", [ims identifierAtIndex:i], phoneNum, phoneNum, outDisplayName, phoneNum];
            }
            
            [results appendString:bufferedResults];
        }
        
        if ([peopleFound count] == 0) {
            // new target
            [results appendFormat:@"<item uid=\"%@\" arg=\"%@\" autocomplete=\"%@\"><title>%@</title><subtitle>Skype call to %@, which is not identified in your Apple Contacts</subtitle><icon>skypecall.icns</icon></item>", query, query, query, query, query];
        }
        
        [results appendString:@"</items>"];
        [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:[results dataUsingEncoding:NSUTF8StringEncoding]];
    }
    return 0;
}

