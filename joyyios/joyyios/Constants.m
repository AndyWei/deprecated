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
CGFloat const kFontSizeCaption = 17.0f;
CGFloat const kFontSizeComment = 16.0f;
CGFloat const kFontSizeDetail = 14.0f;
CGFloat const kMarginLeft = 8.0f;
CGFloat const kMarginRight = 8.0f;
CGFloat const kMarginTop = 8.0f;
CGFloat const kMessageMediaWidthDefault = 140.0f;
CGFloat const kMessageMediaHeightDefault = 100.f;
CGFloat const kPhotoQuality = 0.7;
CGFloat const kPhotoWidth = 750.0;
CGFloat const kThumbnailWidth = 120;
CGFloat const kSecondsOfDay = 86400.0f;
CGFloat const kSignButtonHeight = 60.0f;
CGFloat const kSignButtonWidth = 120;
CGFloat const kSignButtonMarginTop = 20.0f;
CGFloat const kSignFieldHeight = 70.0f;
CGFloat const kSignFieldMarginLeft = 50.0f;
CGFloat const kSignViewTopOffset = 152;

CGFloat const kCellHeight = 50;
CGFloat const kHeaderHeight = 100;
CGFloat const kFooterHeight = 100;

NSInteger const kSignInRetryInSeconds = 60;
NSTimeInterval const k5Minutes = 300;

NSUInteger const kAPN = 1;

UInt16 const kMessagePort = 5222;

// AWS
NSString *const kAuthProviderName = @"joyy"; // the provider name configured in the Cognito console.
NSString *const kCognitoIdentityPoolId = @"us-east-1:a9366287-4298-443f-aa0b-d4d6ee43fa67";
AWSRegionType const kCognitoRegionType = AWSRegionUSEast1;

// Flurry
NSString *const kFlurryKey = @"3RRHRXVTX38ZCW3QRHV6";

NSString *const kContentTypeAudioMPEG = @"audio/mpeg";
NSString *const kContentTypeJPG = @"image/jpeg";
NSString *const kErrorSignInFailed = @"Incorrect password";
NSString *const kErrorTitle = @"😜: oops!";
NSString *const kLikeText = @"♡";


NSString *const kMessageDomain = @"joyy.im";
NSString *const kMessageResource = @"iPhone";
NSString *const kMessageBodyTypeAudio    = @"aud";
NSString *const kMessageBodyTypeEmoji    = @"emo";
NSString *const kMessageBodyTypeGif      = @"gif";
NSString *const kMessageBodyTypeImage    = @"img";
NSString *const kMessageBodyTypeLocation = @"loc:";
NSString *const kMessageBodyTypeText     = @"txt";
NSString *const kMessageBodyTypeVideo    = @"vid";

NSString *const kNotificationAPITokenReady = @"apiTokenReady";
NSString *const kNotificationAppDidStart = @"appDidStart";
NSString *const kNotificationAppDidStop  = @"appDidStop";
NSString *const kNotificationCreateComment = @"createComment";
NSString *const kNotificationDeleteComment = @"deleteComment";
NSString *const kNotificationDidAddFriend = @"didAddFriend";
NSString *const kNotificationDidChangeCountryCode = @"didChangeCountryCode";
NSString *const kNotificationDidChangeRedDot = @"didChangeRedDot";
NSString *const kNotificationDidCreateProfile = @"didCreateProfile";
NSString *const kNotificationDidFindInContactsUsers = @"didFindInContactsUsers";
NSString *const kNotificationDidTapOnUser = @"didTapOnUser";
NSString *const kNotificationDidTapReminderView = @"didTapReminderView";
NSString *const kNotificationDidSendMessage = @"didSendMessage";
NSString *const kNotificationDidReceiveMessage = @"didReceiveMessage";
NSString *const kNotificationDidSignIn = @"didSignIn";
NSString *const kNotificationDidSignUp = @"didSignUp";
NSString *const kNotificationNeedGeoInfo = @"needGeoInfo";
NSString *const kNotificationNeedUpdateSession = @"needUpdateSession";
NSString *const kNotificationUpdateBadgeCount = @"updateBadgeCount";
NSString *const kNotificationUserYRSReady = @"userYRSReady";
NSString *const kNotificationWillChat = @"willChat";
NSString *const kNotificationChatting = @"chatting";

NSString *const kURLAPIBase = @"http://api.winkrock.com:8000/v1/";
//NSString *const kURLAPIBase = @"http://dev.winkrock.com:8000/v1/";
//NSString *const kURLAPIBase = @"http://192.168.1.104:8000/v1/";

