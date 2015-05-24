//
//  JYBid.h
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@interface JYBid : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSString *)expireTimeString;

@property(nonatomic) NSInteger  status;
@property(nonatomic) NSUInteger bidId;
@property(nonatomic) NSUInteger orderId;
@property(nonatomic) NSUInteger userId;
@property(nonatomic) NSUInteger price;
@property(nonatomic) NSUInteger expireTime;

@property(nonatomic, copy) NSString*  note;

@end
