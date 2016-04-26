//
//  JYRefreshHeader.h
//  joyyios
//
//  Created by Ping Yang on 12/21/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import "JYJellyView.h"
#import "MJRefreshHeader.h"

@class JYRefreshHeader;
@protocol JYRefreshHeaderDelegate <NSObject>
- (void)refreshHeader:(JYRefreshHeader *)header willResetJellyView:(JYJellyView *)jellyView;
@end

@interface JYRefreshHeader : MJRefreshHeader

@property (nonatomic, weak) JYJellyView *jellyView;
@property (nonatomic, weak) id<JYRefreshHeaderDelegate> delegate;

@end
