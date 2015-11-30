//
//  JYFilename.m
//  joyyios
//
//  Created by Ping Yang on 9/2/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#import "JYCredential.h"
#import "JYFilename.h"

@interface JYFilename ()
@property (nonatomic) NSDictionary *bucketPrefixDict;
@property (nonatomic) NSDictionary *countryContinetDict;
@property (nonatomic) NSDictionary *continetRegionDict;
@property (nonatomic) NSDictionary *regionPostURLDict;
@property (nonatomic) NSDictionary *regionAvatarURLDict;
@property (nonatomic) NSString *bucketPrefix;
@property (nonatomic) NSString *continent;
@end


@implementation JYFilename

+ (JYFilename *)sharedInstance
{
    static JYFilename *_sharedInstance = nil;
    static dispatch_once_t done;

    dispatch_once(&done, ^{
        _sharedInstance = [JYFilename new];
    });

    return _sharedInstance;
}

- (NSString *)randomFilenameWithHttpContentType:(NSString *)contentType
{
    NSString *suffix = @"unknown";
    if ([contentType isEqualToString:kContentTypeJPG])
    {
        suffix = @"jpg";
    }
    return [self randomFilenameWithSuffix:suffix];
}

- (NSString *)randomFourDigits
{
    u_int32_t rand = arc4random_uniform(10000);                        // 176
    NSString *randString = [NSString stringWithFormat:@"%04d", rand];  // "0176"
    return randString;
}

- (NSString *)randomFilenameWithSuffix:(NSString *)suffix
{
    NSString *first = [[JYCredential current].username substringToIndex:1];  // "j" for jack
    NSString *randString = [self randomFourDigits];              // "0176"
    NSString *timestamp = [self timeInMiliSeconds];              // 458354045799

    return [NSString stringWithFormat:@"%@%@_%@.%@", first, randString, timestamp, suffix]; // "j0176_458354045799.jpg"
}

- (NSString *)timeInMiliSeconds
{
    long long timestamp = [@(floor([NSDate timeIntervalSinceReferenceDate] * 1000)) longLongValue];
    return [NSString stringWithFormat:@"%lld",timestamp];
}

- (NSString *)urlForAvatarWithRegion:(NSString *)region filename:(NSString *)filename
{
    return [self urlWithRegion:region filename:filename type:@"avatar"];
}

- (NSString *)urlForPostWithRegion:(NSString *)region filename:(NSString *)filename
{
    return [self urlWithRegion:region filename:filename type:@"post"];
}

- (NSString *)urlWithRegion:(NSString *)region filename:(NSString *)filename type:(NSString *)type
{
    NSString *fullFilename = filename;

    // If the filename doesn't contain suffix, then append ".jpg"
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"."];
    NSRange range = [filename rangeOfCharacterFromSet:set];
    if (range.location == NSNotFound)
    {
        fullFilename = [filename stringByAppendingString:@".jpg"];
    }

    NSString *domain = @"joyyapp.com";
    NSString *url = [NSString stringWithFormat:@"%@-%@.%@/%@", region, type, domain, fullFilename];
    return url;
}

