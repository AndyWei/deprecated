//
//  JYProfileCardView.h
//  joyyios
//
//  Created by Ping Yang on 12/23/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYUser;

@interface JYProfileCardView : UIView

@property (nonatomic) JYUser *user;
@property (nonatomic) uint32_t friendCount;
@property (nonatomic) uint32_t inviteCount;
@property (nonatomic) uint32_t winkCount;

@end