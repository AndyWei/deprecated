//
//  JYAvatar.h
//  joyyios
//
//  Created by Ping Yang on 8/8/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYAvatar : NSObject 

+ (JYAvatar *)avatarOfCode:(uint64_t)code;

@property(nonatomic) UIColor *color;
@property(nonatomic) NSString *symbol;

@end
