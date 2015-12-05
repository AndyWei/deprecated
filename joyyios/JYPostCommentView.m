//
//  JYPostCommentView.m
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYComment.h"
#import "JYFriendManager.h"
#import "JYPostCommentView.h"
#import "NSDate+Joyy.h"

@interface JYPostCommentView ()
@property (nonatomic) NSMutableArray *commentLabels;
@end

@implementation JYPostCommentView

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = FlatGreen;

//        [self addSubview:self.likeButton];
//        [self addSubview:self.commentButton];
//
//        NSDictionary *views = @{
//                                @"commentButton": self.commentButton,
//                                @"likeButton": self.likeButton
//                                };
//
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[likeButton(40)]-40-[commentButton(40)]-10-|" options:0 metrics:nil views:views]];
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[commentButton]|" options:0 metrics:nil views:views]];
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[likeButton]|" options:0 metrics:nil views:views]];

    }
    return self;
}

//- (void)updateConstraints
//{
//    if (self.didSetupConstraints || [self.commentLabels count] == 0)
//    {
//        [super updateConstraints];
//        return;
//    }
//
//    // size
//    [self.commentLabels autoMatchViewsDimension:ALDimensionWidth];
//
//    // layout
//    // Loop over the labels, attaching the top edge to the previous label's bottom edge
//    [[self.commentLabels firstObject] autoPinEdgeToSuperviewEdge:ALEdgeLeft];
//    TTTAttributedLabel *previousLabel = nil;
//    for (TTTAttributedLabel *label in self.commentLabels) {
//        if (previousLabel) {
//            [label autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousLabel];
//        }
//        previousLabel = label;
//    }
//    [[self.commentLabels lastObject] autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//
//    self.didSetupConstraints = YES;
//    [super updateConstraints];
//}

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
        if (![comment isLike])
        {
            TTTAttributedLabel *label = [self _createCommentLabel];
            label.text = comment.displayText;
            [self.commentLabels addObject:label];
            [self addSubview:label];
        }
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
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:kFontSizeComment];
    label.textColor = JoyyBlack;
    label.backgroundColor = JoyyWhite;
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;

    return label;
}

@end
