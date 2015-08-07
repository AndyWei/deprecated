//
//  JYPersonCard.m
//  joyyios
//
//  Created by Ping Yang on 7/5/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYImageLabelView.h"
#import "JYPerson.h"
#import "JYPersonCard.h"

static const CGFloat kImageLabelWidth = 42.f;

@interface JYPersonCard ()
@property (nonatomic) JYImageLabelView *cameraImageLabelView;
@property (nonatomic) JYImageLabelView *interestsImageLabelView;
@property (nonatomic) JYImageLabelView *friendsImageLabelView;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UIView *informationView;
@end

@implementation JYPersonCard

#pragma mark - Object Lifecycle

- (instancetype)initWithFrame:(CGRect)frame person:(JYPerson *)person options:(MDCSwipeToChooseViewOptions *)options
{
    self = [super initWithFrame:frame options:options];
    if (self)
    {
        _person = person;
        self.imageView.image = _person.image;

        self.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                UIViewAutoresizingFlexibleWidth |
                                UIViewAutoresizingFlexibleBottomMargin;
        self.imageView.autoresizingMask = self.autoresizingMask;

        [self _createInformationView];
    }
    return self;
}

#pragma mark - Internal Methods

- (void)_createInformationView
{
    CGFloat bottomHeight = 60.f;
    CGRect bottomFrame = CGRectMake(0,
                                    CGRectGetHeight(self.bounds) - bottomHeight,
                                    CGRectGetWidth(self.bounds),
                                    bottomHeight);
    _informationView = [[UIView alloc] initWithFrame:bottomFrame];
    _informationView.backgroundColor = [UIColor whiteColor];
    _informationView.clipsToBounds = YES;
    _informationView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                        UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:_informationView];

    [self _createNameLabel];
    [self _createCameraImageLabelView];
    [self _createInterestsImageLabelView];
    [self _createFriendsImageLabelView];
}

- (void)_createNameLabel
{
    CGFloat leftPadding = 12.f;
    CGFloat topPadding = 17.f;
    CGRect frame = CGRectMake(leftPadding,
                              topPadding,
                              floorf(CGRectGetWidth(_informationView.frame)/2),
                              CGRectGetHeight(_informationView.frame) - topPadding);
    _nameLabel = [[UILabel alloc] initWithFrame:frame];
    _nameLabel.text = [NSString stringWithFormat:@"%@, %@", _person.name, @(_person.age)];
    [_informationView addSubview:_nameLabel];
}

- (void)_createCameraImageLabelView
{
    CGFloat rightPadding = 10.f;
    UIImage *image = [UIImage imageNamed:@"camera"];
    _cameraImageLabelView = [self buildImageLabelViewLeftOf:CGRectGetWidth(_informationView.bounds) - rightPadding
                                                      image:image
                                                       text:[@(_person.numberOfPhotos) stringValue]];
    [_informationView addSubview:_cameraImageLabelView];
}

- (void)_createInterestsImageLabelView
{
    UIImage *image = [UIImage imageNamed:@"book"];
    _interestsImageLabelView = [self buildImageLabelViewLeftOf:CGRectGetMinX(_cameraImageLabelView.frame)
                                                         image:image
                                                          text:[@(_person.numberOfPhotos) stringValue]];
    [_informationView addSubview:_interestsImageLabelView];
}

- (void)_createFriendsImageLabelView
{
    UIImage *image = [UIImage imageNamed:@"group"];
    _friendsImageLabelView = [self buildImageLabelViewLeftOf:CGRectGetMinX(_interestsImageLabelView.frame)
                                                      image:image
                                                       text:[@(_person.numberOfSharedFriends) stringValue]];
    [_informationView addSubview:_friendsImageLabelView];
}

- (JYImageLabelView *)buildImageLabelViewLeftOf:(CGFloat)x image:(UIImage *)image text:(NSString *)text
{
    CGRect frame = CGRectMake(x - kImageLabelWidth,
                              0,
                              kImageLabelWidth,
                              CGRectGetHeight(_informationView.bounds));
    JYImageLabelView *view = [[JYImageLabelView alloc] initWithFrame:frame
                                                           image:image
                                                            text:text];
    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    return view;
}

@end
