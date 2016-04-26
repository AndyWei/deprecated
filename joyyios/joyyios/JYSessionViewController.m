//
//  JYSessionViewController.m
//  joyyios
//
//  Created by Ping Yang on 2/15/16.
//  Copyright © 2016 Joyy Inc. All rights reserved.
//

#import <IDMPhotoBrowser/IDMPhotoBrowser.h>
#import <MJRefresh/MJRefresh.h>

#import "JYAudioRecorder.h"
#import "JYButton.h"
#import "JYInputBarContainer.h"
#import "JYLocalDataManager.h"
#import "JYMessageDateFormatter.h"
#import "JYMessageIncomingMediaCell.h"
#import "JYMessageIncomingTextCell.h"
#import "JYMessageOutgoingMediaCell.h"
#import "JYMessageOutgoingTextCell.h"
#import "JYMessageSender.h"
#import "JYS3Uploader.h"
#import "JYSessionViewController.h"
#import "JYSoundPlayer.h"
#import "JYXmppManager.h"

@interface JYSessionViewController () <JYAudioRecorderDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic) BOOL isLoading;
@property (nonatomic) BOOL panRecognizerEnabled;
@property (nonatomic) JYAudioRecorder *recorder;
@property (nonatomic) JYInputBarContainer *rightContainer;
@property (nonatomic) JYMessageSender *messageSender;
@property (nonatomic) JYS3Uploader *uploader;
@property (nonatomic) NSMutableArray *messageList;
@property (nonatomic) NSNumber *minMessageId;
@property (nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic) XMPPJID *thatJID;

@end

static NSString *const kIncomingMediaCell = @"incomingMediaCell";
static NSString *const kIncomingTextCell  = @"incomingTextCell";
static NSString *const kOutgoingMediaCell = @"outgoingMediaCell";
static NSString *const kOutgoingTextCell  = @"outgoingTextCell";

@implementation JYSessionViewController

- (instancetype)init
{
    if (self = [super initWithTableViewStyle:UITableViewStylePlain])
    {
        self.inverted = NO;
        self.textInputbar.autoHideRightButton = NO;
        self.isLoading = NO;
        self.messageList = [NSMutableArray new];
        self.minMessageId = [NSNumber numberWithUnsignedLongLong:LLONG_MAX];
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
    self.navigationController.navigationBar.translucent = NO;

    self.shouldScrollToBottomAfterKeyboardShows = YES;

    // the freind
    self.title = self.friend.username;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"me_selected"] style:UIBarButtonItemStylePlain target:self action:@selector(_showFriendProfile)];

    [self _loadMessages];
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
    // Note: DO NOT use estimatedRowHeight, it will cause table view jump on auto load
    self.tableView.backgroundColor = JoyyWhiter;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = YES;

    [self.tableView registerClass:JYMessageIncomingMediaCell.class forCellReuseIdentifier:kIncomingMediaCell];
    [self.tableView registerClass:JYMessageIncomingTextCell.class forCellReuseIdentifier:kIncomingTextCell];
    [self.tableView registerClass:JYMessageOutgoingMediaCell.class forCellReuseIdentifier:kOutgoingMediaCell];
    [self.tableView registerClass:JYMessageOutgoingTextCell.class forCellReuseIdentifier:kOutgoingTextCell];
}

