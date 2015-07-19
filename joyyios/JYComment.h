//
//  JYComment.h
//  joyyios
//
//  Created by Ping Yang on 5/24/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@interface JYComment : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@property(nonatomic) NSUInteger commentId;
@property(nonatomic) NSUInteger mediaId;
@property(nonatomic) NSUInteger ownerId;
@property(nonatomic) BOOL isHost;
@property(nonatomic, readonly) NSString* contentString;

@end
