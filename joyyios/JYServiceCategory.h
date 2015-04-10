//
//  JYServiceCategory.h
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

typedef NS_ENUM(NSUInteger, JYServiceCategoryIndex)
{
    JYServiceCategoryIndexRoadsideAssistance = 0,
    JYServiceCategoryIndexRide,
    JYServiceCategoryIndexMoving,
    JYServiceCategoryIndexDelivery,
    JYServiceCategoryIndexPlumbing,
    JYServiceCategoryIndexCleaning,
    JYServiceCategoryIndexHandyman,
    JYServiceCategoryIndexGardener,
    JYServiceCategoryIndexPersonalAssistant,
    JYServiceCategoryIndexOther
};

@interface JYServiceCategory : NSObject

+ (NSArray *)names;
+ (NSUInteger)categoryAtIndex:(NSUInteger)index;
+ (Class)classAtIndex:(NSUInteger)index;

@end
