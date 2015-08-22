//
//  JYCommentView.h
//  joyyios
//
//  Created by Ping Yang on 8/6/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYComment.h"

@interface JYCommentView : UIView

+ (CGFloat)heightForComment:(JYComment *)comment;
+ (CGFloat)heightForText:(NSString *)text;

@property(nonatomic) JYComment *comment;
@property(nonatomic) NSString *caption;

@end
