//
//  JYCommentViewCell.h
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@interface JYCommentViewCell : UITableViewCell

+ (CGFloat)cellHeightForText:(NSString *)text;

@property(nonatomic) UILabel *commentLabel;

@end
