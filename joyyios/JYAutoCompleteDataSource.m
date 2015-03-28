//
//  JYAutoCompleteDataSource.m
//  joyyios
//
//  Created by Ping Yang on 3/27/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYAutoCompleteDataSource.h"

@interface JYAutoCompleteDataSource ()

@end

static JYAutoCompleteDataSource *sharedDataSource;

@implementation JYAutoCompleteDataSource

+ (JYAutoCompleteDataSource *)sharedDataSource
{
    static dispatch_once_t done;
    dispatch_once(&done, ^{ sharedDataSource = [[JYAutoCompleteDataSource alloc] init]; });
    return sharedDataSource;
}

#pragma mark - HTAutocompleteTextFieldDelegate

- (NSString *)textField:(JYAutocompleteTextField *)textField
    completionForPrefix:(NSString *)prefix
             ignoreCase:(BOOL)ignoreCase
{
    if (textField.autocompleteType == JYAutoCompleteTypeEmail)
    {
        static dispatch_once_t onceToken;
        static NSArray *autocompleteArray;
        dispatch_once(&onceToken, ^
                      {
                          autocompleteArray = @[  @"gmail.com",
                                                  @"yahoo.com",
                                                  @"outlook.com",
                                                  @"icloud.com",
                                                  @"hotmail.com",
                                                  @"facebook.com",
                                                  @"aol.com",
                                                  @"aim.com",
                                                  @"mail.com",
                                                  @"comcast.net",
                                                  @"msn.com",
                                                  @"live.com",
                                                  @"qq.com",
                                                  @"ymail.com",
                                                  @"inbox.com",
                                                  @"zoho.com",
                                                  @"att.net",
                                                  @"cox.net",
                                                  @"verizon.net",
                                                  @"rocketmail.com",
                                                  @"earthlink.net",
                                                  @"charter.net",
                                                  @"naver.com",
                                                  @"rogers.com",
                                                  @"juno.com",
                                                  @"walla.com",
                                                  @"telus.net",
                                                  @"stanford.edu",
                                                  @"harvard.edu",
                                                  @"asu.edu",
                                                  @"berkeley.edu",
                                                  @"hanmail.net",
                                                  @"netzero.net",
                                                  @"ail.com",
                                                  @"netzero.com",
                                                  @"mchsi.com",
                                                  @"cableone.net",
                                                  @"cornell.edu",
                                                  @"ucla.edu",
                                                  @"us.army.mil",
                                                  @"excite.com",
                                                  @"ntlworld.com",
                                                  @"usc.edu",
                                                  @"nate.com"];
                      });

        // Check that text field contains an @
        NSRange atSignRange = [prefix rangeOfString:@"@"];
        if (atSignRange.location == NSNotFound)
        {
            return @"";
        }

        // Stop autocomplete if user types dot after domain
        NSString *domainAndTLD = [prefix substringFromIndex:atSignRange.location];
        NSRange rangeOfDot = [domainAndTLD rangeOfString:@"."];
        if (rangeOfDot.location != NSNotFound)
        {
            return @"";
        }

        // Check that there aren't two @-signs
        NSArray *textComponents = [prefix componentsSeparatedByString:@"@"];
        if ([textComponents count] > 2)
        {
            return @"";
        }

        if ([textComponents count] > 1)
        {
            // If no domain is entered, use the first domain in the list
            if ([(NSString *)textComponents[1] length] == 0)
            {
                return [autocompleteArray objectAtIndex:0];
            }

            NSString *textAfterAtSign = textComponents[1];

            NSString *stringToLookFor;
            if (ignoreCase)
            {
                stringToLookFor = [textAfterAtSign lowercaseString];
            }
            else
            {
                stringToLookFor = textAfterAtSign;
            }

            for (NSString *stringFromReference in autocompleteArray)
            {
                NSString *stringToCompare;
                if (ignoreCase)
                {
                    stringToCompare = [stringFromReference lowercaseString];
                }
                else
                {
                    stringToCompare = stringFromReference;
                }

                if ([stringToCompare hasPrefix:stringToLookFor])
                {
                    return [stringFromReference stringByReplacingCharactersInRange:[stringToCompare rangeOfString:stringToLookFor] withString:@""];
                }

            }
        }
    }
    else if (textField.autocompleteType == JYAutoCompleteTypeColor)
    {
        static dispatch_once_t colorOnceToken;
        static NSArray *colorAutocompleteArray;
        dispatch_once(&colorOnceToken, ^
                      {
                          colorAutocompleteArray = @[ @"Alfred",
                                                      @"Beth",
                                                      @"Carlos",
                                                      @"Daniel",
                                                      @"Ethan",
                                                      @"Fred"];
                      });

        NSString *stringToLookFor;
        NSArray *componentsString = [prefix componentsSeparatedByString:@","];
        NSString *prefixLastComponent = [componentsString.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (ignoreCase)
        {
            stringToLookFor = [prefixLastComponent lowercaseString];
        }
        else
        {
            stringToLookFor = prefixLastComponent;
        }

        for (NSString *stringFromReference in colorAutocompleteArray)
        {
            NSString *stringToCompare;
            if (ignoreCase)
            {
                stringToCompare = [stringFromReference lowercaseString];
            }
            else
            {
                stringToCompare = stringFromReference;
            }
            
            if ([stringToCompare hasPrefix:stringToLookFor])
            {
                return [stringFromReference stringByReplacingCharactersInRange:[stringToCompare rangeOfString:stringToLookFor] withString:@""];
            }
            
        }
    }
    
    return @"";
}

@end


