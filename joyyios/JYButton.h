//
//  JYButton.h
//  joyyios
//
//  Forked and modified by Ping Yang on 3/27/15 from Github project: MRoundedButton
//  Below is the original license:

//  ---------------------------Begin of the original license--------------------
//  Copyright (c) 2014 Michael WU. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//  ---------------------------End of the original license--------------------

typedef NS_ENUM(NSInteger, JYButtonStyle)
{
    JYButtonStyleDefault,
    JYButtonStyleSubtitle,
    JYButtonStyleCentralImage,
    JYButtonStyleImageWithSubtitle,
    JYButtonStyleImageWithTitle
};

extern CGFloat const JYButtonMaxValue;

@interface JYButton : UIControl

@property(nonatomic, readonly) JYButtonStyle buttonStyle;
@property(nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;
@property(nonatomic) CGFloat borderWidth UI_APPEARANCE_SELECTOR;
@property(nonatomic) UIColor *borderColor UI_APPEARANCE_SELECTOR;
@property(nonatomic) UIColor *contentColor UI_APPEARANCE_SELECTOR;
@property(nonatomic) UIColor *foregroundColor UI_APPEARANCE_SELECTOR;
@property(nonatomic) UIColor *borderAnimateToColor UI_APPEARANCE_SELECTOR;
@property(nonatomic) UIColor *contentAnimateToColor UI_APPEARANCE_SELECTOR;
@property(nonatomic) UIColor *foregroundAnimateToColor UI_APPEARANCE_SELECTOR;
@property(nonatomic) BOOL restoreSelectedState UI_APPEARANCE_SELECTOR;
@property(nonatomic) BOOL shouldMaskImage;

@property(nonatomic, weak) UILabel *textLabel;
@property(nonatomic, weak) UILabel *detailTextLabel;
@property(nonatomic, weak) UIImageView *imageView;
@property(nonatomic) UIEdgeInsets contentEdgeInsets;

+ (instancetype)buttonWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style appearanceIdentifier:(NSString *)identifier;
+ (instancetype)buttonWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style shouldMaskImage:(BOOL)mask;
+ (instancetype)buttonWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style shouldMaskImage:(BOOL)mask appearanceIdentifier:(NSString *)identifier;
- (instancetype)initWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style;
- (instancetype)initWithFrame:(CGRect)frame buttonStyle:(JYButtonStyle)style appearanceIdentifier:(NSString *)identifier;

@end

extern NSString *const kJYButtonCornerRadius;
extern NSString *const kJYButtonBorderWidth;
extern NSString *const kJYButtonBorderColor;
extern NSString *const kJYButtonContentColor;
extern NSString *const kJYButtonForegroundColor;
extern NSString *const kJYButtonBorderAnimateToColor;
extern NSString *const kJYButtonContentAnimateToColor;
extern NSString *const kJYButtonForegroundAnimateToColor;
extern NSString *const kJYButtonRestoreSelectedState;

@interface JYButtonAppearanceManager : NSObject

+ (void)registerAppearanceProxy:(NSDictionary *)proxy forIdentifier:(NSString *)identifier;
+ (void)unregisterAppearanceProxyIdentier:(NSString *)identifier;
+ (NSDictionary *)appearanceForIdentifier:(NSString *)identifier;

@end

@interface JYHollowBackgroundView : UIView

@property(nonatomic) UIColor *foregroundColor;

@end
