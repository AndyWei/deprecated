//
//  JYUserView.h
//  joyyios
//
//  Created by Ping Yang on 11/26/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYUser;

@interface JYUserView : UIView

@property (nonatomic) BOOL hideDetail;
@property (nonatomic) JYUser *user;
@property (nonatomic) NSString *notificationName;

@end