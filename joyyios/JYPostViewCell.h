//
//  JYPostViewCell.h
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@class JYPost;

@interface JYPostViewCell : UITableViewCell

+ (CGFloat)heightForPost:(JYPost *)post;

@property(nonatomic) JYPost *post;

@end
