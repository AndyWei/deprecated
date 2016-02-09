//
//  JYSessionViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/23/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIKit+AFNetworking.h>
#import <AWSS3/AWSS3.h>

#import "JYButton.h"
#import "JYFilename.h"
#import "JYLocalDataManager.h"
#import "JYMessage.h"
#import "JYSessionViewController.h"
#import "JYXmppManager.h"

@interface JYSessionViewController() <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (nonatomic) JSQMessagesAvatarImage *remoteAvatar;
@property (nonatomic) NSMutableArray *messageList;
@property (nonatomic) JYButton *accButton;
@property (nonatomic) JYButton *cameraButton;
@property (nonatomic) JYButton *micButton;
@property (nonatomic) UIView *leftContainerView;
@property (nonatomic) UIView *rightContainerView;
@property (nonatomic) XMPPJID *thatJID;
@end

CGFloat const kAvatarDiameter = 35.f;
CGFloat const kAccButtonWidth = 44.f;
CGFloat const kMediaButtonWidth = 44.f;
CGFloat const kLeftContainerWidth = kAccButtonWidth;
CGFloat const kRightContainerWidth = 2 * kMediaButtonWidth;
CGFloat const kEdgeInset = 10.f;

@implementation JYSessionViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.friend.username;
    self.view.backgroundColor = JoyyWhite;

    self.senderId = [[JYCredential current].userId uint64String];
    self.senderDisplayName = [JYCredential current].username;
    NSString *friendUserId = [self.friend.userId uint64String];
    self.thatJID = [JYXmppManager jidWithUserId:friendUserId];

    [self configCollectionView];
    [self configBubbleImage];
    [self configInputToolBar];

    // Profile Button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"me_selected"] style:UIBarButtonItemStylePlain target:self action:@selector(showPersonProfile)];

    // Avatar
    [self _fetchAvatarImage];

    [self _reloadMessages];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMessage:) name:kNotificationDidReceiveMessage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didSendMessage:) name:kNotificationDidSendMessage object:nil];
}

- (void)_reloadMessages
{
    // Start load data
    NSString *friendUserId = [self.friend.userId uint64String];
    NSString *condition = [NSString stringWithFormat:@"user_id = %@ AND peer_id = %@", self.senderId, friendUserId];
    self.messageList = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYMessage.class withCondition:condition sort:@"ASC"];

    // mark all unread messages as read
    NSInteger delta = 0;
    for (JYMessage *message in self.messageList)
    {
        if ([message.isUnread boolValue])
        {
            message.isUnread = [NSNumber numberWithBool:NO];
            [[JYLocalDataManager sharedInstance] updateObject:message ofClass:JYMessage.class];
            --delta;
        }
    }

    if (delta != 0)
    {
        [self _updateBadgeCountWithDelta:delta];
    }
}

- (void)_updateBadgeCountWithDelta:(NSInteger)delta
{
    NSDictionary *info = @{@"delta": @(delta)};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBadgeCount object:nil userInfo:info];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [JYXmppManager sharedInstance].currentRemoteJid = self.thatJID;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [JYXmppManager sharedInstance].currentRemoteJid = nil;
}

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)configCollectionView
{
    self.collectionView.backgroundColor = JoyyWhite;
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont systemFontOfSize:16];
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(kAvatarDiameter, kAvatarDiameter);
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    self.showLoadEarlierMessagesHeader = NO;
}

- (void)configBubbleImage
{
    UIImage *bubble = [UIImage imageNamed:@"message_bubble_neat"];
    JSQMessagesBubbleImageFactory *factory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:bubble capInsets:UIEdgeInsetsZero];
    self.outgoingBubbleImageData = [factory outgoingMessagesBubbleImageWithColor:JoyyBlue];
    self.incomingBubbleImageData = [factory incomingMessagesBubbleImageWithColor:JoyyWhitePure];
}

