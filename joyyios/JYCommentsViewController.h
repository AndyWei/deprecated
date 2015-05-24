//
//  JYCommentsViewController.h
//  joyyios
//
//  Created by Ping Yang on 5/20/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "SLKTextViewController.h"

@interface JYCommentsViewController : SLKTextViewController

@property(nonatomic) NSInteger originalCommentIndex;

- (instancetype)initWithOrder:(NSDictionary *)order bid:(NSDictionary *)bid comments:(NSArray *)commentList;

@end
