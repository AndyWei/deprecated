//
//  JYPostCommentViewCell.m
//  joyyios
//
//  Created by Ping Yang on 12/5/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYPostCommentViewCell.h"

@interface JYPostCommentViewCell ()
@property(nonatomic) TTTAttributedLabel *commentLabel;
@end

@implementation JYPostCommentViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = JoyyWhiter;

        [self.contentView addSubview:self.commentLabel];

        NSDictionary *views = @{
                                @"commentLabel": self.commentLabel
                                };

        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[commentLabel]|" options:0 metrics:nil views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-3-[commentLabel]-0-|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.comment = nil;
}

- (void)setComment:(JYComment *)comment
{
    if (!comment)
    {
        self.commentLabel.text = nil;
        return;
    }

    _comment = comment;
    self.commentLabel.text = comment.displayText;
    self.commentLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.commentLabel.bounds);
}

- (TTTAttributedLabel *)commentLabel
{
    if (!_commentLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeComment];
        label.backgroundColor = ClearColor;
        label.textColor = JoyyBlack;
        label.textInsets = UIEdgeInsetsMake(0, 5, 0, 5);
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;

        _commentLabel = label;
    }
    return _commentLabel;
}

@end
