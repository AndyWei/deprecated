//
//  JYMessageCell.h
//  joyyios
//
//  Created by Ping Yang on 2/15/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "JYMessage.h"

@interface JYMessageCell : UITableViewCell

@property (nonatomic) JYMessage *message;
@property (nonatomic) UIImageView *avatarView;

@end