- (void)_configTextInputbar
{
    self.textInputbar.translucent = NO;
    [self.leftButton setImage:[UIImage imageNamed:@"upload"] forState:UIControlStateNormal];
    [self.leftButton setImageEdgeInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
    [self.leftButton setTintColor:JoyyBlue];

    [self.rightButton setTitle:NSLocalizedString(@"    Send    ", nil) forState:UIControlStateNormal];
    self.rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    self.rightButton.tintColor = JoyyBlue;

    [self.textInputbar addGestureRecognizer:self.panRecognizer];
    self.panRecognizerEnabled = NO;
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

- (JYS3Uploader *)uploader
{
    if (!_uploader)
    {
        _uploader = [JYS3Uploader new];
    }
    return _uploader;
}

- (JYInputBarContainer *)rightContainer
{
    if (!_rightContainer)
    {
        UIImage *camera = [UIImage imageNamed:@"camera"];
        UIImage *mic = [UIImage imageNamed:@"microphone"];
        JYInputBarContainer *container = [[JYInputBarContainer alloc] initWithCameraImage:camera micImage:mic];

        [container.cameraButton addTarget:self action:@selector(_showCamera) forControlEvents:UIControlEventTouchUpInside];
        [container.micButton addTarget:self action:@selector(_audioRecordStart) forControlEvents:UIControlEventTouchDown];
        [container.micButton addTarget:self action:@selector(_audioRecordEnd) forControlEvents:UIControlEventTouchUpInside];

        _rightContainer = container;
    }
    return _rightContainer;
}

- (JYAudioRecorder *)recorder
{
    if (!_recorder)
    {
        _recorder = [JYAudioRecorder new];
        CGFloat width = CGRectGetWidth(self.textInputbar.bounds) - CGRectGetWidth(self.rightContainer.micButton.bounds) - 20;
//        CGFloat width = CGRectGetWidth(self.textInputbar.bounds);
        CGFloat heigh = CGRectGetHeight(self.textInputbar.bounds);
        _recorder.frame = CGRectMake(0, 0, width, heigh);
        _recorder.delegate = self;
    }
    return _recorder;
}

#pragma mark - JYAudioRecorderDelegate Methods

- (void)recorder:(JYAudioRecorder *)recorder didRecordAudioFile:(NSURL *)fileURL duration:(NSTimeInterval)duration
{
    JYMessage *message = [[JYMessage alloc] initWithAudioFile:fileURL duration:duration];

    __weak typeof(self) weakSelf = self;
    [self.uploader uploadAudioFile:fileURL success:^(NSString *url) {

        BOOL success = [weakSelf.messageSender sendAudioMessageWithDuration:duration url:url];
        message.uploadStatus = success? JYMessageUploadStatusNone : JYXmppStatusRegisterFailure;
        message.url = url;
        [weakSelf _showMessage:message];
    } failure:^(NSError *error) {

        NSLog(@"upload audio message failed with error = %@", error);
         message.uploadStatus = JYMessageUploadStatusFailure;
        [weakSelf _showMessage:message];
    }];
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
//    NSString *video = NSLocalizedString(@"Send video", nil);
//    NSString *location = NSLocalizedString(@"Send location", nil);


    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:photo style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [weakSelf _showPhotoPicker];
                                            }]];

//    [alert addAction:[UIAlertAction actionWithTitle:video style:UIAlertActionStyleDefault
//                                            handler:^(UIAlertAction * action) {
//
//                                            }]];
//
//    [alert addAction:[UIAlertAction actionWithTitle:location style:UIAlertActionStyleDefault
//                                            handler:^(UIAlertAction * action) {
//
//                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];

    [super didPressLeftButton:sender];
}

- (void)didPressRightButton:(id)sender
{
    NSString *text = self.textInputbar.textView.text;
    BOOL success = [self.messageSender sendTextMessageWithContent:text];
    JYMessage *message = [[JYMessage alloc] initWithText:text];
    message.uploadStatus = success? JYMessageUploadStatusNone: JYXmppStatusLoginFailure;

    [self _showMessage:message];
    [self showSendButton:NO];

    [super didPressRightButton:sender];
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
    [self _sendMessage:message withImage:message.media];
}

- (void)_sendMessage:(JYMessage *)message withImage:(UIImage *)image
{
    __weak typeof(self) weakSelf = self;
    [self.uploader uploadImage:image success:^(NSString *url) {

        BOOL success = [weakSelf.messageSender sendImageMessageWithDimensions:image.size url:url];
        message.uploadStatus = success? JYMessageUploadStatusSuccess: JYMessageUploadStatusFailure;
        [weakSelf _refresh];
    } failure:^(NSError *error) {
        NSLog(@"send image error = %@", error);
        message.uploadStatus = JYMessageUploadStatusFailure;
        [weakSelf _refresh];
    }];
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

- (void)_pullToRefresh
{
    if (self.isLoading)
    {
        return;
    }

    self.isLoading = YES;
    [self _loadMessages];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.isLoading = NO;
    });
}

- (void)_loadMessages
{
    // Start load data
    NSString *friendUserId = [self.friend.userId uint64String];
    NSString *senderId = [[JYCredential current].userId uint64String];
    NSString *condition = [NSString stringWithFormat:@"user_id = %@ AND peer_id = %@", senderId, friendUserId];

    NSArray *messageList = [[JYLocalDataManager sharedInstance] selectObjectsOfClass:JYMessage.class beforeId:self.minMessageId withCondition:condition limit:20];
    if ([messageList count] == 0)
    {
        return;
    }

    JYMessage *min = [messageList lastObject];
    self.minMessageId = min.messageId;


    NSInteger delta = 0;
    for (JYMessage *message in messageList)
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

    for (JYMessage *message in messageList)
    {
        [self.messageList insertObject:message atIndex:0];
    }

    [self _refreshWithElegance];
}

