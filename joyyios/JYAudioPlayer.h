//
//  JYAudioPlayer.h
//  joyyios
//
//  Created by Ping Yang on 2/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <TTTAttributedLabel/TTTAttributedLabel.h>

@interface JYAudioPlayer : UIControl

@property (nonatomic) NSURL *url;
@property (nonatomic) TTTAttributedLabel *textLabel;
@property (nonatomic) UIImageView *imageView;

@end