- (void)configInputToolBar
{
    self.inputToolbar.contentView.leftBarButtonItem.hidden = YES;
    self.inputToolbar.contentView.leftBarButtonItemWidth = kLeftContainerWidth;
    [self.inputToolbar.contentView.leftBarButtonContainerView addSubview:self.leftContainerView];

    self.inputToolbar.contentView.rightBarButtonItemWidth = kRightContainerWidth;
    [self.inputToolbar.contentView.rightBarButtonContainerView addSubview:self.rightContainerView];
    [self showSendButton:NO];
}

- (void)showSendButton:(BOOL)show
{
    if (show)
    {
        self.rightContainerView.hidden = YES;
        self.inputToolbar.contentView.rightBarButtonItem.hidden = NO;
    }
    else
    {
        self.rightContainerView.hidden = NO;
        self.inputToolbar.contentView.rightBarButtonItem.hidden = YES;
    }
}

#pragma mark - Avatar
- (void)_fetchAvatarImage
{
    UIImageView *dummyView = [UIImageView new];

    NSURLRequest *request = [NSURLRequest requestWithURL:self.friend.avatarThumbnailURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [dummyView setImageWithURLRequest:request
                           placeholderImage:self.friend.avatarThumbnailImage
                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                        weakSelf.remoteAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:kAvatarDiameter];
                                        self.friend.avatarThumbnailImage = image;
                                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                        NSLog(@"setImageWithURLRequest failed with error = %@", error);
                                    }];
}
#pragma mark - Properties

- (JSQMessagesAvatarImage *)remoteAvatar
{
    if (!_remoteAvatar)
    {
        if (self.friend.avatarThumbnailImage)
        {
            _remoteAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:self.friend.avatarThumbnailImage diameter:kAvatarDiameter];
        }
    }

    return _remoteAvatar;
}

- (UIView *)leftContainerView
{
    if (!_leftContainerView)
    {
        CGFloat height = self.inputToolbar.preferredDefaultHeight;
        _leftContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kLeftContainerWidth, height)];
        _leftContainerView.backgroundColor = ClearColor;
        [_leftContainerView addSubview:self.accButton];
    }
    return _leftContainerView;
}

- (UIView *)rightContainerView
{
    if (!_rightContainerView)
    {
        CGFloat height = self.inputToolbar.preferredDefaultHeight;
        _rightContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kRightContainerWidth, height)];
        _rightContainerView.backgroundColor = ClearColor;
        [_rightContainerView addSubview:self.cameraButton];
        [_rightContainerView addSubview:self.micButton];
    }
    return _rightContainerView;
}