- (void)_refreshWithElegance
{
    CGSize beforeContentSize = self.tableView.contentSize;
    [self.tableView reloadData];
    CGSize afterContentSize = self.tableView.contentSize;
    
    CGFloat delta = afterContentSize.height - beforeContentSize.height;
    CGPoint afterContentOffset = self.tableView.contentOffset;
    CGPoint newContentOffset = CGPointMake(afterContentOffset.x, afterContentOffset.y + delta);
    [self.tableView setContentOffset:newContentOffset animated:NO];
}

- (void)_refresh
{
    [self.tableView reloadData];
}

- (void)_updateBadgeCountWithDelta:(NSInteger)delta
{
    NSDictionary *info = @{@"delta": @(delta)};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdateBadgeCount object:nil userInfo:info];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // media cell height is simple
    BOOL hasToplable = [self _shouldShowTimestampAtIndexPath:indexPath];

    JYMessage *message = self.messageList[indexPath.row];
    if ([message isMediaMessage])
    {
        CGFloat height = message.displayDimensions.height + 20.0f; // media and spaces
        if (hasToplable)
        {
            height += 30.0f;
        }
        return height;
    }

    // text cell height needs a dummy cell to really layout the text
    static JYMessageIncomingTextCell* dummyCell = nil;
    if (!dummyCell)
    {
        dummyCell = [[JYMessageIncomingTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kIncomingTextCell];
    }

    dummyCell.message = message;
    dummyCell.topLabelText = hasToplable? [[JYMessageDateFormatter sharedInstance] timestampForDate:message.timestamp]: nil;

    [dummyCell setNeedsUpdateConstraints];
    [dummyCell updateConstraintsIfNeeded];

    dummyCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(dummyCell.bounds));

    [dummyCell setNeedsLayout];
    [dummyCell layoutIfNeeded];

    // Get the actual height required for the cell's contentView
    CGFloat height = [dummyCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    return height;
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

    if ([self _shouldShowTimestampAtIndexPath:indexPath])
    {
        cell.topLabelText = [[JYMessageDateFormatter sharedInstance] timestampForDate:message.timestamp];
    }
    else
    {
        cell.topLabelText = nil;
    }

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

- (BOOL)_shouldShowTimestampAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *prev = [indexPath previous];
    if (!prev)
    {
        return YES;
    }

    JYMessage *current = self.messageList[indexPath.row];
    JYMessage *previos = self.messageList[prev.row];

    return [current hasGapWith:previos];
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYMessage *message = self.messageList[indexPath.row];

    if (message.type == JYMessageTypeImage)
    {
        if (message.uploadStatus == JYMessageUploadStatusFailure)
        {
            [self _resendImageMessage:message];
            return;
        }

        JYMessageMediaCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self _showImageBrowserWithImage:message.media fromView:cell.contentImageView];
    }
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < 0)
    {
        [self _pullToRefresh];
    }

    [super scrollViewDidScroll:scrollView];
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
//    NSDictionary *info = [notification userInfo];
//    if (!info)
//    {
//        return;
//    }
//
//    id obj = [info objectForKey:@"message"];
//    if (obj == [NSNull null])
//    {
//        return;
//    }
//
//    JYMessage *message = (JYMessage *)obj;

    // TODO: update message status
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
    [self _showMessage:message];

    // send image
    [self _sendMessage:message withImage:image];
}

#pragma mark - Audio

- (void)_audioRecordStart
{
    NSLog(@"Down");
    [[JYSoundPlayer sharedInstance] playStartWithVibrate:YES];
    self.panRecognizerEnabled = YES;
    [self.textInputbar addSubview:self.recorder];
    [self.recorder start];
}

- (void)_audioRecordEnd
{
    NSLog(@"Release");
    self.panRecognizerEnabled = NO;
    [[JYSoundPlayer sharedInstance] playFinishWithVibrate:YES];
    [self.recorder stop];
}

-(void)_audioRecordCancel
{
    NSLog(@"Cancel");
    [[JYSoundPlayer sharedInstance] playCancelWithVibrate:YES];
    [self.recorder cancel];
}

- (UIPanGestureRecognizer *)panRecognizer
{
    if (!_panRecognizer)
    {
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panRecognizer.minimumNumberOfTouches = 1;
        _panRecognizer.maximumNumberOfTouches = 1;
    }
    return _panRecognizer;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    // Note: panRecognizerEnabled is different with panRecognizer.enabled
    // we need panRecognizer.enabled always YES to detect the tap-on-micButton-then-slide-left case
    if (!self.panRecognizerEnabled)
    {
        return;
    }

    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self _audioRecordEnd];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [recognizer translationInView:self.view];
        CGFloat x = -translation.x;
        self.recorder.scrollView.contentOffset = CGPointMake(x, 0);

        if (x > 80)
        {
            self.panRecognizerEnabled = NO;
            [self _audioRecordCancel];
        }
    }
}

@end
