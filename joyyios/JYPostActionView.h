//
//  JYPostActionView.h
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYPost;

@interface JYPostActionView : UIView

+ (instancetype)newAutoLayoutView;

@property(nonatomic) JYPost *post;

@end
