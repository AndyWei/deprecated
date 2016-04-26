//
//  JYYearPickerView.m
//  joyyios
//
//  Created by Ping Yang on 12/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYYearPickerView.h"

@interface JYYearPickerView () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic) NSInteger minValue;
@property (nonatomic) NSInteger maxValue;
@property (nonatomic) NSInteger initValue;
@property (nonatomic) UIPickerView *pickerView;
@end


@implementation JYYearPickerView

- (instancetype)initWithFrame:(CGRect)frame maxValue:(NSInteger)max minValue:(NSInteger)min initValue:(NSInteger)init
{
    if (self = [super init])
    {
        NSAssert(min <= max, @"min must not greater than max");
        NSAssert(init >= min, @"init must not smaller than min");
        NSAssert(init <= max, @"init must not greater than max");

        self.minValue = min;
        self.maxValue = max;
        self.initValue = init;
        self.frame = frame;
        [self addSubview:self.pickerView];
        [self.pickerView selectRow:(init - min) inComponent:0 animated:NO];
    }
    return self;
}

#pragma mark - Property

- (UIPickerView *)pickerView
{
    if (!_pickerView)
    {
        CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
        _pickerView = [[UIPickerView alloc] initWithFrame:frame];
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
    }

    return _pickerView;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return (self.maxValue - self.minValue + 1);
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSInteger value = self.minValue + row;

    return [NSString stringWithFormat:@"%ld", (long)value];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return 200;
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pV didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSInteger value = self.minValue + row;
    if (self.delegate)
    {
        [self.delegate pickerView:self didSelectValue:value];
    }
}

@end
