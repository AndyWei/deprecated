//
//  JYSessionViewController.h
//  joyyios
//
//  Created by Ping Yang on 2/15/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <SlackTextViewController/SLKTextViewController.h>

typedef void(^ImageHandler)(NSString *url);

@interface JYSessionViewController : SLKTextViewController
@property (nonatomic) JYFriend *friend;
@end
