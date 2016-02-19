//
//  JYSessionViewController.m
//  joyyios
//
//  Created by Ping Yang on 2/15/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <AWSS3/AWSS3.h>
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>
#import <MJRefresh/MJRefresh.h>

#import "JYButton.h"
#import "JYFilename.h"
#import "JYInputBarContainer.h"
#import "JYLocalDataManager.h"
#import "JYMessageTextCell.h"
#import "JYMessageIncomingMediaCell.h"
#import "JYMessageIncomingTextCell.h"
#import "JYMessageOutgoingMediaCell.h"
#import "JYMessageOutgoingTextCell.h"
#import "JYMessageSender.h"
#import "JYSessionViewController.h"
#import "JYXmppManager.h"

@interface JYSessionViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic) JYInputBarContainer *rightContainer;
@property (nonatomic) JYMessageSender *messageSender;
@property (nonatomic) NSMutableArray *messageList;
@property (nonatomic) XMPPJID *thatJID;
@end

static NSString *const kIncomingMediaCell = @"incomingMediaCell";
static NSString *const kIncomingTextCell = @"incomingTextCell";
static NSString *const kOutgoingMediaCell = @"outgoingMediaCell";
static NSString *const kOutgoingTextCell = @"outgoingTextCell";

@implementation JYSessionViewController

- (instancetype)init
{
    if (self = [super initWithTableViewStyle:UITableViewStylePlain])
    {
        self.inverted = NO;
        self.textInputbar.autoHideRightButton = NO;
    }
    return self;
}

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.shouldScrollToBottomAfterKeyboardShows = YES;

    // the freind
    self.title = self.friend.username;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"me_selected"] style:UIBarButtonItemStylePlain target:self action:@selector(_showFriendProfile)];

    [self _reloadMessages];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMessage:) name:kNotificationDidReceiveMessage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didSendMessage:) name:kNotificationDidSendMessage object:nil];

    [self _configTableView];
    [self _configTextInputbar];

    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [JYXmppManager sharedInstance].currentRemoteJid = self.thatJID;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [JYXmppManager sharedInstance].currentRemoteJid = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_configTableView
{
    self.tableView.estimatedRowHeight = 70;
    self.tableView.backgroundColor = JoyyWhite;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = YES;

    [self.tableView registerClass:JYMessageIncomingMediaCell.class forCellReuseIdentifier:kIncomingMediaCell];
    [self.tableView registerClass:JYMessageIncomingTextCell.class forCellReuseIdentifier:kIncomingTextCell];
    [self.tableView registerClass:JYMessageOutgoingMediaCell.class forCellReuseIdentifier:kOutgoingMediaCell];
    [self.tableView registerClass:JYMessageOutgoingTextCell.class forCellReuseIdentifier:kOutgoingTextCell];

    // Setup the pull-up-to-refresh footer
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(_fetchOldMessages)];
    header.stateLabel.hidden = YES;
    self.tableView.mj_header = header;
}

