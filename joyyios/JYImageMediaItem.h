//
//  JYImageMediaItem.h
//  joyyios
//
//  Created by Ping Yang on 2/8/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JSQMediaItem.h"

@interface JYImageMediaItem : JSQMediaItem <JSQMessageMediaData, NSCoding, NSCopying>

- (instancetype)initWithURL:(NSString *)url;

@property (nonatomic) NSString *url;
@property (nonatomic) UIImage *image;

@end
