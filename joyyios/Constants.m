//
//  Constants.m
//  joyy
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

CGFloat const kButtonCornerRadius = 4.0f;
CGFloat const kButtonDefaultHeight = 44.0f;
CGFloat const kButtonDefaultFontSize = 18.0f;
CGFloat const kButtonLocateDiameter = 40;
CGFloat const kIntroductionVersion = 1.0;
CGFloat const kFontSizeCaption = 16.0f;
CGFloat const kFontSizeComment = 15.0f;
CGFloat const kFontSizeDetail = 13.0f;
CGFloat const kMarginLeft = 8.0f;
CGFloat const kMarginRight = 8.0f;
CGFloat const kMarginTop = 8.0f;
CGFloat const kPhotoQuality = 0.7;
CGFloat const kPhotoWidth = 375.0;
CGFloat const kSignButtonHeight = 60.0f;
CGFloat const kSignButtonWidth = 120;
CGFloat const kSignButtonMarginTop = 20.0f;
CGFloat const kSignFieldFloatingLabelFontSize = 11.0f;
CGFloat const kSignFieldFontSize = 18.0f;
CGFloat const kSignFieldHeight = 70.0f;
CGFloat const kSignFieldMarginLeft = 50.0f;
CGFloat const kSignViewTopOffset = 152;

CGFloat const kCellHeight = 50;
CGFloat const kHeaderHeight = 100;
CGFloat const kFooterHeight = 100;

NSInteger const kSignInRetryInSeconds = 60;
NSTimeInterval const k5Minutes = 300;

NSUInteger const kAPN = 1;
NSUInteger const kRecentCommentsLimit = 3;

UInt16 const kMessagePort = 5222;

// AWS
NSString *const kAuthProviderName = @"joyy"; // the provider name configured in the Cognito console.
NSString *const kCognitoIdentityPoolId = @"us-east-1:a9366287-4298-443f-aa0b-d4d6ee43fa67";
NSString *const kAvatarBucket   = @"joyyavatar";
NSString *const kMessagesBucket = @"joyyim";
NSString *const kPostBucket     = @"joyypost";
AWSRegionType const kCognitoRegionType = AWSRegionUSEast1;
// AWS end

NSString *const kContentTypeJPG = @"image/jpeg";
NSString *const kDummyCaptionText = @"◦";
NSString *const kErrorSignInFailed = @"Incorrect password";
NSString *const kErrorTitle = @"😜: oops!";

NSString *const kMessageDomain = @"joyy.im";
NSString *const kMessageResource = @"iPhone";
NSString *const kMessageBodyTypeAudio    = @"a:";
NSString *const kMessageBodyTypeEmoji    = @"e:";
NSString *const kMessageBodyTypeGif      = @"g:";
NSString *const kMessageBodyTypeImage    = @"i:";
NSString *const kMessageBodyTypeLocation = @"l:";
NSString *const kMessageBodyTypeText     = @"t:";
NSString *const kMessageBodyTypeVideo    = @"v:";

NSString *const kNotificationAppDidStart = @"appDidStart";
NSString *const kNotificationAppDidStop  = @"appDidStop";
NSString *const kNotificationDidChangeCountryCode = @"didChangeCountryCode";
NSString *const kNotificationDidSignIn = @"didSignIn";
NSString *const kNotificationDidSignUp = @"didSignUp";
NSString *const kNotificationNeedGeoInfo = @"needGeoInfo";
NSString *const kNotificationWillCommentPost = @"willCommentPost";
NSString *const kNotificationWillLikePost = @"willLikePost";

NSString *const kSystemFontBold = @"AvenirNextCondensed-DemiBold";
NSString *const kSystemFontItalic = @"AvenirNextCondensed-Italic ";
NSString *const kSystemFontLight = @"AvenirNextCondensed-UltraLight ";
NSString *const kSystemFontRegular = @"AvenirNextCondensed-Regular";

NSString *const kTableNameLikedPost = @"liked_post";
NSString *const kTableNamePerson = @"person";

NSString *const kURLAPIBase = @"http://api.joyyapp.com:8000/v1/";
//NSString *const kURLAPIBase = @"http://192.168.1.106:8000/v1/";

NSString *const kURLAvatarBase = @"http://avatar.joyyapp.com/";
NSString *const kURLMessageMediaBase = @"http://media.joyy.im/";
NSString *const kURLPostBase = @"http://post.joyyapp.com/";
