//
//  JYSessionViewController.h
//  joyyios
//
//  Created by Ping Yang on 8/23/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessages.h>
#import "JYFriend.h"

typedef void(^ImageHandler)(NSString *url);

@interface JYOldSessionViewController : JSQMessagesViewController

@property (nonatomic) JYFriend *friend;

@end
