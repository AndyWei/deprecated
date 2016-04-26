//
//  JYMessageOutgoingCell.h
//  joyyios
//
//  Created by Ping Yang on 2/15/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import "JYAudioPlayer.h"
#import "JYMessageCell.h"

@interface JYMessageMediaCell : JYMessageCell

@property (nonatomic) JYAudioPlayer *audioPlayer;
@property (nonatomic) UIView *mediaContainerView;
@property (nonatomic) UIImageView *contentImageView;

@end
