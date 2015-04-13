//
//  JYRestrictedTextViewCell.m
//  joyyios
//
//  Created by Ping Yang on 4/11/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYRestrictedTextViewCell.h"
#import "UIView+XLFormAdditions.h"
#import "XLFormRowDescriptor.h"
#import "XLFormViewController.h"
#import "XLFormTextView.h"

NSString *const XLFormRowDescriptorTypeTextViewRestricted = @"XLFormRowDescriptorTypeTextViewRestricted";

@interface JYRestrictedTextViewCell () <UITextViewDelegate>

@end



@implementation JYRestrictedTextViewCell

@synthesize textLabel = _textLabel;
@synthesize textView = _textView;


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.textLabel && [keyPath isEqualToString:@"text"])
    {
        if ([[change objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:@(NSKeyValueChangeSetting)])
        {
            [self needsUpdateConstraints];
        }
    }
}

- (void)dealloc
{
    [self.textLabel removeObserver:self forKeyPath:@"text"];
}

#pragma mark - Properties

- (UILabel *)textLabel
{
    if (_textLabel)
    {
        return _textLabel;
    }
    _textLabel = [UILabel autolayoutView];
    [_textLabel setContentHuggingPriority:500 forAxis:UILayoutConstraintAxisHorizontal];
    return _textLabel;
}

- (XLFormTextView *)textView
{
    if (_textView)
    {
        return _textView;
    }

    _textView = [XLFormTextView autolayoutView];
    return _textView;
}

#pragma mark - XLFormDescriptorCell

+ (void)load
{
    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:[JYRestrictedTextViewCell class] forKey:XLFormRowDescriptorTypeTextViewRestricted];
}

- (void)configure
{
    [super configure];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self.contentView addSubview:self.textView];
    [self.textView addSubview:self.textLabel];
    [self.textLabel addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:0];
    NSDictionary *views = @{ @"label" : self.textLabel, @"textView" : self.textView };
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.textView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1
                                                                  constant:0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.textView
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1
                                                                  constant:0]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[textView]-0-|" options:0 metrics:0 views:views]];
    [self.textView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-130-[label]-8-|" options:0 metrics:0 views:views]];
}

- (void)update
{
    [super update];
    self.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.textView.placeHolderLabel.font = self.textView.font;
    self.textView.delegate = self;
    self.textView.keyboardType = UIKeyboardTypeDefault;
    if (self.rowDescriptor.value != [NSNull null])
    {
        self.textView.text = self.rowDescriptor.value;
    }
    [self.textView setEditable:!self.rowDescriptor.isDisabled];
    self.textView.textColor = self.rowDescriptor.isDisabled ? [UIColor grayColor] : [UIColor blackColor];
    self.textLabel.textColor = [UIColor whiteColor];
    self.textLabel.text = self.rowDescriptor.title;
}

+ (CGFloat)formDescriptorCellHeightForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor
{
    return 155.f;
}

- (BOOL)formDescriptorCellCanBecomeFirstResponder
{
    return (!self.rowDescriptor.isDisabled);
}

- (BOOL)formDescriptorCellBecomeFirstResponder
{
    return [self.textView becomeFirstResponder];
}

- (void)highlight
{
    [super highlight];
    self.textLabel.textColor = [UIColor lightGrayColor];
}

- (void)unhighlight
{
    [super unhighlight];
    [self.formViewController updateFormRow:self.rowDescriptor];
    self.textLabel.textColor = [UIColor whiteColor];
}

#pragma mark - Constraints

- (void)updateConstraints
{
    NSDictionary *views = @{ @"label" : self.textLabel, @"textView" : self.textView };

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[textView]-8-|" options:0 metrics:0 views:views]];
    if (self.textLabel.text && ![self.textLabel.text isEqualToString:@""])
    {
        [self.textView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-320-[label]-|" options:0 metrics:0 views:views]];
    }
    [super updateConstraints];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self.formViewController beginEditing:self.rowDescriptor];
    return [self.formViewController textViewDidBeginEditing:textView];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([self.textView.text length] > 0)
    {
        self.rowDescriptor.value = self.textView.text;
    }
    else
    {
        self.rowDescriptor.value = nil;
    }
    [self.formViewController endEditing:self.rowDescriptor];
    [self.formViewController textViewDidEndEditing:textView];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return [self.formViewController textViewShouldBeginEditing:textView];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if ([self.textView.text length] > 0)
    {
        self.rowDescriptor.value = self.textView.text;

        NSUInteger lengLimit = [self.rowDescriptor.title integerValue];
        NSInteger left = lengLimit - [self.textView.text length];
        self.textLabel.text = [@(left) stringValue];;
    }
    else
    {
        self.rowDescriptor.value = nil;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text
{
    NSUInteger lengLimit = [self.rowDescriptor.title integerValue];
    NSString * newText = [[textView text] stringByReplacingCharactersInRange:range withString:text];
    return (newText.length <= lengLimit);
}

@end
