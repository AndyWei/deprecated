//
//  JYAutoCompleteDataSource.h
//  joyyios
//
//  Created by Ping Yang on 3/27/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYAutocompleteTextField.h"

@interface JYAutoCompleteDataSource : NSObject <JYAutocompleteDataSource>

+ (JYAutoCompleteDataSource *)sharedDataSource;

@end