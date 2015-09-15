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
extern CGFloat const kIntroductionVersion;
extern CGFloat const kFontSizeCaption;
extern CGFloat const kFontSizeComment;
extern CGFloat const kFontSizeDetail;
extern CGFloat const kMarginLeft;
extern CGFloat const kMarginRight;
extern CGFloat const kMarginTop;
extern CGFloat const kPhotoQuality;
extern CGFloat const kPhotoWidth;  // exact pixel size
extern CGFloat const kSignButtonHeight;
extern CGFloat const kSignButtonWidth;
extern CGFloat const kSignButtonMarginTop;
extern CGFloat const kSignFieldFloatingLabelFontSize;
extern CGFloat const kSignFieldFontSize;
extern CGFloat const kSignFieldHeight;
extern CGFloat const kSignFieldMarginLeft;
extern CGFloat const kSignViewTopOffset;

extern CGFloat const kCellHeight;
extern CGFloat const kHeaderHeight;
extern CGFloat const kFooterHeight;

// AWS
extern NSString *const kAuthProviderName;
extern NSString *const kCognitoIdentityPoolId;
extern NSString *const kPostBucket;
extern NSString *const kMessagesBucket;
extern AWSRegionType const kCognitoRegionType;
// AWS end


// KeyChain
extern NSString *const kKeyChainStoreAPI;
extern NSString *const kKeyChainStoreAWS;

extern NSString *const kAPIPhoneNumberKey;
extern NSString *const kAPIPasswordKey;
extern NSString *const kAPIUserIdKey;
extern NSString *const kAPIUsernameKey;
extern NSString *const kAPITokenKey;
extern NSString *const kAPITokenExpiryTimeKey;

extern NSString *const kAWSIdentityIdKey;
extern NSString *const kAWSTokenKey;
extern NSString *const kAWSTokenExpiryTimeKey;
// KeyChain end

extern NSString *const kContentTypeJPG;
extern NSString *const kDummyCaptionText;
extern NSString *const kErrorAuthenticationFailed;
extern NSString *const kErrorTitle;
extern NSString *const kMessageDomain;
extern NSString *const kMessageResource;
extern NSString *const kMessageBodyTypeAudio;
extern NSString *const kMessageBodyTypeEmoji;
extern NSString *const kMessageBodyTypeGif;
extern NSString *const kMessageBodyTypeImage;
extern NSString *const kMessageBodyTypeLocation;
extern NSString *const kMessageBodyTypeText;
extern NSString *const kMessageBodyTypeVideo;
extern NSString *const kNotificationDidChangeCountryCode;
extern NSString *const kNotificationDidSignIn;
extern NSString *const kNotificationDidSignUp;
extern NSString *const kNotificationNeedGeoInfo;
extern NSString *const kNotificationWillCommentPost;
extern NSString *const kNotificationWillLikePost;
extern NSString *const kSystemFontBold;
extern NSString *const kSystemFontItalic;
extern NSString *const kSystemFontLight;
extern NSString *const kSystemFontRegular;
extern NSString *const kTableNameLikedPost;
extern NSString *const kTableNamePerson;
extern NSString *const kURLAPIBase;
extern NSString *const kURLAvatarBase;
extern NSString *const kURLPostBase;
extern NSString *const kURLMessageBase;

extern NSInteger const kSignInRetryInSeconds;
extern NSTimeInterval const k15Minutes;
extern NSTimeInterval const k5Minutes;

extern NSUInteger const kAPN;
extern NSUInteger const kRecentCommentsLimit;

extern UInt16  const kMessagePort;


#define NAVIGATION_BAR_HEIGHT       (self.navigationController.navigationBar.frame.size.height)    // 44
#define STATUS_BAR_HEIGHT           ([UIApplication sharedApplication].statusBarFrame.size.height) // 20
#define SCREEN_WIDTH                CGRectGetWidth([[UIScreen mainScreen] applicationFrame])
#define SCREEN_HEIGHT               CGRectGetHeight([[UIScreen mainScreen] applicationFrame])
#define TRANSLUCENT_TOP_BAR_HEIGHT  (self.topLayoutGuide.length)                                   // 64

#endif
