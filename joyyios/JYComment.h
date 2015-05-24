//
//  JYComment.h
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@interface JYComment : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSString *)contentString;

@property(nonatomic) NSUInteger commentId;
@property(nonatomic) NSUInteger orderId;
@property(nonatomic) NSUInteger userId;

@property(nonatomic, copy) NSString* body;
@property(nonatomic, copy) NSString* username;

@end
