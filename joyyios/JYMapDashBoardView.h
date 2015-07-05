//
//  JYMapDashBoardView.h
//  joyyios
//
//  Created by Ping Yang on 4/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@class JYMapDashBoardView;
@class JYButton;

@protocol JYMapDashBoardViewDelegate <NSObject>

- (void)didPressLocateButton;
- (void)didSelectSegment:(NSInteger)index;

@end



@interface JYMapDashBoardView : UIView

- (instancetype)initWithFrame:(CGRect)frame;

@property(nonatomic) BOOL hidden;

@property(nonatomic, weak) id<JYMapDashBoardViewDelegate> delegate;
@property(nonatomic, weak) JYButton *locateButton;

@end
