//
//  JYRestrictedTextViewCell.h
//  joyyios
//
//  Created by Ping Yang on 4/11/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "XLFormBaseCell.h"
#import "XLFormTextView.h"

extern NSString *const XLFormRowDescriptorTypeTextViewRestricted;

@interface JYRestrictedTextViewCell : XLFormBaseCell

@property(nonatomic, readonly) UILabel *textLabel;
@property(nonatomic, readonly) XLFormTextView *textView;

@end
