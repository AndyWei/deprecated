//
//  JYContactManager.m
//  joyyios
//
//  Created by Ping Yang on 1/14/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>

#import "JYContactManager.h"
#import "JYManagementDataStore.h"
#import "NSString+Joyy.h"

@import AddressBook;
@import Contacts;

@interface JYContactManager ()
@property (nonatomic) NBPhoneNumberUtil *phoneUtil;
@property (nonatomic) NSMutableSet *phoneNumberSet;
@property (nonatomic) NSMutableDictionary *contactDict;
@property (nonatomic) NSString *countryCode;
@end

@implementation JYContactManager

+ (JYContactManager *)sharedInstance
{
    static JYContactManager *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYContactManager new];
    });

    return _sharedInstance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.phoneUtil = [NBPhoneNumberUtil new];
        self.phoneNumberSet = [NSMutableSet new];
        self.contactDict = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_apiTokenReady) name:kNotificationAPITokenReady object:nil];
    }
    return self;
}

- (void)start
{
    NSLog(@"ContactManager started");

    if ([JYCredential current].tokenValidInSeconds <= 0)
    {
        return;
    }

    [self _apiTokenReady];
}

- (void)_apiTokenReady
{
    if (![JYManagementDataStore sharedInstance].needQueryContacts)
    {
        return;
    }

    [self _readPhoneNumbers];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_readPhoneNumbers
{
//    if (NSClassFromString(@"CNContact"))
//    {
//        [self _readPhoneNumbersFromContactStore]; // iOS9 and later
//    }
//    else
//    {
        [self _readPhoneNumbersFromAddressBook]; // iOS7 and iOS8
//    }
}

- (void)_readPhoneNumbersFromContactStore
{
    __weak typeof(self) weakSelf = self;
    CNContactStore *store = [[CNContactStore alloc] init];
    [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error) {
        if (granted == NO || error)
        {
            NSLog(@"requestAccessForEntityType error: %@", error);
            return ;
        }

        //keys with fetching properties
        NSArray *keys = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey];

        NSPredicate *predicate = [CNContact predicateForContactsInContainerWithIdentifier:store.defaultContainerIdentifier];
        NSError *err;
        NSArray *contactList = [store unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:&err];
        if (err)
        {
            NSLog(@"error fetching contacts %@", err);
            return;
        }

        for (CNContact *contact in contactList)
        {
            // copy data to my custom Contacts class.
            NSString *fullName = [self _fullNameWithFirstname:contact.givenName lastname:contact.familyName];

            for (CNLabeledValue *labeledValue in contact.phoneNumbers)
            {
                NSString *phoneNumber = [labeledValue.value stringValue];
                [weakSelf _handlePhoneNumber:phoneNumber contactName:fullName];
            }
        }
        NSLog(@"self.phoneNumberSet count = %lu", (unsigned long)[self.phoneNumberSet count]);
        [weakSelf _readRemoteUsersInContact];
    }];
}

- (void)_readPhoneNumbersFromAddressBook
{
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusDenied)
    {
        // user had previously denied/revoked permission the app to access the contacts, and all we can do is
        // telling the user that they have to go to settings to grant access to contacts
        [self _showAddressBookAccessAlert];
        return;
    }

    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);

    if (error)
    {
        NSLog(@"ABAddressBookCreateWithOptions error: %@", CFBridgingRelease(error));
        if (addressBook)
        {
            CFRelease(addressBook);
        }
        return;
    }

    if (status == kABAuthorizationStatusAuthorized)
    {
        [self _doReadPhoneNumbersFromAddressBook:addressBook];
        if (addressBook)
        {
            CFRelease(addressBook);
        }
    }
    else if (status == kABAuthorizationStatusNotDetermined)
    {
        // present the user the UI that requests permission to contacts ...
        __weak typeof(self) weakSelf = self;
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (error)
            {
                NSLog(@"ABAddressBookRequestAccessWithCompletion error: %@", CFBridgingRelease(error));
            }

            if (granted)
            {
                [weakSelf _doReadPhoneNumbersFromAddressBook:addressBook];
            }
            else
            {
                // the user didn't give permission, handle it gracefully by presenting an alert view
                [weakSelf _showAddressBookAccessAlert];
            }

            if (addressBook)
            {
                CFRelease(addressBook);
            }
        });
    }
}

