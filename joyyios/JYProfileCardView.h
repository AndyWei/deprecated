//
//  JYProfileCardView.h
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYUser;
@class JYProfileCardView;

@protocol JYProfileCardViewDelegate <NSObject>
- (void)didTapAvatarOnView:(JYProfileCardView *)view;
- (void)didTapFriendLabelOnView:(JYProfileCardView *)view;
- (void)didTapContactLabelOnView:(JYProfileCardView *)view;
- (void)didTapWinkLabelOnView:(JYProfileCardView *)view;
@end

@interface JYProfileCardView : UIView
@property (nonatomic) JYUser *user;
@property (nonatomic) UIImage *avatarImage;
@property (nonatomic) uint64_t friendCount;
@property (nonatomic) uint64_t contactCount;
@property (nonatomic) uint64_t winkCount;
@property (nonatomic, weak) id<JYProfileCardViewDelegate> delegate;
@end