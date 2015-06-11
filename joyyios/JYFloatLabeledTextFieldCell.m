//
//  JYFloatLabeledTextFieldCell.m
//  joyyios
//
//  Created by Ping Yang on 5/31/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYFloatLabeledTextFieldCell.h"
#import "UIView+XLFormAdditions.h"
#import "JYFloatLabeledTextField.h"
#import "NSObject+XLFormAdditions.h"


NSString * const XLFormRowDescriptorTypeFloatLabeledInteger = @"XLFormRowDescriptorTypeFloatLabeledInteger";
NSString * const XLFormRowDescriptorTypeFloatLabeledName    = @"XLFormRowDescriptorTypeFloatLabeledName";
NSString * const XLFormRowDescriptorTypeFloatLabeledText    = @"XLFormRowDescriptorTypeFloatLabeledText";
NSString * const XLFormRowDescriptorTypeFloatLabeledSSN     = @"XLFormRowDescriptorTypeFloatLabeledSSN";
NSString * const XLFormRowDescriptorTypeFloatLabeledZipcode = @"XLFormRowDescriptorTypeFloatLabeledZipcode";

const static CGFloat kHMargin = 15.0f;
const static CGFloat kVMargin = 8.0f;
const static CGFloat kFloatingLabelFontSize = 11.0f;
const static CGFloat kTextFieldFontSize = 18.0f;

@interface JYFloatLabeledTextFieldCell () <UITextFieldDelegate>
@property (nonatomic) JYFloatLabeledTextField * floatLabeledTextField;
@end

@implementation JYFloatLabeledTextFieldCell

@synthesize floatLabeledTextField =_floatLabeledTextField;

+(void)load
{
    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:[JYFloatLabeledTextFieldCell class] forKey:XLFormRowDescriptorTypeFloatLabeledInteger];

    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:[JYFloatLabeledTextFieldCell class] forKey:XLFormRowDescriptorTypeFloatLabeledName];

    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:[JYFloatLabeledTextFieldCell class] forKey:XLFormRowDescriptorTypeFloatLabeledText];

    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:[JYFloatLabeledTextFieldCell class] forKey:XLFormRowDescriptorTypeFloatLabeledSSN];

    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:[JYFloatLabeledTextFieldCell class] forKey:XLFormRowDescriptorTypeFloatLabeledZipcode];
}

-(JYFloatLabeledTextField *)floatLabeledTextField
{
    if (_floatLabeledTextField) return _floatLabeledTextField;

    _floatLabeledTextField = [JYFloatLabeledTextField autolayoutView];
    _floatLabeledTextField.font = [UIFont systemFontOfSize:kTextFieldFontSize];
    _floatLabeledTextField.floatingLabel.font = [UIFont boldSystemFontOfSize:kFloatingLabelFontSize];

    _floatLabeledTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    return _floatLabeledTextField;
}

#pragma mark - XLFormDescriptorCell

-(void)configure
{
    [super configure];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self.contentView addSubview:self.floatLabeledTextField];
    [self.floatLabeledTextField setDelegate:self];
    [self.contentView addConstraints:[self layoutConstraints]];
}

-(void)update
{
    [super update];

    if ([self.rowDescriptor.rowType isEqualToString:XLFormRowDescriptorTypeFloatLabeledText])
    {
        self.floatLabeledTextField.autocorrectionType = UITextAutocorrectionTypeDefault;
        self.floatLabeledTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        self.floatLabeledTextField.keyboardType = UIKeyboardTypeDefault;
    }
    else if ([self.rowDescriptor.rowType isEqualToString:XLFormRowDescriptorTypeFloatLabeledName])
    {
        self.floatLabeledTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.floatLabeledTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.floatLabeledTextField.keyboardType = UIKeyboardTypeDefault;
    }
    else
    {
        self.floatLabeledTextField.keyboardType = UIKeyboardTypeNumberPad;
    }

    self.floatLabeledTextField.attributedPlaceholder =
    [[NSAttributedString alloc] initWithString:self.rowDescriptor.title
                                    attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];

    self.floatLabeledTextField.text = self.rowDescriptor.value ? [self.rowDescriptor.value displayText] : self.rowDescriptor.noValueDisplayText;
    [self.floatLabeledTextField setEnabled:!self.rowDescriptor.disabled];

    self.floatLabeledTextField.floatingLabelTextColor = [UIColor grayColor];

    [self.floatLabeledTextField setAlpha:((self.rowDescriptor.isDisabled) ? .6 : 1)];
}

-(BOOL)formDescriptorCellCanBecomeFirstResponder
{
    return (!self.rowDescriptor.disabled);
}

-(BOOL)formDescriptorCellBecomeFirstResponder
{
    return [self.floatLabeledTextField becomeFirstResponder];
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
    if (self.floatLabeledTextField == textField)
    {
        NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        self.rowDescriptor.value = newText.length > 0 ? newText : nil;
    }
    return [self.formViewController textField:textField shouldChangeCharactersInRange:range replacementString:string];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.formViewController textFieldDidBeginEditing:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self textFieldDidChange:textField];
    [self.formViewController textFieldDidEndEditing:textField];
}

-(void)setReturnKeyType:(UIReturnKeyType)returnKeyType
{
    self.floatLabeledTextField.returnKeyType = returnKeyType;
}

-(UIReturnKeyType)returnKeyType
{
    return self.floatLabeledTextField.returnKeyType;
}

+(CGFloat)formDescriptorCellHeightForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor {
    return 55;
}



-(NSArray *)layoutConstraints
{
    NSMutableArray * result = [[NSMutableArray alloc] init];

    NSDictionary * views = @{@"floatLabeledTextField": self.floatLabeledTextField};
    NSDictionary *metrics = @{@"hMargin":@(kHMargin),
                              @"vMargin":@(kVMargin)};

    [result addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(hMargin)-[floatLabeledTextField]-(hMargin)-|"
                                                                        options:0
                                                                        metrics:metrics
                                                                          views:views]];
    [result addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(vMargin)-[floatLabeledTextField]-(vMargin)-|"
                                                                        options:0
                                                                        metrics:metrics
                                                                          views:views]];
    return result;
}

#pragma mark - Helpers

- (void)textFieldDidChange:(UITextField *)textField
{
    if (self.floatLabeledTextField == textField)
    {
        if (self.floatLabeledTextField.text.length > 0)
        {
            self.rowDescriptor.value = self.floatLabeledTextField.text;
        }
        else
        {
            self.rowDescriptor.value = nil;
        }
    }
}



@end
