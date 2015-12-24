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
@property (nonatomic) uint64_t friendCount;
@property (nonatomic) uint64_t inviteCount;
@property (nonatomic) uint64_t winkCount;

@end