//
//  JYFriend.h
//  joyyios
//
//  Created by Ping Yang on 11/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYUser.h"

@interface JYFriend : JYUser

+ (instancetype)myself;

@property (nonatomic) NSUInteger phoneNumber;

@end
