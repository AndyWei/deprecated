//
//  JYSessionListViewCell.h
//  joyyios
//
//  Created by Ping Yang on 9/3/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYMessage.h"

@interface JYSessionListViewCell : UITableViewCell

@property (nonatomic) JYMessage *message;
@property (nonatomic, readonly) JYFriend *friend;

@end
