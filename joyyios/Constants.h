//
//  Constants.h
//  joyy
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#ifndef joyy_Constants_h
#define joyy_Constants_h

extern NSString *const kUrlAPIBase;

extern const CGFloat kButtonCornerRadius;
extern const CGFloat kButtonDefaultHeight;
extern const CGFloat kButtonDefaultFontSize;
extern const CGFloat kButtonLocateDiameter;

extern const CGFloat kIntroductionVersion;

extern const CGFloat kFontSizeCaption;
extern const CGFloat kFontSizeComment;
extern const CGFloat kFontSizeDetail;

extern const CGFloat kMarginLeft;
extern const CGFloat kMarginRight;
extern const CGFloat kMarginTop;

extern const CGFloat kPhotoQuality;
extern const CGFloat kPhotoWidth;  // exact pixel size

extern const CGFloat kSignButtonHeight;
extern const CGFloat kSignButtonWidth;
extern const CGFloat kSignButtonMarginTop;
extern const CGFloat kSignFieldFloatingLabelFontSize;
extern const CGFloat kSignFieldFontSize;
extern const CGFloat kSignFieldHeight;
extern const CGFloat kSignFieldMarginLeft;
extern const CGFloat kSignViewTopOffset;

extern const NSTimeInterval k1Minutes;
extern const NSTimeInterval k15Minutes;
extern const NSTimeInterval k30Minutes;

extern const NSUInteger kAPN;
extern const NSUInteger kRecentCommentsLimit;

extern NSString *const kErrorAuthenticationFailed;
extern NSString *const kErrorTitle;

extern NSString *const kNotificationDidSignIn;
extern NSString *const kNotificationDidSignUp;
extern NSString *const kNotificationNeedGeoInfo;
extern NSString *const kNotificationWillCommentPost;
extern NSString *const kNotificationWillLikePost;

extern NSString *const kSystemFontBold;
extern NSString *const kSystemFontItalic;
extern NSString *const kSystemFontLight;
extern NSString *const kSystemFontRegular;

#define NAVIGATION_BAR_HEIGHT       (self.navigationController.navigationBar.frame.size.height)    // 44
#define STATUS_BAR_HEIGHT           ([UIApplication sharedApplication].statusBarFrame.size.height) // 20
#define SCREEN_WIDTH                CGRectGetWidth([[UIScreen mainScreen] applicationFrame])
#define SCREEN_HEIGHT               CGRectGetHeight([[UIScreen mainScreen] applicationFrame])
#define TRANSLUCENT_TOP_BAR_HEIGHT  (self.topLayoutGuide.length)                                   // 64

#endif
