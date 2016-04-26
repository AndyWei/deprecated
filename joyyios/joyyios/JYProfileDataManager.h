//
//  JYProfileDataManager.h
//  joyyios
//
//  Created by Ping Yang on 1/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

@class JYProfileDataManager;

@protocol JYProfileDataManagerDelegate <NSObject>
- (void)manager:(JYProfileDataManager *)manager didReceiveFriends:(NSMutableArray *)list;
- (void)manager:(JYProfileDataManager *)manager didReceiveInvites:(NSMutableArray *)list;
- (void)manager:(JYProfileDataManager *)manager didReceivePosts:(NSMutableArray *)list;
- (void)manager:(JYProfileDataManager *)manager didReceiveWinks:(NSMutableArray *)list;
- (void)manager:(JYProfileDataManager *)manager didReceiveOwnProfile:(JYUser *)me;
@end


@interface JYProfileDataManager : NSObject

- (void)start;
- (void)fetchUserline;

@property (nonatomic, weak) id<JYProfileDataManagerDelegate> delegate;
@end
