//
//  Constants.m
//  joyy
//
//  Created by Ping Yang on 3/26/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//


NSString *const kUrlAPIBase = @"http://api.joyyapp.com:8000/v1/";
//NSString *const kUrlAPIBase = @"http://192.168.1.145:8000/v1/";
NSString *const kMessageDomain = @"joyy.im";
NSString *const kMessageResource = @"iPhone";
const UInt16 kMessagePort = 5222;

const CGFloat kButtonCornerRadius = 4.0f;
const CGFloat kButtonDefaultHeight = 44.0f;
const CGFloat kButtonDefaultFontSize = 18.0f;
const CGFloat kButtonLocateDiameter = 40;

const CGFloat kIntroductionVersion = 1.0;

const CGFloat kFontSizeCaption = 16.0f;
const CGFloat kFontSizeComment = 15.0f;
const CGFloat kFontSizeDetail = 13.0f;

const CGFloat kMarginLeft = 8.0f;
const CGFloat kMarginRight = 8.0f;
const CGFloat kMarginTop = 8.0f;

const CGFloat kPhotoQuality = 0.7;
const CGFloat kPhotoWidth = 375.0;

const CGFloat kSignButtonHeight = 60.0f;
const CGFloat kSignButtonWidth = 120;
const CGFloat kSignButtonMarginTop = 20.0f;
const CGFloat kSignFieldFloatingLabelFontSize = 11.0f;
const CGFloat kSignFieldFontSize = 18.0f;
const CGFloat kSignFieldHeight = 70.0f;
const CGFloat kSignFieldMarginLeft = 50.0f;
const CGFloat kSignViewTopOffset = 152;

const NSTimeInterval k1Minutes = 60;
const NSTimeInterval k15Minutes = 900;
const NSTimeInterval k30Minutes = 1800;
const NSTimeInterval k5Minutes = 300;

const NSUInteger kAPN = 1;
const NSUInteger kRecentCommentsLimit = 3;

NSString *const kErrorAuthenticationFailed = @"Incorrect Email or password";
NSString *const kErrorTitle = @"🐻: something wrong";

NSString *const kMessageBodyTypeAudio    = @"a:";
NSString *const kMessageBodyTypeEmoji    = @"e:";
NSString *const kMessageBodyTypeGif      = @"g:";
NSString *const kMessageBodyTypeImage    = @"i:";
NSString *const kMessageBodyTypeLocation = @"l:";
NSString *const kMessageBodyTypeText     = @"t:";
NSString *const kMessageBodyTypeVideo    = @"v:";

NSString *const kNotificationDidSignIn = @"signIn";
NSString *const kNotificationDidSignUp = @"signUp";
NSString *const kNotificationNeedGeoInfo = @"needGeoInfo";
NSString *const kNotificationWillCommentPost = @"willCommentPost";
NSString *const kNotificationWillLikePost = @"willLikePost";

NSString *const kSystemFontBold = @"AvenirNextCondensed-DemiBold";
NSString *const kSystemFontItalic = @"AvenirNextCondensed-Italic ";
NSString *const kSystemFontLight = @"AvenirNextCondensed-UltraLight ";
NSString *const kSystemFontRegular = @"AvenirNextCondensed-Regular";
