//
//  JYMediaViewCell.h
//  joyyios
//
//  Created by Ping Yang on 7/12/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

@class JYMedia;

@interface JYMediaViewCell : UITableViewCell

+ (CGFloat)heightForMedia:(JYMedia *)media;

@property(nonatomic, weak) JYMedia *media;

@end
