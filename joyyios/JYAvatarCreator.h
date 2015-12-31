//
//  JYAvatarCreator.h
//  joyyios
//
//  Created by Ping Yang on 12/28/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

@class JYAvatarCreator;

@protocol JYAvatarCreatorDelegate <NSObject>
- (void)creator:(JYAvatarCreator *)creator didTakePhoto:(UIImage *)photo;
@end


@interface JYAvatarCreator : NSObject

- (instancetype)initWithViewController:(UIViewController *)viewController;
- (void)showOptions;
- (void)showImagePicker;
- (void)showCamera;
- (void)uploadAvatarImage:(UIImage *)image success:(Action)success failure:(FailureHandler)failure;
- (void)writeRemoteProfileWithParameters:(NSDictionary *)parameters;

@property (nonatomic, weak) id<JYAvatarCreatorDelegate> delegate;

@end