- (NSString *)buketNameWithType:(NSString *)type
{
    return [NSString stringWithFormat:@"%@%@", self.bucketPrefix, type];
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

- (NSString *)avatarBucketName
{
    if (!_avatarBucketName)
    {
        _avatarBucketName = [self buketNameWithType:@"avatar"];
    }
    return _avatarBucketName;
}

- (NSString *)messageBucketName
{
    if (!_messageBucketName)
    {
        _messageBucketName = [self buketNameWithType:@"im"];
    }
    return _messageBucketName;
}

- (NSString *)postBucketName
{
    if (!_postBucketName)
    {
        _postBucketName = [self buketNameWithType:@"post"];
    }
    return _postBucketName;
}

- (NSString *)avatarURLPrefixOfRegion:(NSString *)region
{
    return self.regionAvatarURLDict[region];
}

- (NSString *)postURLPrefixOfRegion:(NSString *)region
{
    return self.regionPostURLDict[region];
}

// Mapping region value to post URL prefix
- (NSDictionary *)regionAvatarURLDict
{
    if (!_regionAvatarURLDict)
    {
        _regionAvatarURLDict = @{
                               @"0": @"http://joyyavatar-1d98.kxcdn.com/", // north america keyCDN zone
                               @"1": @"http://asjyavatar-1d98.kxcdn.com/", // asia keyCDN zone
                               @"2": @"http://eujyavatar-1d98.kxcdn.com/"  // europe keyCDN zone
                               };
    }
    return _regionAvatarURLDict;
}

// Mapping region value to post URL prefix
- (NSDictionary *)regionPostURLDict
{
    if (!_regionPostURLDict)
    {
        _regionPostURLDict = @{
                           @"0": @"http://joyypost-1d98.kxcdn.com/", // north america keyCDN zone
                           @"1": @"http://asjypost-1d98.kxcdn.com/", // asia keyCDN zone
                           @"2": @"http://eujypost-1d98.kxcdn.com/"  // europe keyCDN zone
                          };
    }
    return _regionPostURLDict;
}

- (NSString *)region
{
    if (!_region)
    {
        _region = [self.continetRegionDict objectForKey:self.continent];
    }
    return _region;
}

// Mapping continent code to region value
- (NSDictionary *)continetRegionDict
{
    if (!_continetRegionDict)
    {
        _continetRegionDict = @{ @"na":@"0",
                                 @"sa":@"0",
                                 @"as":@"1",
                                 @"oc":@"1",
                                 @"eu":@"2",
                                 @"af":@"2"
                              };
    }
    return _continetRegionDict;
}

- (NSString *)bucketPrefix
{
    if (!_bucketPrefix)
    {
        _bucketPrefix = [self.bucketPrefixDict objectForKey:self.continent];
    }
    return _bucketPrefix;
}

// Mapping continent code to bucket name prefix
- (NSDictionary *)bucketPrefixDict
{
    if (!_bucketPrefixDict)
    {
        _bucketPrefixDict = @{ @"as":@"as-jy-", @"oc":@"as-jy-",
                               @"eu":@"eu-jy-", @"af":@"eu-jy-",
                               @"na":@"joyy", @"sa":@"joyy" };
    }
    return _bucketPrefixDict;
}


// Mapping country code to continent code
// Note: All middle East counties are mapped to "eu" for network speed optimization

- (NSString *)continent
{
    if (!_continent)
    {
        _continent = [self.countryContinetDict objectForKey:self.countryCode];
        if (!_continent)
        {
            _continent = @"na";
        }
    }
    return _continent;
}

- (NSDictionary *)countryContinetDict
{
    if (!_countryContinetDict)
    {
        _countryContinetDict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"eu", @"AD", @"eu", @"AE", @"as", @"AF", @"na", @"AG", @"na", @"AI", @"eu", @"AL", @"as", @"AM", @"na", @"AN",
                        @"af", @"AO", @"as", @"AP", @"an", @"AQ", @"sa", @"AR", @"oc", @"AS", @"eu", @"AT", @"oc", @"AU", @"na", @"AW",
                        @"eu", @"AX", @"as", @"AZ", @"eu", @"BA", @"na", @"BB", @"as", @"BD", @"eu", @"BE", @"af", @"BF", @"eu", @"BG",
                        @"as", @"BH", @"af", @"BI", @"af", @"BJ", @"na", @"BL", @"na", @"BM", @"as", @"BN", @"sa", @"BO", @"sa", @"BR",
                        @"na", @"BS", @"as", @"BT", @"an", @"BV", @"af", @"BW", @"eu", @"BY", @"na", @"BZ", @"na", @"CA", @"as", @"CC",
                        @"af", @"CD", @"af", @"CF", @"af", @"CG", @"eu", @"CH", @"af", @"CI", @"oc", @"CK", @"sa", @"CL", @"af", @"CM",
                        @"as", @"CN", @"sa", @"CO", @"na", @"CR", @"na", @"CU", @"af", @"CV", @"as", @"CX", @"eu", @"CY", @"eu", @"CZ",
                        @"eu", @"DE", @"af", @"DJ", @"eu", @"DK", @"na", @"DM", @"na", @"DO", @"af", @"DZ", @"sa", @"EC", @"eu", @"EE",
                        @"af", @"EG", @"af", @"EH", @"af", @"ER", @"eu", @"ES", @"af", @"ET", @"eu", @"EU", @"eu", @"FI", @"oc", @"FJ",
                        @"sa", @"FK", @"oc", @"FM", @"eu", @"FO", @"eu", @"FR", @"eu", @"FX", @"af", @"GA", @"eu", @"GB", @"na", @"GD",
                        @"as", @"GE", @"sa", @"GF", @"eu", @"GG", @"af", @"GH", @"eu", @"GI", @"na", @"GL", @"af", @"GM", @"af", @"GN",
                        @"na", @"GP", @"af", @"GQ", @"eu", @"GR", @"an", @"GS", @"na", @"GT", @"oc", @"GU", @"af", @"GW", @"sa", @"GY",
                        @"as", @"HK", @"oc", @"HM", @"na", @"HN", @"eu", @"HR", @"na", @"HT", @"eu", @"HU", @"as", @"ID", @"eu", @"IE",
                        @"eu", @"IL", @"eu", @"IM", @"as", @"IN", @"as", @"IO", @"eu", @"IQ", @"eu", @"IR", @"eu", @"IS", @"eu", @"IT",
                        @"eu", @"JE", @"na", @"JM", @"eu", @"JO", @"as", @"JP", @"af", @"KE", @"as", @"KG", @"as", @"KH", @"oc", @"KI",
                        @"af", @"KM", @"na", @"KN", @"as", @"KP", @"as", @"KR", @"eu", @"KW", @"na", @"KY", @"as", @"KZ", @"as", @"LA",
                        @"eu", @"LB", @"na", @"LC", @"eu", @"LI", @"as", @"LK", @"af", @"LR", @"af", @"LS", @"eu", @"LT", @"eu", @"LU",
                        @"eu", @"LV", @"af", @"LY", @"af", @"MA", @"eu", @"MC", @"eu", @"MD", @"eu", @"ME", @"na", @"MF", @"af", @"MG",
                        @"oc", @"MH", @"eu", @"MK", @"af", @"ML", @"as", @"MM", @"as", @"MN", @"as", @"MO", @"oc", @"MP", @"na", @"MQ",
                        @"af", @"MR", @"na", @"MS", @"eu", @"MT", @"af", @"MU", @"as", @"MV", @"af", @"MW", @"na", @"MX", @"as", @"MY",
                        @"af", @"MZ", @"af", @"NA", @"oc", @"NC", @"af", @"NE", @"oc", @"NF", @"af", @"NG", @"na", @"NI", @"eu", @"NL",
                        @"eu", @"NO", @"as", @"NP", @"oc", @"NR", @"oc", @"NU", @"oc", @"NZ", @"eu", @"OM", @"na", @"PA", @"sa", @"PE",
                        @"oc", @"PF", @"oc", @"PG", @"as", @"PH", @"as", @"PK", @"eu", @"PL", @"na", @"PM", @"oc", @"PN", @"na", @"PR",
                        @"eu", @"PS", @"eu", @"PT", @"oc", @"PW", @"sa", @"PY", @"as", @"QA", @"af", @"RE", @"eu", @"RO", @"eu", @"RS",
                        @"eu", @"RU", @"af", @"RW", @"eu", @"SA", @"oc", @"SB", @"af", @"SC", @"af", @"SD", @"eu", @"SE", @"as", @"SG",
                        @"af", @"SH", @"eu", @"SI", @"eu", @"SJ", @"eu", @"SK", @"af", @"SL", @"eu", @"SM", @"af", @"SN", @"af", @"SO",
                        @"sa", @"SR", @"af", @"ST", @"na", @"SV", @"eu", @"SY", @"af", @"SZ", @"na", @"TC", @"af", @"TD", @"an", @"TF",
                        @"af", @"TG", @"as", @"TH", @"as", @"TJ", @"oc", @"TK", @"as", @"TL", @"as", @"TM", @"af", @"TN", @"oc", @"TO",
                        @"eu", @"TR", @"na", @"TT", @"oc", @"TV", @"as", @"TW", @"af", @"TZ", @"eu", @"UA", @"af", @"UG", @"oc", @"UM",
                        @"na", @"US", @"sa", @"UY", @"as", @"UZ", @"eu", @"VA", @"na", @"VC", @"sa", @"VE", @"na", @"VG", @"na", @"VI",
                        @"as", @"VN", @"oc", @"VU", @"oc", @"WF", @"oc", @"WS", @"eu", @"YE", @"af", @"YT", @"af", @"ZA", @"af", @"ZM",
                        @"af", @"ZW", nil];
    }
    return _countryContinetDict;
}

@end