- (void)_configTextInputbar
{
    [self.leftButton setImage:[UIImage imageNamed:@"upload"] forState:UIControlStateNormal];
    [self.leftButton setImageEdgeInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
    [self.leftButton setTintColor:JoyyBlue];

    [self.rightButton setTitle:NSLocalizedString(@"    Send    ", nil) forState:UIControlStateNormal];
    self.rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    self.rightButton.tintColor = JoyyBlue;

    [self.textInputbar addSubview:self.rightContainer];
    NSDictionary *views = @{
                            @"rightContainer": self.rightContainer
                            };

    [self.textInputbar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0@500)-[rightContainer(95)]-0-|" options:0 metrics:nil views:views]];
    [self.textInputbar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[rightContainer]-0-|" options:0 metrics:nil views:views]];

    [self showSendButton:NO];
}

- (void)showSendButton:(BOOL)show
{
    self.rightContainer.hidden = show;
    self.rightButton.tintColor = show? JoyyBlue: ClearColor;
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

- (JYInputBarContainer *)rightContainer
{
    if (!_rightContainer)
    {
        UIImage *camera = [UIImage imageNamed:@"camera"];
        UIImage *mic = [UIImage imageNamed:@"microphone"];
        JYInputBarContainer *container = [[JYInputBarContainer alloc] initWithCameraImage:camera micImage:mic];

        [container.cameraButton addTarget:self action:@selector(_showCamera) forControlEvents:UIControlEventTouchUpInside];
        [container.micButton addTarget:self action:@selector(_micButtonTouchDown) forControlEvents:UIControlEventTouchDown];
        [container.micButton addTarget:self action:@selector(_micButtonTouchRelease) forControlEvents:UIControlEventTouchUpInside];
        [container.micButton addTarget:self action:@selector(_micButtonTouchRelease) forControlEvents:UIControlEventTouchUpOutside];

        _rightContainer = container;
    }
    return _rightContainer;
}

#pragma mark - TextView delegate

- (void)textViewDidChange:(UITextView *)textView
{
    [super textViewDidChange:textView];

    if (textView != self.textInputbar.textView) {
        return;
    }

    BOOL hasText = ![textView.text isInvisible];
    [self showSendButton:hasText];
}

#pragma mark - Actions

- (void)didPressLeftButton:(id)sender
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

                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:location style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {

                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];

    [super didPressLeftButton:sender];
}

- (void)didPressRightButton:(id)sender
{
    [self showSendButton:NO];
    [self.messageSender sendText:self.textInputbar.textView.text];
    [self showSendButton:YES];

    [super didPressRightButton:sender];
}

- (void)_micButtonTouchDown
{
    NSLog(@"_micButtonTouchDown");
}

- (void)_micButtonTouchRelease
{
    NSLog(@"_micButtonTouchRelease");
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

- (void)_resendImageMessage:(JYMessage *)message
{
    message.uploadStatus = JYMessageUploadStatusOngoing;
    [self _refresh];

    UIImage *image = (UIImage *)message.mediaUnderneath;
    [self _sendMessage:message withImage:image];
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

- (void)_refresh
{
    [self.tableView reloadData];
}

- (void)_showFriendProfile
{
}

- (void)_showImageBrowserWithImage:(UIImage *)image fromView:(UIView *)view
{
    IDMPhoto *photo = [IDMPhoto photoWithImage:image];
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:@[photo] animatedFromView:view];
    browser.scaleImage = image;
    [self presentViewController:browser animated:YES completion:nil];
}

- (void)_showMessage:(JYMessage *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{

        NSUInteger count = [self.messageList count];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:count inSection:0];

        [self.tableView beginUpdates];
        [self.messageList addObject:message];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];

        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    });
}

- (void)_showOngoingMessage:(JYMessage *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{

        NSUInteger count = [self.messageList count];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:count inSection:0];

        [self.tableView beginUpdates];
        [self.messageList addObject:message];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];

        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    });
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

#pragma mark - Data

- (void)_reloadMessages
{
    // Start load data
    NSString *friendUserId = [self.friend.userId uint64String];
    NSString *senderId = [[JYCredential current].userId uint64String];
//    NSString *condition = [NSString stringWithFormat:@"user_id = %@ AND peer_id = %@", senderId, friendUserId];
//    self.messageList = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYMessage.class withCondition:condition sort:@"ASC"];

    NSString *condition = [NSString stringWithFormat:@"user_id = %@ AND peer_id = %@", senderId, friendUserId];

    NSArray *array = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYMessage.class withCondition:condition sort:@"DESC LIMIT 80"];
    self.messageList = [NSMutableArray arrayWithArray:[[array reverseObjectEnumerator] allObjects]];


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

- (void)_fetchOldMessages
{
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messageList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    JYMessage *message = self.messageList[indexPath.row];
    if ([message isMediaMessage])
    {
        CGFloat height = message.displayDimensions.height + 10;
        return height;
    }

    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYMessage *message = self.messageList[indexPath.row];
    NSString *identifier = nil;
    if ([message isOutgoing].boolValue)
    {
        identifier = [message isMediaMessage]? kOutgoingMediaCell: kOutgoingTextCell;
    }
    else
    {
        identifier = [message isMediaMessage]? kIncomingMediaCell: kIncomingTextCell;
    }

    JYMessageCell *cell = (JYMessageCell *)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];

    cell.message = message;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYMessage *message = self.messageList[indexPath.row];

    if (message.bodyType == JYMessageBodyTypeImage)
    {
        if (message.uploadStatus == JYMessageUploadStatusFailure)
        {
            [self _resendImageMessage:message];
            return;
        }

        JYMessageMediaCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self _showImageBrowserWithImage:message.mediaUnderneath fromView:cell.contentImageView];
    }
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

    [self _showMessage:obj];
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
    if (message.bodyType == JYMessageBodyTypeText)
    {
        [self _showMessage:message];
    }
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
