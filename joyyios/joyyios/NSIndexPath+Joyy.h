//
//  NSIndexPath+Joyy.h
//  joyyios
//
//  Created by Ping Yang on 9/4/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexPath (Joyy)

// Return the previous indexPath of self. If self is the first one, return nil
- (instancetype)previous;

@end