- (JYButton *)cameraButton
{
    if (!_cameraButton)
    {
        CGRect frame = CGRectMake(0, 0, kMediaButtonWidth, self.inputToolbar.preferredDefaultHeight);
        UIImage *icon = [UIImage imageNamed:@"camera"];
        _cameraButton = [JYButton iconButtonWithFrame:frame icon:icon color:JoyyBlue];
        _cameraButton.contentEdgeInsets = UIEdgeInsetsMake(0, kEdgeInset, kEdgeInset, kEdgeInset);
        [_cameraButton addTarget:self action:@selector(_showCamera) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraButton;
}

- (JYButton *)micButton
{
    if (!_micButton)
    {
        CGFloat x = kRightContainerWidth - kMediaButtonWidth;
        CGRect frame = CGRectMake(x, 0, kMediaButtonWidth, self.inputToolbar.preferredDefaultHeight);
        UIImage *icon = [UIImage imageNamed:@"microphone"];
        _micButton = [JYButton iconButtonWithFrame:frame icon:icon color:JoyyBlue];
        _micButton.contentEdgeInsets = UIEdgeInsetsMake(0, kEdgeInset, kEdgeInset + 2, kEdgeInset);

        [_micButton addTarget:self action:@selector(micButtonTouchDown) forControlEvents:UIControlEventTouchDown];
        [_micButton addTarget:self action:@selector(micButtonTouchRelease) forControlEvents:UIControlEventTouchUpInside];
        [_micButton addTarget:self action:@selector(micButtonTouchRelease) forControlEvents:UIControlEventTouchUpOutside];
    }
    return _micButton;
}

- (JYButton *)accButton
{
    if (!_accButton)
    {
        CGRect frame = CGRectMake(0, 0, kAccButtonWidth, self.inputToolbar.preferredDefaultHeight);
        UIImage *icon = [UIImage imageNamed:@"upload"];
        _accButton = [JYButton iconButtonWithFrame:frame icon:icon color:JoyyBlue];
        _accButton.contentEdgeInsets = UIEdgeInsetsMake(0, kEdgeInset, kEdgeInset + 1, kEdgeInset);
        [_accButton addTarget:self action:@selector(accButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _accButton;
}

#pragma mark - Actions

- (void)accButtonPressed
{
    NSString *title  = NSLocalizedString(@"Media messages", nil);
    NSString *cancel = NSLocalizedString(@"Cancel", nil);
    NSString *photo = NSLocalizedString(@"Send photo", nil);
    NSString *video = NSLocalizedString(@"Send video", nil);
    NSString *location = NSLocalizedString(@"Send location", nil);


    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:photo style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [weakSelf _showPhotoPicker];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:video style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [JSQSystemSoundPlayer jsq_playMessageSentSound];
                                                [weakSelf finishSendingMessageAnimated:YES];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:location style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                 [JSQSystemSoundPlayer jsq_playMessageSentSound];
                                                 [weakSelf finishSendingMessageAnimated:YES];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)micButtonTouchDown
{
    NSLog(@"micButtonTouchDown");
}

- (void)micButtonTouchRelease
{
    NSLog(@"micButtonTouchRelease");
}

- (void)_showPhotoPicker
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    [self presentViewController:picker animated:YES completion:nil];
}

- (void)_showCamera
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;

    [self presentViewController:picker animated:YES completion:nil];
}

- (void)showPersonProfile
{

}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];

    // resize image
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    CGFloat min = fmin(originalImage.size.width, originalImage.size.height);
    if (min == 0.0f)
    {
        return;
    }

    CGFloat factor = fmin(kPhotoWidth/min, 1);
    CGFloat width = originalImage.size.width * factor;
    CGFloat heigth = originalImage.size.height * factor;
    UIImage *image = [originalImage imageScaledToSize:CGSizeMake(width, heigth)];

    // send image
    __weak typeof(self) weakSelf = self;
    [self _sendImage:image success:^(UIImage *image, NSString *url) {

        [weakSelf _sendMessageWithType:kMessageBodyTypeImage message:url andAlert:@"send you a photo"];
    } failure:^(NSError *error) {
        NSLog(@"send image error = %@", error);
    }];
}

#pragma mark - TextView delegate
- (void)textViewDidChange:(UITextView *)textView
{
    [super textViewDidChange:textView];

    if (textView != self.inputToolbar.contentView.textView) {
        return;
    }

    BOOL hasText = [self.inputToolbar.contentView.textView hasText];
    [self showSendButton:hasText];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(JYButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    [self showSendButton:NO];
    [self _sendMessageWithType:kMessageBodyTypeText message:text andAlert:text];
    [self showSendButton:YES];
}

- (void)_sendMessageWithType:(NSString *)type message:(NSString *)message andAlert:(NSString *)alert
{
    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:self.thatJID];
    NSString *title = [NSString stringWithFormat:@"%@: %@", [JYCredential current].username, alert];
    uint64_t timestamp = (uint64_t)([NSDate timeIntervalSinceReferenceDate] * 1000000);

    NSDictionary *dict = @{
                           @"type": type,
                           @"res": message,
                           @"title": title, // for push notification purpose
                           @"ts": @(timestamp)
                           };
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];

    if (err || !jsonData)
    {
        NSLog(@"Got an error: %@", err);
        return;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [msg addBody:jsonString];

    [[JYXmppManager sharedInstance].xmppStream sendElement:msg];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JYMessage *message = self.messageList[indexPath.row];
    return message;
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JYMessage *message = self.messageList[indexPath.row];
    return [message.isOutgoing boolValue]? self.outgoingBubbleImageData: self.incomingBubbleImageData;
}

// Show avatar for incoming messages. For a incoming messages burst, only show avatar for the first one
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JYMessage *message = self.messageList[indexPath.row];

    // No avatar for outgoing message
    if ([message.isOutgoing boolValue])
    {
        return nil;
    }

    // Show avatar for the first message
    NSIndexPath *prev = [indexPath previous];
    if (!prev)
    {
        return self.remoteAvatar;
    }

    JYMessage *prevMessage = self.messageList[prev.row];
    if ([prevMessage.isOutgoing boolValue])
    {
        return self.remoteAvatar;
    }

    // Show avatar if the previous one has over 5 minutes old
    if ([message hasGapWith:prevMessage])
    {
        return self.remoteAvatar;
    }

    return nil;
}

