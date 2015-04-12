//
//  JYPriceTextFieldCell.m
//  joyyios
//
//  Created by Ping Yang on 4/11/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPriceTextFieldCell.h"
#import "NSObject+XLFormAdditions.h"
#import "UIView+XLFormAdditions.h"
#import "XLFormRowDescriptor.h"

NSString *const XLFormRowDescriptorTypePrice = @"XLFormRowDescriptorTypePrice";

@interface JYPriceTextFieldCell () <UITextFieldDelegate>

@property NSArray *dynamicCustomConstraints;
@property UIReturnKeyType returnKeyType;

@end

@implementation JYPriceTextFieldCell

@synthesize textField = _textField;
@synthesize textLabel = _textLabel;

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == self.textLabel && [keyPath isEqualToString:@"text"]) || (object == self.imageView && [keyPath isEqualToString:@"image"]))
    {
        if ([[change objectForKey:NSKeyValueChangeKindKey] isEqualToNumber:@(NSKeyValueChangeSetting)])
        {
            [self.contentView setNeedsUpdateConstraints];
        }
    }
}

- (void)dealloc
{
    [self.textLabel removeObserver:self forKeyPath:@"text"];
    [self.imageView removeObserver:self forKeyPath:@"image"];
}

#pragma mark - XLFormDescriptorCell

+ (void)load
{
    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:[JYPriceTextFieldCell class] forKey:XLFormRowDescriptorTypePrice];
}

- (void)configure
{
    [super configure];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self.contentView addSubview:self.textLabel];
    [self.contentView addSubview:self.textField];
    [self.contentView addConstraints:[self layoutConstraints]];
    [self.textLabel addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:0];
    [self.imageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:0];
    [self.textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)update
{
    [super update];
    self.textField.delegate = self;
    self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.textField.keyboardType = UIKeyboardTypeNumberPad;

    self.textLabel.text = ((self.rowDescriptor.required && self.rowDescriptor.title &&
                            self.rowDescriptor.sectionDescriptor.formDescriptor.addAsteriskToRequiredRowsTitle)
                               ? [NSString stringWithFormat:@"%@*", self.rowDescriptor.title]
                               : self.rowDescriptor.title);

    self.textField.text = self.rowDescriptor.value ? [self.rowDescriptor.value displayText] : self.rowDescriptor.noValueDisplayText;
    [self.textField setEnabled:!self.rowDescriptor.isDisabled];
    self.textField.textColor = self.rowDescriptor.isDisabled ? [UIColor grayColor] : [UIColor blackColor];
    self.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (BOOL)formDescriptorCellCanBecomeFirstResponder
{
    return (!self.rowDescriptor.isDisabled);
}

- (BOOL)formDescriptorCellBecomeFirstResponder
{
    return [self.textField becomeFirstResponder];
}

- (void)highlight
{
    [super highlight];
    self.textLabel.textColor = self.tintColor;
}

- (void)unhighlight
{
    [super unhighlight];
    [self.formViewController updateFormRow:self.rowDescriptor];
}

#pragma mark - Properties

- (UILabel *)textLabel
{
    if (_textLabel)
        return _textLabel;
    _textLabel = [UILabel autolayoutView];
    return _textLabel;
}

- (UITextField *)textField
{
    if (_textField)
    {
        return _textField;
    }

    _textField = [UITextField autolayoutView];
    return _textField;
}

#pragma mark - LayoutConstraints

- (NSArray *)layoutConstraints
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [self.textLabel setContentHuggingPriority:500 forAxis:UILayoutConstraintAxisHorizontal];
    [result addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_textLabel]-[_textField]"
                                                                        options:NSLayoutFormatAlignAllBaseline
                                                                        metrics:0
                                                                          views:NSDictionaryOfVariableBindings(_textLabel, _textField)]];

    [result addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=11)-[_textField]-(>=11)-|"
                                                                        options:NSLayoutFormatAlignAllBaseline
                                                                        metrics:nil
                                                                          views:NSDictionaryOfVariableBindings(_textField)]];

    [result addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=11)-[_textLabel]-(>=11)-|"
                                                                        options:NSLayoutFormatAlignAllBaseline
                                                                        metrics:nil
                                                                          views:NSDictionaryOfVariableBindings(_textLabel)]];
    return result;
}

- (void)updateConstraints
{
    if (self.dynamicCustomConstraints)
    {
        [self.contentView removeConstraints:self.dynamicCustomConstraints];
    }
    NSDictionary *views = @{ @"label" : self.textLabel, @"textField" : self.textField, @"image" : self.imageView };
    NSDictionary *metrics = @{ @"leftMargin" : @16.0, @"rightMargin" : self.textField.textAlignment == NSTextAlignmentRight ? @16.0 : @4.0 };

    if (self.imageView.image)
    {
        if (self.textLabel.text.length > 0)
        {
            self.dynamicCustomConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[image]-[label]-[textField]-(rightMargin)-|"
                                                                                    options:0
                                                                                    metrics:metrics
                                                                                      views:views];
        }
        else
        {
            self.dynamicCustomConstraints =
                [NSLayoutConstraint constraintsWithVisualFormat:@"H:[image]-[textField]-(rightMargin)-|" options:0 metrics:metrics views:views];
        }
    }
    else
    {
        if (self.textLabel.text.length > 0)
        {
            self.dynamicCustomConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(leftMargin)-[label]-[textField]-(rightMargin)-|"
                                                                                    options:0
                                                                                    metrics:metrics
                                                                                      views:views];
        }
        else
        {
            self.dynamicCustomConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(leftMargin)-[textField]-(rightMargin)-|"
                                                                                    options:0
                                                                                    metrics:metrics
                                                                                      views:views];
        }
    }
    [self.contentView addConstraints:self.dynamicCustomConstraints];
    [super updateConstraints];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return [self.formViewController textFieldShouldClear:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return [self.formViewController textFieldShouldReturn:textField];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return [self.formViewController textFieldShouldBeginEditing:textField];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return [self.formViewController textFieldShouldEndEditing:textField];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return [self.formViewController textField:textField shouldChangeCharactersInRange:range replacementString:string];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.formViewController beginEditing:self.rowDescriptor];
    [self.formViewController textFieldDidBeginEditing:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self textFieldDidChange:textField];
    [self.formViewController endEditing:self.rowDescriptor];
    [self.formViewController textFieldDidEndEditing:textField];
}

#pragma mark - Helper

- (void)textFieldDidChange:(UITextField *)textField
{
    if ([self.textField.text length] > 0)
    {
        self.rowDescriptor.value = self.textField.text;
    }
    else
    {
        self.rowDescriptor.value = nil;
    }
}

- (void)setReturnKeyType:(UIReturnKeyType)returnKeyType
{
    self.textField.returnKeyType = returnKeyType;
}

- (UIReturnKeyType)returnKeyType
{
    return self.textField.returnKeyType;
}

@end
