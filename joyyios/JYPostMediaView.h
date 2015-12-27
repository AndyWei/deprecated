//
//  JYMediaView.h
//  joyyios
//
//  Created by Ping Yang on 11/30/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYPost;

@protocol JYPostMediaViewDelegate <NSObject>
- (void)view:(UIView *)view didTapOnPost:(JYPost *)post;
@end


@interface JYPostMediaView : UIView
@property(nonatomic) JYPost *post;
@property(nonatomic, weak) id<JYPostMediaViewDelegate> delegate;
@end
