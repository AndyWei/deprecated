//
//  JYCommentViewCell.m
//  joyyios
//
//  Created by Ping Yang on 5/14/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYCommentView.h"
#import "JYCommentViewCell.h"

@interface JYCommentViewCell ()
@property(nonatomic) JYCommentView *commentView;
@end

@implementation JYCommentViewCell

+ (CGFloat)heightForComment:(JYComment *)comment
{
    return [JYCommentView heightForComment:comment];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = ClearColor;
    }
    return self;
}

- (void)setComment:(JYComment *)comment
{
    self.commentView.comment = comment;
}

- (JYCommentView *)commentView
{
    if (!_commentView)
    {
        CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, CGRectGetHeight(self.frame));
        _commentView = [[JYCommentView alloc] initWithFrame:frame];
        [self addSubview:_commentView];
    }
    return _commentView;
}

@end
