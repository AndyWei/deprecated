//
//  JYCardView.h
//  joyyios
//
//  Created by Ping Yang on 12/9/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@interface JYCardView : UIView

@property (nonatomic) UIImageView *avatarView;
@property (nonatomic) UIImageView *coverView;
@property (nonatomic) UILabel *titleLabel;

- (void)addBlur;
- (void)removeBlur;
- (void)addShadow;
- (void)removeShadow;

@end