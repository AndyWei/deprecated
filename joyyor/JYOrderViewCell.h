//
//  JYOrderViewCell.h
//  joyyor
//
//  Created by Ping Yang on 4/13/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <MCSwipeTableViewCell/MCSwipeTableViewCell.h>


@interface JYOrderViewCell : MCSwipeTableViewCell

+ (CGFloat)cellHeightForText:(NSString *)text;
- (void)presentOrder:(NSDictionary *)order;
- (void)updateCommentsCount:(NSUInteger)count;

@end
