//
//  JYYearPickerView.h
//  joyyios
//
//  Created by Ping Yang on 12/29/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYYearPickerView;

@protocol JYYearPickerViewDelegate <NSObject>
- (void)pickerView:(JYYearPickerView *)view didSelectValue:(NSInteger)value;
@end


@interface JYYearPickerView : UIView
- (instancetype)initWithFrame:(CGRect)frame maxValue:(NSInteger)max minValue:(NSInteger)min initValue:(NSInteger)init;
@property (nonatomic, weak) id<JYYearPickerViewDelegate> delegate;
@end
