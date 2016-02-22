//
//  JYMessageIncomingCell.m
//  joyyios
//
//  Created by Ping Yang on 2/15/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYMessageTextCell.h"

@implementation JYMessageTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self.contentView addSubview:self.contentLabel];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.contentLabel.text = nil;
}

- (void)setMessage:(JYMessage *)message
{
    [super setMessage:message];

    if ([message.isOutgoing boolValue])
    {
        self.contentLabel.textColor = JoyyWhitePure;
        self.contentLabel.backgroundColor = JoyyBlue;
    }
    else
    {
        self.contentLabel.textColor = JoyyBlack;
        self.contentLabel.backgroundColor = rgb(255, 239, 213);
    }

    self.contentLabel.text = [message text];
    [self.contentLabel sizeToFit];
}

- (TTTAttributedLabel *)contentLabel
{
    if (!_contentLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:16];
        label.textAlignment = NSTextAlignmentLeft;
        label.textInsets = UIEdgeInsetsMake(8, 8, 8, 8);
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.preferredMaxLayoutWidth = SCREEN_WIDTH - 130;
        label.layer.cornerRadius = 6;
        label.layer.masksToBounds = YES;

        _contentLabel = label;
    }
    return _contentLabel;
}

@end
