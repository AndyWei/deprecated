//
//  JYCardView.h
//  joyyios
//
//  Created by Ping Yang on 12/9/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYCardView;

@protocol JYCardViewDelegate <NSObject>
- (void)didTapAvatarOnView:(JYCardView *)view;
@end

@interface JYCardView : UIView

@property (nonatomic) UIButton *avatarButton;
@property (nonatomic) UIImageView *coverView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic, weak) id<JYCardViewDelegate> delegate;
- (void)addBlur;
- (void)removeBlur;
- (void)addShadow;
- (void)removeShadow;

@end