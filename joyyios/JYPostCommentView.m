//
//  JYPostCommentView.m
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYComment.h"
#import "JYPostCommentView.h"
#import "NSDate+Joyy.h"

@interface JYPostCommentView ()
@property (nonatomic) BOOL didSetupConstraints;
@property (nonatomic) NSMutableArray *commentLabels;
@end

@implementation JYPostCommentView

+ (instancetype)newAutoLayoutView
{
    JYPostCommentView *view = [super newAutoLayoutView];
    view.backgroundColor = FlatGreen;
    return view;
}

- (void)updateConstraints
{
    if (self.didSetupConstraints || [self.commentLabels count] == 0)
    {
        [super updateConstraints];
        return;
    }

    // size
    [self.commentLabels autoMatchViewsDimension:ALDimensionWidth];

    // layout
    // Loop over the labels, attaching the top edge to the previous label's bottom edge
    [[self.commentLabels firstObject] autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    TTTAttributedLabel *previousLabel = nil;
    for (TTTAttributedLabel *label in self.commentLabels) {
        if (previousLabel) {
            [label autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousLabel];
        }
        previousLabel = label;
    }
    [[self.commentLabels lastObject] autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    self.didSetupConstraints = YES;
    [super updateConstraints];
}

- (void)setCommentList:(NSArray *)commentList
{
    if (!commentList)
    {
        return;
    }

    _commentList = commentList;
    [self _resetCommentlabels];

    for (JYComment *comment in commentList)
    {
        TTTAttributedLabel *label = [self _createCommentLabel];
        label.text = comment.displayText;
        [self.commentLabels addObject:label];
        [self addSubview:label];
    }
}

- (void)_resetCommentlabels
{
    for (TTTAttributedLabel *label in self.commentLabels)
    {
        [label removeFromSuperview];
    }

    self.commentLabels = [NSMutableArray new];
}

- (TTTAttributedLabel *)_createCommentLabel
{
    TTTAttributedLabel *label = [TTTAttributedLabel newAutoLayoutView];
    label.font = [UIFont systemFontOfSize:kFontSizeComment];
    label.textColor = JoyyBlack;
    label.backgroundColor = JoyyWhite;
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    return label;
}

@end
