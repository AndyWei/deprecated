//
//  JYSessionViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/23/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "JYButton.h"
#import "JYMessage.h"
#import "JYSessionViewController.h"
#import "JYXmppManager.h"

@interface JYSessionViewController() <UIActionSheetDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (nonatomic) JSQMessagesAvatarImage *remoteAvatar;
@property (nonatomic) NSFetchedResultsController *fetcher;
@property (nonatomic) JYButton *accButton;
@property (nonatomic) JYButton *cameraButton;
@property (nonatomic) JYButton *micButton;
@property (nonatomic) UIView *leftContainerView;
@property (nonatomic) UIView *rightContainerView;
@property (nonatomic) XMPPJID *thatJID;
@end

CGFloat const kAvatarDiameter = 40.f;
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

    XMPPJID *myJID = [JYXmppManager myJID];
    self.senderId = myJID.bare;
    self.senderDisplayName = [JYCredential current].username;
    self.thatJID = [JYXmppManager jidWithUsername:self.friend.username];

    [self configCollectionView];
    [self configBubbleImage];
    [self configInputToolBar];

    // Profile Button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"me_selected"]
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(showPersonProfile)];
    // Start fetch data
    self.fetcher = [JYXmppManager fetcherForRemoteJid:self.thatJID];
    self.fetcher.delegate = self;
    NSError *error = nil;
    [self.fetcher performFetch:&error];
    if (error)
    {
        NSLog(@"fetcher performFetch error = %@", error);
    }
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

#pragma mark - Properties

- (JSQMessagesAvatarImage *)remoteAvatar
{
    if (!_remoteAvatar)
    {
        _remoteAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:self.friend.avatarImage diameter:kAvatarDiameter];
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
        [_cameraButton addTarget:self action:@selector(cameraButtonPressed) forControlEvents:UIControlEventTouchUpInside];
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
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Send photo", @"Send location", @"Send video", nil];

    [sheet showFromToolbar:self.inputToolbar];
}

- (void)cameraButtonPressed
{
    NSLog(@"cameraButtonPressed");
}

- (void)micButtonTouchDown
{
    NSLog(@"micButtonTouchDown");
}

- (void)micButtonTouchRelease
{
    NSLog(@"micButtonTouchRelease");
}

- (void)showPersonProfile
{

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

- (void)didPressSendButton:(JYButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    [self showSendButton:NO];

    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.thatJID];
    NSString *body = [NSString stringWithFormat:@"%@%@", kMessageBodyTypeText, text];
    [message addBody:body];
    [message addSubject:kMessageBodyTypeText];
    [[JYXmppManager sharedInstance].xmppStream sendElement:message];

    [self finishSendingMessageAnimated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    switch (buttonIndex) {
        case 0:
//            [self.demoData addPhotoMediaMessage];
            break;

        case 1:
        {
//            __weak UICollectionView *weakView = self.collectionView;

//            [self.demoData addLocationMediaMessageCompletion:^{
//                [weakView reloadData];
//            }];
        }
            break;

        case 2:
//            [self.demoData addVideoMediaMessage];
            break;
    }

    [JSQSystemSoundPlayer jsq_playMessageSentSound];

    [self finishSendingMessageAnimated:YES];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *coreDataMessage = [self.fetcher objectAtIndexPath:indexPath];
    JYMessage *message = [[JYMessage alloc] initWithXMPPCoreDataMessage:coreDataMessage];
    return message;
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *coreDataMessage = [self.fetcher objectAtIndexPath:indexPath];
    if (coreDataMessage.isOutgoing)
    {
        return self.outgoingBubbleImageData;
    }

    return self.incomingBubbleImageData;
}

// Show avatar for incoming messages. For a incoming messages burst, only show avatar for the first one
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *message = [self.fetcher objectAtIndexPath:indexPath];

    // No avatar for outgoing message
    if (message.isOutgoing)
    {
        return nil;
    }

    // Show avatar for the first message
    NSIndexPath *prev = [indexPath previous];
    if (!prev)
    {
        return self.remoteAvatar;
    }

    XMPPMessageArchiving_Message_CoreDataObject *prevMessage = [self.fetcher objectAtIndexPath:prev];

    if (prevMessage.isOutgoing)
    {
        return self.remoteAvatar;
    }

    // Show avatar if the previous one has over 5 minutes old
    if ([message.timestamp timeIntervalSinceDate:prevMessage.timestamp] > k5Minutes)
    {
        return self.remoteAvatar;
    }

    return nil;
}

// Return timestamp label text
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // Show timestamp label for messages 5+ minutes later than its prior
    XMPPMessageArchiving_Message_CoreDataObject *message = [self.fetcher objectAtIndexPath:indexPath];
    NSAttributedString *timestampStr = [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.timestamp];

    NSIndexPath *prev = [indexPath previous];
    if (!prev)
    {
        return timestampStr;
    }

    XMPPMessageArchiving_Message_CoreDataObject *prevMessage = [self.fetcher objectAtIndexPath:prev];
    if ([message.timestamp timeIntervalSinceDate:prevMessage.timestamp] > k5Minutes)
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
    return self.fetcher.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self.fetcher.sections objectAtIndex:section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

    XMPPMessageArchiving_Message_CoreDataObject *coreDataMessage = [self.fetcher objectAtIndexPath:indexPath];

    if ([coreDataMessage.message.body hasPrefix:kMessageBodyTypeText])
    {
        if (coreDataMessage.isOutgoing)
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

    XMPPMessageArchiving_Message_CoreDataObject *message = [self.fetcher objectAtIndexPath:indexPath];
    XMPPMessageArchiving_Message_CoreDataObject *prevMessage = [self.fetcher objectAtIndexPath:prev];
    if ([message.timestamp timeIntervalSinceDate:prevMessage.timestamp] > k5Minutes)
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

#pragma mark - NSFetchedResultsControllerDelegate

// When a message received , XMPPFramework will archive the message to CoreData storage,
// and if the message belongs to this conversation, the controllerDidChangeContent will be triggered
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.collectionView reloadData];
    [self scrollToBottomAnimated:YES];
}

@end