- (void)_doReadPhoneNumbersFromAddressBook:(ABAddressBookRef)addressBook
{
    NSInteger numberOfPeople = ABAddressBookGetPersonCount(addressBook);
    NSArray *allPeople = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));

    for (NSInteger i = 0; i < numberOfPeople; i++)
    {
        ABRecordRef person = (__bridge ABRecordRef)allPeople[i];

        NSString *firstname = CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        NSString *lastname  = CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
        NSString *fullName = [self _fullNameWithFirstname:firstname lastname:lastname];

        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);

        CFIndex numberOfPhoneNumbers = ABMultiValueGetCount(phoneNumbers);
        for (CFIndex i = 0; i < numberOfPhoneNumbers; i++)
        {
            NSString *phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneNumbers, i));
            [self _handlePhoneNumber:phoneNumber contactName:fullName];
        }

        CFRelease(phoneNumbers);
    }
    [self _readRemoteUsersInContact];
}

- (void)_showAddressBookAccessAlert
{
    NSString *message = NSLocalizedString(@"Winkrock requires access to your contacts to find your friends. Please go to Settings -> Privacy -> Contacts to give access", nil);
    NSString *ok = NSLocalizedString(@"OK", nil);

    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:ok otherButtonTitles:nil] show];
    });
}

- (void)_handlePhoneNumber:(NSString *)phoneNumber contactName:(NSString *)contactName
{
    NSNumber *number = [self _parsePhoneNumber:phoneNumber];
    if (number == 0)
    {
        return;
    }

    [self.phoneNumberSet addObject:number];
    [self.contactDict setObject:contactName forKey:number];
}

- (NSNumber *)_parsePhoneNumber:(NSString *)phone
{
    NSError *error = nil;
    NBPhoneNumber *phoneNumber = [self.phoneUtil parse:phone defaultRegion:self.countryCode error:&error];

    if (error || ![self.phoneUtil isValidNumber:phoneNumber])
    {
        return 0;
    }

    NSString *e164 = [self.phoneUtil format:phoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&error];
    if (error)
    {
        return 0;
    }

    // remove '+'
    NSString *phoneStr = [e164 substringFromIndex:1];
    return [phoneStr uint64Number];
}

- (NSString *)_fullNameWithFirstname:(NSString *)firstname lastname:(NSString *)lastname
{
    if (lastname == nil)
    {
        return [NSString stringWithFormat:@"%@", firstname];
    }
    else if (firstname == nil)
    {
        return [NSString stringWithFormat:@"%@", lastname];
    }
    return [NSString stringWithFormat:@"%@ %@", firstname, lastname];
}

- (NSString *)countryCode
{
    if (!_countryCode)
    {
        CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        _countryCode = [carrier.isoCountryCode uppercaseString];
    }
    return _countryCode;
}

#pragma mark - Network

- (void) _readRemoteUsersInContact
{
    if ([self.phoneNumberSet count] == 0)
    {
        return;
    }

    NSString *url = [NSString apiURLWithPath:@"contacts"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters: [self _readRemoteUsersParameters]
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"GET contacts Success");

             NSMutableArray *userList = [NSMutableArray new];
             for (NSDictionary *dict in responseObject)
             {
                 NSError *error = nil;
                 JYUser *user = (JYUser *)[MTLJSONAdapter modelOfClass:JYUser.class fromJSONDictionary:dict error:&error];
                 if (user)
                 {
                     [userList addObject:user];
                 }
             }

             if ([userList count] > 0)
             {
                 [weakSelf _findInContactsUsers:userList];
             }
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"GET contacts error: %@", error);
         }];
}

- (NSDictionary *)_readRemoteUsersParameters
{
    NSMutableArray *phoneNumberList = [NSMutableArray new];
    for (NSNumber *phoneNumber in self.phoneNumberSet)
    {
        uint64_t number = [phoneNumber unsignedLongLongValue];
        [phoneNumberList addObject:@(number)];
    }
    NSLog(@"phoneNumberList count = %lu", (unsigned long)[phoneNumberList count]);
    return @{@"phone": phoneNumberList};
}

- (void)_findInContactsUsers:(NSArray *)userList
{
    NSDictionary *info = @{@"users": userList, @"contacts": self.contactDict};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidFindInContactsUsers object:nil userInfo:info];
}

@end
