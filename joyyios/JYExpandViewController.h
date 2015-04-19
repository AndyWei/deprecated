//
//  JYWaxViewController.h
//  joyyios
//
//  Created by Ping Yang on 4/7/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@interface JYExpandViewController : UIViewController <UIScrollViewDelegate>

@property(nonatomic, weak) UIScrollView *scrollView;

- (void)setTitleText:(NSString *)text;
- (void)resetNavigationBar:(BOOL)animated;

@end
