//
//  JYAutoCompleteDataSource.h
//  joyyios
//
//  Created by Ping Yang on 3/27/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYAutoCompleteTextField.h"

@interface JYAutoCompleteDataSource : NSObject <JYAutoCompleteDataSourceDelegate>

+ (JYAutoCompleteDataSource *)sharedDataSource;

@end