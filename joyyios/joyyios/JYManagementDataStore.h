//
//  JYManagementDataStore.h
//  joyyios
//
//  Created by Ping Yang on 3/30/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYManagementDataStore : NSObject

+ (JYManagementDataStore *)sharedInstance;

@property (nonatomic) BOOL didShowIntroduction;
@property (nonatomic) BOOL didShowFeedsViewTips;
@property (nonatomic) BOOL didShowPeopleViewTips;
@property (nonatomic) BOOL needQueryContacts;
@end
