//
//  JYTimelineCell.h
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@class JYPost;
@class JYTimelineCell;

@protocol JYTimelineCellDelegate <NSObject>
- (void)cell:(JYTimelineCell *)cell didTapOnPost:(JYPost *)post;
- (void)cell:(JYTimelineCell *)cell didLikePost:(JYPost *)post;
- (void)cell:(JYTimelineCell *)cell didCommentPost:(JYPost *)post;
@end

@interface JYTimelineCell : UITableViewCell
@property(nonatomic) JYPost *post;
@property(nonatomic) id<JYTimelineCellDelegate> delegate;
@end
