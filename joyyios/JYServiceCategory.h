//
//  JYServiceCategory.h
//  joyyios
//
//  Created by Ping Yang on 4/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

typedef NS_ENUM(NSUInteger, JYServiceCategoryIndex)
{
    JYServiceCategoryIndexCleaning = 0,
    JYServiceCategoryIndexDelivery,
    JYServiceCategoryIndexElectrical,
    JYServiceCategoryIndexHandyman,
    JYServiceCategoryIndexMoving,
    JYServiceCategoryIndexPersonalAssistant,
    JYServiceCategoryIndexPlumbing,
    JYServiceCategoryIndexOther
};

@interface JYServiceCategory : NSObject

+ (NSArray *)names;
+ (NSUInteger)categoryAtIndex:(JYServiceCategoryIndex)index;
+ (JYServiceCategoryIndex)indexOfCategory:(NSUInteger)category;

@end
