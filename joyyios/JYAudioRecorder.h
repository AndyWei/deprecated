//
//  JYAudioRecorder.h
//  joyyios
//
//  Created by Ping Yang on 2/20/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

@class JYAudioRecorder;

@protocol JYAudioRecorderDelegate <NSObject>
- (void)recorder:(JYAudioRecorder *)recorder didRecordAudioFile:(NSURL *)fileURL duration:(NSTimeInterval)duration;
@end

@interface JYAudioRecorder: UIView

- (void)start;
- (void)stop;
- (void)cancel;

@property (nonatomic, weak) id<JYAudioRecorderDelegate> delegate;
@property (nonatomic) UIScrollView *scrollView;
@end
