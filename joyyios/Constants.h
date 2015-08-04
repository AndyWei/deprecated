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


extern const NSTimeInterval k1Minutes;
extern const NSTimeInterval k15Minutes;
extern const NSTimeInterval k30Minutes;

extern const CGFloat kButtonCornerRadius;
extern const CGFloat kButtonDefaultHeight;
extern const CGFloat kButtonDefaultFontSize;
extern const CGFloat kButtonLocateDiameter;

extern const CGFloat kCaptionLabelHeightMin;

extern const CGFloat kIntroductionVersion;

extern const CGFloat kFontSizeCaption;
extern const CGFloat kFontSizeComment;
extern const CGFloat kFontSizeDetail;

extern const CGFloat kMapDashBoardHeight;
extern const CGFloat kMapDefaultAltitude;
extern const CGFloat kMapDefaultSpanDistance;

extern const CGFloat kMarginLeft;
extern const CGFloat kMarginRight;
extern const CGFloat kMarginTop;

extern const CGFloat kNavBarTitleFontSize;

extern const CGFloat kPinAnnotationHeight;
extern const CGFloat kPinAnnotationWidth;
extern const CGFloat kPhotoQuality;
extern const CGFloat kPhotoWidth;  // exact pixel size

extern const CGFloat kTabBarTitleFontSize;

extern const CGFloat kSignButtonHeight;
extern const CGFloat kSignButtonWidth;
extern const CGFloat kSignButtonMarginTop;
extern const CGFloat kSignFieldFloatingLabelFontSize;
extern const CGFloat kSignFieldFontSize;
extern const CGFloat kSignFieldHeight;
extern const CGFloat kSignFieldMarginLeft;

extern const CGFloat kSignViewTopOffset;
extern const CGFloat kServiceCategoryCellFontSize;

extern const NSUInteger kBriefCommentsCount;
extern const NSUInteger kAPN;

extern NSString *const kAnnotationTitleEnd;
extern NSString *const kAnnotationTitleStart;

extern NSString *const kErrorAuthenticationFailed;
extern NSString *const kErrorTitle;

extern NSString *const kImageNameLocationArrow;
extern NSString *const kImageNamePinBlue;
extern NSString *const kImageNamePinGreen;
extern NSString *const kImageNamePinPink;

extern NSString *const kNotificationDidCreateAccount;
extern NSString *const kNotificationDidCreateBid;
extern NSString *const kNotificationDidCreateComment;
extern NSString *const kNotificationDidCreateOrder;
extern NSString *const kNotificationDidFinishOrder;
extern NSString *const kNotificationDidReceiveBid;
extern NSString *const kNotificationDidSignIn;
extern NSString *const kNotificationDidSignUp;
extern NSString *const kNotificationNeedGeoInfo;
extern NSString *const kNotificationWillCommentPost;
extern NSString *const kNotificationWillLikePost;

extern NSString *const kSystemFontBold;
extern NSString *const kSystemFontItalic;
extern NSString *const kSystemFontLight;
extern NSString *const kSystemFontRegular;

#define SCREEN_WIDTH  CGRectGetWidth([[UIScreen mainScreen] applicationFrame])
#define SCREEN_HEIGHT CGRectGetHeight([[UIScreen mainScreen] applicationFrame])

#endif
