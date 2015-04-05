//
//  JYMapDashBoardView.h
//  joyyios
//
//  Created by Ping Yang on 4/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@class JYMapDashBoardView;
@class MRoundedButton;

typedef NS_ENUM(NSUInteger, JYMapDashBoardStyle)
{
    JYMapDashBoardStyleStartOnly = 0,
    JYMapDashBoardStyleStartAndEnd
};

typedef NS_ENUM(NSUInteger, MapEditMode)
{
    MapEditModeNone = 0,
    MapEditModeStartPoint,
    MapEditModeEndPoint,
    MapEditModeDone
};

@protocol JYMapDashBoardViewDelegate <NSObject>

- (void)dashBoard:(JYMapDashBoardView *)dashBoard startButtonPressed:(MRoundedButton *)button;
- (void)dashBoard:(JYMapDashBoardView *)dashBoard endButtonPressed:(MRoundedButton *)button;
- (void)dashBoard:(JYMapDashBoardView *)dashBoard submitButtonPressed:(MRoundedButton *)button;

@end



@interface JYMapDashBoardView : UIView

- (id)initWithFrame:(CGRect)frame withStyle:(JYMapDashBoardStyle)style;

@property(nonatomic, weak) id<JYMapDashBoardViewDelegate> delegate;
@property(nonatomic) MapEditMode mapEditMode;
@property(nonatomic) MRoundedButton *startButton;
@property(nonatomic) MRoundedButton *endButton;
@property(nonatomic) MRoundedButton *submitButton;

@end
