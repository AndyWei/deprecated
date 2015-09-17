//
//  JYFacialGestureDetector.h
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@import ImageIO;

@class JYFacialGestureDetector;

@protocol JYFacialGuestureDetectorDelegate <NSObject>

@required
- (BOOL)isListening;

@optional
- (void)detectorDidDetectSmile:(JYFacialGestureDetector *)detector;
- (void)detectorDidDetectBlink:(JYFacialGestureDetector *)detector;
- (void)detectorDidDetectLeftWink:(JYFacialGestureDetector *)detector;
- (void)detectorDidDetectRightWink:(JYFacialGestureDetector *)detector;

@end


@interface JYFacialGestureDetector : NSObject

- (void)startDetectionWithError:(NSError **)error;
- (void)stopDetection;

@property (nonatomic) CFTimeInterval reportingPeriod;
@property (nonatomic) BOOL detectSmile;
@property (nonatomic) BOOL detectBlink;
@property (nonatomic) BOOL detectLeftWink;
@property (nonatomic) BOOL detectRightWink;
@property (nonatomic, weak) id<JYFacialGuestureDetectorDelegate> delegate;
@property (nonatomic, weak) UIView *previewView;

@end
