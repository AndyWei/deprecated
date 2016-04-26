//
//  JYPostActionView.h
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYPost;

@protocol JYPostActionViewDelegate <NSObject>
- (void)view:(UIView *)view didLikePost:(JYPost *)post;
- (void)view:(UIView *)view didCommentPost:(JYPost *)post;
@end

@interface JYPostActionView : UIView
@property(nonatomic) JYPost *post;
@property(nonatomic, weak) id<JYPostActionViewDelegate> delegate;
@end
