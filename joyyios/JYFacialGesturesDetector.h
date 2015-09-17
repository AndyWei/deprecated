//
//  JYFacialDetector.h
//  joyyios
//
//  Created by Ping Yang on 9/15/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@import ImageIO;

@class JYFacialGesturesDetector;

@protocol JYFacialDetectorDelegate <NSObject>

@required
- (BOOL)isListening;

@optional
- (void)detectorDidDetectSmile:(JYFacialGesturesDetector *)detector;
- (void)detectorDidDetectBlink:(JYFacialGesturesDetector *)detector;
- (void)detectorDidDetectLeftWink:(JYFacialGesturesDetector *)detector;
- (void)detectorDidDetectRightWink:(JYFacialGesturesDetector *)detector;

@end


@interface JYFacialGesturesDetector : NSObject

- (void)startDetectionWithError:(NSError **)error;
- (void)stopDetection;

@property (nonatomic) BOOL detectSmile;
@property (nonatomic) BOOL detectBlink;
@property (nonatomic) BOOL detectLeftWink;
@property (nonatomic) BOOL detectRightWink;
@property (nonatomic, readonly) CIImage *currentImage;
@property (nonatomic, weak) id<JYFacialDetectorDelegate> delegate;
@property (nonatomic, weak) UIView *previewView;

@end
