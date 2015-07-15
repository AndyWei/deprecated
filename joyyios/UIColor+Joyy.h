//
//  UIColor+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#define JoyyBlack     [UIColor joyyBlackColor]
#define JoyyBlack50   [UIColor joyyBlackColor50]

#define JoyyBlue      [UIColor joyyBlueColor]
#define JoyyBlue50    [UIColor joyyBlueColor50]
#define JoyyBlue30    [UIColor joyyBlueColor30]

#define JoyyGray      [UIColor grayColor]
#define JoyyGray50    [UIColor joyyGrayColor50]

#define JoyyWhite     [UIColor joyyWhiteColor]


@interface UIColor (Joyy)

+ (UIColor *)joyyBlackColor;
+ (UIColor *)joyyBlackColor50;
+ (UIColor *)joyyBlueColor;
+ (UIColor *)joyyBlueColor50;
+ (UIColor *)joyyBlueColor30;
+ (UIColor *)joyyGrayColor50;
+ (UIColor *)joyyWhiteColor;

@end