//
//  JYSessionViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/23/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/UIKit+AFNetworking.h>
#import <AWSS3/AWSS3.h>
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>
#import <M13ProgressSuite/M13ProgressViewImage.h>

#import "JYButton.h"
#import "JYFilename.h"
#import "JYImageMediaItem.h"
#import "JYLocalDataManager.h"
#import "JYMessage.h"
#import "JYMessageSender.h"
#import "JYSessionViewController.h"
#import "JYXmppManager.h"

@interface JYSessionViewController() <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (nonatomic) JSQMessagesAvatarImage *remoteAvatar;
@property (nonatomic) JYButton *accButton;
@property (nonatomic) JYButton *cameraButton;
@property (nonatomic) JYButton *micButton;
@property (nonatomic) JYMessageSender *messageSender;
@property (nonatomic) NSMutableArray *messageList;
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

- (XMPPJID *)thatJID
{
    if (!_thatJID)
    {
        NSString *friendUserId = [self.friend.userId uint64String];
        _thatJID = [JYXmppManager jidWithUserId:friendUserId];
    }
    return _thatJID;
}

- (JYMessageSender *)messageSender
{
    if (!_messageSender)
    {
        _messageSender = [[JYMessageSender alloc] initWithThatJID:self.thatJID];
    }
    return _messageSender;
}

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
    [self _showPickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)_showCamera
{
    [self _showPickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
}

- (void)_showPickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = sourceType;

    [self presentViewController:picker animated:YES completion:nil];
}

- (void)_showImageBrowserWithImage:(UIImage *)image fromView:(UIView *)view
{
    IDMPhoto *photo = [IDMPhoto photoWithImage:image];
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:@[photo] animatedFromView:view];
    browser.scaleImage = image;
    [self presentViewController:browser animated:YES completion:nil];
}

- (void)_showOngoingMessage:(JYMessage *)message
{
    [self.messageList addObject:message];
    [self _refresh];

    if (self.automaticallyScrollsToMostRecentMessage) {
        [self scrollToBottomAnimated:YES];
    }
}

- (void)_refresh
{
    [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
    [self.collectionView reloadData];
}

- (void)_sendMessage:(JYMessage *)message withImage:(UIImage *)image
{
    __weak typeof(self) weakSelf = self;
    [self _sendImage:image success:^(NSString *url) {

        // TODO: there is a bug: if _sendMessageWithType fail due to xmpp connect issue, the sender will consider the photo has been sent
        message.uploadStatus = JYMessageUploadStatusSuccess;
        [weakSelf _refresh];
        [weakSelf.messageSender sendImageWithDimensions:image.size URL:url];
    } failure:^(NSError *error) {
        NSLog(@"send image error = %@", error);
        message.uploadStatus = JYMessageUploadStatusFailure;
        [weakSelf _refresh];
    }];
}

- (void)_resendImageMessage:(JYMessage *)message
{
    message.uploadStatus = JYMessageUploadStatusOngoing;
    [self _refresh];

    // send image
    UIImage *image = (UIImage *)message.mediaUnderneath;
    [self _sendMessage:message withImage:image];
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

    // show JYMessage
    JYMessage *message = [[JYMessage alloc] initWithImage:image];
    message.uploadStatus = JYMessageUploadStatusOngoing;
    [self _showOngoingMessage:message];

    // send image
    [self _sendMessage:message withImage:image];
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
    [self.messageSender sendText:text];
    [self showSendButton:YES];
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

    NSUInteger row = indexPath.row;
    JYMessage *message = self.messageList[row];

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
    else if (message.bodyType == JYMessageBodyTypeImage)
    {
        JYImageMediaItem *item = (JYImageMediaItem *)message.media;
        if (!item.image)
        {
            __weak typeof(cell) weakCell = cell;
            [item fetchImageWithCompletion:^{
                [weakCell setNeedsLayout];
            }];
        }
    }

    [self _updateProgeressHudForMessage:message];

    return cell;
}

- (void)_updateProgeressHudForMessage:(JYMessage *)message
{
    if (![message isMediaMessage])
    {
        return;
    }

    if (message.uploadStatus == JYMessageUploadStatusNone)
    {
        message.progressView.alpha = 0.0f;
    }
    else if (message.uploadStatus == JYMessageUploadStatusOngoing)
    {
        message.progressView.primaryColor = JoyyBlue;
        message.progressView.secondaryColor = JoyyBlue;
        message.progressView.alpha = 1.0f;
        message.progressView.animationDuration = 0.5f;
        [message.progressView setProgress:0.0f animated:NO];
        [message.progressView setProgress:1.0f animated:YES];
    }
    else if (message.uploadStatus == JYMessageUploadStatusSuccess)
    {
        [message.progressView performAction:M13ProgressViewActionSuccess animated:YES];
        message.uploadStatus = JYMessageUploadStatusNone;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            message.progressView.alpha = 0.0f;
        });
    }
    else if (message.uploadStatus == JYMessageUploadStatusFailure)
    {
        message.progressView.primaryColor = JoyyRedPure;
        message.progressView.secondaryColor = JoyyRedPure;
        [message.progressView performAction:M13ProgressViewActionFailure animated:YES];
    }
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
    JYMessage *message = self.messageList[indexPath.row];

    if (message.bodyType == JYMessageBodyTypeImage)
    {
        if (message.uploadStatus == JYMessageUploadStatusFailure)
        {
            [self _resendImageMessage:message];
            return;
        }

        JYImageMediaItem *item = (JYImageMediaItem *)message.media;
        [self _showImageBrowserWithImage:item.image fromView:item.mediaView];
    }
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

    [self _showReceivedMessage:obj];
}

- (void)_showReceivedMessage:(JYMessage *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{

        [self.collectionView performBatchUpdates:^{

            NSUInteger count = [self.messageList count];
            [self.messageList addObject:message];

            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:count inSection:0];
            [self.collectionView insertItemsAtIndexPaths:@[indexPath]];

        } completion:^(BOOL finished) {
            [self scrollToBottomAnimated:YES];
        }];
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

    JYMessage *message = (JYMessage *)obj;

    // Only handle txt in this way, all the other type media outgoing messages was handled separately
    if (message.bodyType != JYMessageBodyTypeText)
    {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageList addObject:message];
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
                dispatch_async(dispatch_get_main_queue(), ^(void){ success(s3url); });
            }
        }
        return nil;
    }];
}

@end
