//
//  JYUserBaseCell.h
//  joyyios
//
//  Created by Ping Yang on 1/5/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYButton.h"
#import "JYUserView.h"

@class JYUser, JYUserBaseCell;

@protocol JYUserBaseCellDelegate <NSObject>
- (void)didTapActionButtonOnCell:(JYUserBaseCell *)cell;
@end

@interface JYUserBaseCell : UITableViewCell

@property (nonatomic) JYUser *user;
@property (nonatomic) JYButton *actionButton;
@property (nonatomic) JYUserView *userView;
@property (nonatomic, weak) id<JYUserBaseCellDelegate> delegate;

@end
