//
//  Constants.h
//  joyy
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#ifndef joyy_Constants_h
#define joyy_Constants_h

#import <AWSCore/AWSCore.h>

extern CGFloat const kButtonCornerRadius;
extern CGFloat const kButtonDefaultHeight;
extern CGFloat const kButtonDefaultFontSize;
extern CGFloat const kButtonLocateDiameter;
extern CGFloat const kFontSizeCaption;
extern CGFloat const kFontSizeComment;
extern CGFloat const kFontSizeDetail;
extern CGFloat const kMarginLeft;
extern CGFloat const kMarginRight;
extern CGFloat const kMarginTop;
extern CGFloat const kPhotoQuality;
extern CGFloat const kPhotoWidth;  // exact pixel size
extern CGFloat const kThumbnailWidth;
extern CGFloat const kSignButtonHeight;
extern CGFloat const kSignButtonWidth;
extern CGFloat const kSignButtonMarginTop;
extern CGFloat const kSignFieldHeight;
extern CGFloat const kSignFieldMarginLeft;
extern CGFloat const kSignViewTopOffset;
extern CGFloat const kVersionIntroduction;
extern CGFloat const kVersionFeedsViewTips;
extern CGFloat const kVersionPeopleViewTips;

extern CGFloat const kCellHeight;
extern CGFloat const kHeaderHeight;
extern CGFloat const kFooterHeight;

// AWS
extern NSString *const kAuthProviderName;
extern NSString *const kCognitoIdentityPoolId;
extern AWSRegionType const kCognitoRegionType;

// Flurry
extern NSString *const kFlurryKey;

extern NSString *const kContentTypeJPG;
extern NSString *const kErrorSignInFailed;
extern NSString *const kErrorTitle;
extern NSString *const kLikeText;
extern NSString *const kMessageDomain;
extern NSString *const kMessageResource;
extern NSString *const kMessageBodyTypeAudio;
extern NSString *const kMessageBodyTypeEmoji;
extern NSString *const kMessageBodyTypeGif;
extern NSString *const kMessageBodyTypeImage;
extern NSString *const kMessageBodyTypeLocation;
extern NSString *const kMessageBodyTypeText;
extern NSString *const kMessageBodyTypeVideo;
extern NSString *const kNotificationAPITokenReady;
extern NSString *const kNotificationAppDidStart;
extern NSString *const kNotificationAppDidStop;
extern NSString *const kNotificationCreateComment;
extern NSString *const kNotificationDeleteComment;
extern NSString *const kNotificationDidChangeCountryCode;
extern NSString *const kNotificationDidCreateProfile;
extern NSString *const kNotificationDidFinishContactsConnection;
extern NSString *const kNotificationDidTapOnUser;
extern NSString *const kNotificationDidTapReminderView;
extern NSString *const kNotificationDidSignIn;
extern NSString *const kNotificationDidSignUp;
extern NSString *const kNotificationNeedGeoInfo;
extern NSString *const kNotificationUserYRSReady;
extern NSString *const kURLAPIBase;

extern NSInteger const kSignInRetryInSeconds;
extern NSTimeInterval const k15Minutes;
extern NSTimeInterval const k5Minutes;

extern NSUInteger const kAPN;

extern UInt16  const kMessagePort;

typedef void(^SuccessHandler)();
typedef void(^FailureHandler)(NSError *error);

#define NAVIGATION_BAR_HEIGHT       (self.navigationController.navigationBar.frame.size.height)    // 44
#define STATUS_BAR_HEIGHT           ([UIApplication sharedApplication].statusBarFrame.size.height) // 20
#define SCREEN_WIDTH                CGRectGetWidth([[UIScreen mainScreen] applicationFrame])
#define SCREEN_HEIGHT               CGRectGetHeight([[UIScreen mainScreen] applicationFrame])
#define TRANSLUCENT_TOP_BAR_HEIGHT  (self.topLayoutGuide.length)                                   // 64

#endif
