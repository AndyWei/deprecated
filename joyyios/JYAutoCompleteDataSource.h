//
//  JYAutoCompleteDataSource.h
//  joyyios
//
//  Created by Ping Yang on 3/27/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "HTAutocompleteTextField.h"

typedef enum {
    JYAutoCompleteTypeEmail, // Default
    JYAutoCompleteTypeColor,
} JYAutoCompleteType;

@interface JYAutoCompleteDataSource : NSObject <HTAutocompleteDataSource>

+ (JYAutoCompleteDataSource *)sharedDataSource;

@end