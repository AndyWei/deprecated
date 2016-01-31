//
//  JYSessionListViewCell.h
//  joyyios
//
//  Created by Ping Yang on 9/3/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYSession.h"

@interface JYSessionListViewCell : UITableViewCell

@property (nonatomic) JYSession *session;
@property (nonatomic, readonly) JYFriend *friend;

@end