// Return timestamp label text
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // Show timestamp label for messages 5+ minutes later than its prior
    JYMessage *message = self.messageList[indexPath.row];
    NSAttributedString *timestampStr = [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.timestamp];

    NSIndexPath *prev = [indexPath previous];
    if (!prev)
    {
        return timestampStr;
    }

    JYMessage *prevMessage = self.messageList[prev.row];
    if ([message hasGapWith:prevMessage])
    {
        return timestampStr;
    }

    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messageList count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

    JYMessage *message = self.messageList[indexPath.row];

    if (message.bodyType == JYMessageBodyTypeText)
    {
        if ([message.isOutgoing boolValue])
        {
            cell.textView.textColor = JoyyWhitePure;
        }
        else {
            cell.textView.textColor = JoyyBlack;
        }

        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }

    return cell;
}

#pragma mark - JSQMessages collection view flow layout delegate

// Return timestamp label height
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // Show timestamp label for messages 5+ minutes later than its prior
    NSIndexPath *prev = [indexPath previous];
    if (!prev)
    {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }

    JYMessage *message = self.messageList[indexPath.row];
    JYMessage *prevMessage = self.messageList[prev.row];
    if ([message hasGapWith:prevMessage])
    {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }

    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(JYButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - Notifications

- (void)_didReceiveMessage:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (!info)
    {
        return;
    }

    id obj = [info objectForKey:@"message"];
    if (obj == [NSNull null])
    {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageList addObject:obj];
        [self finishReceivingMessage];
    });
}

- (void)_didSendMessage:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    if (!info)
    {
        return;
    }

    id obj = [info objectForKey:@"message"];
    if (obj == [NSNull null])
    {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageList addObject:obj];
        [self finishSendingMessage];
    });
}

#pragma mark S3
- (void)_sendImage:(UIImage *)image success:(ImageHandler)success failure:(FailureHandler)failure
{
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"message"]];

    NSData *imageData = UIImageJPEGRepresentation(image, kPhotoQuality);
    [imageData writeToURL:fileURL atomically:YES];

    NSString *s3filename = [[JYFilename sharedInstance] randomFilenameWithHttpContentType:kContentTypeJPG];
    NSString *s3region = [JYFilename sharedInstance].region;
    NSString *s3url = [NSString stringWithFormat:@"%@:%@", s3region, s3filename];

    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    if (!transferManager)
    {
        NSLog(@"Error: no S3 transferManager");
        if (failure)
        {
            NSError *error = [NSError errorWithDomain:@"winkrock" code:2000 userInfo:@{@"error": @"no S3 transferManager"}];
            dispatch_async(dispatch_get_main_queue(), ^(void){ failure(error); });
        }
        return;
    }

    AWSS3TransferManagerUploadRequest *request = [AWSS3TransferManagerUploadRequest new];
    request.bucket = [JYFilename sharedInstance].messageBucketName;
    request.key = s3filename;
    request.body = fileURL;
    request.contentType = kContentTypeJPG;

    [[transferManager upload:request] continueWithBlock:^id(AWSTask *task) {
        if (task.error)
        {
            NSLog(@"Error: AWSS3TransferManager upload error = %@", task.error);

            if (failure)
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){ failure(task.error); });
            }
        }
        if (task.result)
        {
            AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
            NSLog(@"Success: AWSS3TransferManager upload task.result = %@", uploadOutput);

            if (success)
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){ success(image, s3url); });
            }
        }
        return nil;
    }];
}

@end
