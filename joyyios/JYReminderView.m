//
//  JYReminderView.m
//  joyyios
//
//  Created by Ping Yang on 12/15/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//


#import <TTTAttributedLabel/TTTAttributedLabel.h>

#import "JYReminderView.h"

@interface JYReminderView () <TTTAttributedLabelDelegate>
@property (nonatomic) TTTAttributedLabel *reminderLabel;
@end

static NSString *kActionURL = @"action://_didTapReminderLabel";

@implementation JYReminderView

- (instancetype)init
{
    if (self = [super init])
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.reminderLabel];

        NSDictionary *views = @{
                                @"reminderLabel": self.reminderLabel
                                };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=100@500)-[reminderLabel]-(>=100@500)-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[reminderLabel]-10-|" options:0 metrics:nil views:views]];

        NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:self.reminderLabel
                                     attribute:NSLayoutAttributeCenterX
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeCenterX
                                    multiplier:1.f constant:0.f];
        [self addConstraint:centerConstraint];
    }
    return self;
}

- (void)setText:(NSString *)text
{
    _text = text;

    NSString *displayText = [NSString stringWithFormat:@"%@   >", text];
    self.reminderLabel.text = displayText;

    // add link to make the label clickable
    NSRange range = [displayText rangeOfString:displayText];
    [self.reminderLabel addLinkToURL:[NSURL URLWithString:kActionURL] withRange:range];
}

- (TTTAttributedLabel *)reminderLabel
{
    if (!_reminderLabel)
    {
        TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.delegate = self;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [UIFont systemFontOfSize:kFontSizeCaption];
        label.backgroundColor = JoyyBlue;
        label.textColor = JoyyWhitePure;
        label.textInsets = UIEdgeInsetsMake(5, 10, 5, 10);
        label.layer.cornerRadius = 4;
        label.layer.masksToBounds = YES;

        label.linkAttributes = @{
                                 (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyWhite.CGColor),
                                 (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                 };
        label.activeLinkAttributes = @{
                                       (NSString*)kCTForegroundColorAttributeName: (__bridge id)(JoyyBlue.CGColor),
                                       (NSString *)kCTUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                       };
        _reminderLabel = label;
    }
    return _reminderLabel;
}

#pragma mark -- TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([kActionURL isEqualToString:[url absoluteString]])
    {
        NSDictionary *info = @{@"text": self.text};
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidTapReminderView object:nil userInfo:info];
    }
}

@end
