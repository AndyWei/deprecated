//
//  JYSessionViewController.h
//  joyyios
//
//  Created by Ping Yang on 8/23/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessages.h>
#import "JYFriend.h"

typedef void(^ImageHandler)(UIImage *image, NSString *url);

@interface JYSessionViewController : JSQMessagesViewController

@property (nonatomic) JYFriend *friend;

@end
