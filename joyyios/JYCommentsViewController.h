//
//  JYCommentsViewController.h
//  joyyios
//
//  Created by Ping Yang on 5/20/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@interface JYCommentsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, copy) NSDictionary *originalComment;

- (instancetype)initWithOrder:(NSDictionary *)order bid:(NSDictionary *)bid comments:(NSArray *)commentList;

@end
