//
//  JYMessageViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/23/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "JYMessage.h"
#import "JYMessageViewController.h"
#import "JYXmppManager.h"

@interface JYMessageViewController() <UIActionSheetDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (nonatomic) JSQMessagesAvatarImage *remoteAvatar;
@property (nonatomic) NSFetchedResultsController *fetcher;
@property (nonatomic) UIButton *attachmentButton;
@property (nonatomic) UIButton *cameraButton;
@property (nonatomic) UIButton *voiceButton;
@property (nonatomic) XMPPJID *remoteJid;
@end

CGFloat const kAvatarDiameter = 40.f;

@implementation JYMessageViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.person.name;

    self.view.backgroundColor = JoyyWhite;
    self.collectionView.backgroundColor = JoyyWhite;
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont systemFontOfSize:16];
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(kAvatarDiameter, kAvatarDiameter);
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;

    XMPPJID *myJid = [JYXmppManager myJid];
    self.senderId = myJid.bare;
    self.senderDisplayName = [JYCredential currentCredential].username;
    self.remoteJid = [JYXmppManager jidWithIdString:self.person.idString];

    // Bubble images
    UIImage *bubble = [UIImage imageNamed:@"message_bubble"];
    JSQMessagesBubbleImageFactory *factory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:bubble capInsets:UIEdgeInsetsZero];
    self.outgoingBubbleImageData = [factory outgoingMessagesBubbleImageWithColor:JoyyBlue];
    self.incomingBubbleImageData = [factory incomingMessagesBubbleImageWithColor:JoyyWhitePure];

    self.showLoadEarlierMessagesHeader = NO;

    self.inputToolbar.contentView.leftBarButtonItem = self.attachmentButton;
     /*  self.inputToolbar.contentView.rightBarButtonItem = custom button or nil to remove
     */
    self.inputToolbar.maximumHeight = 150;

    // Profile Button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"me_selected"]
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(_showPersonProfile)];
    // Start fetch data
    self.fetcher = [JYXmppManager fetcherForRemoteJid:self.remoteJid];
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
    [JYXmppManager sharedInstance].currentRemoteJid = self.remoteJid;
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

#pragma mark - Properties

- (JSQMessagesAvatarImage *)remoteAvatar
{
    if (!_remoteAvatar)
    {
        _remoteAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:self.person.avatarImage diameter:kAvatarDiameter];
    }

    return _remoteAvatar;
}

- (UIButton *)attachmentButton
{
    if (!_attachmentButton)
    {
        _attachmentButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [_attachmentButton addTarget:self action:@selector(_attachmentButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _attachmentButton;
}

- (UIButton *)cameraButton
{
    if (!_cameraButton)
    {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_cameraButton addTarget:self action:@selector(_cameraButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraButton;
}

- (UIButton *)voiceButton
{
    if (!_voiceButton)
    {
        _voiceButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_voiceButton addTarget:self action:@selector(_voiceButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _voiceButton;
}

#pragma mark - Actions

- (void)_attachmentButtonPressed
{

}

- (void)_cameraButtonPressed
{

}

- (void)_voiceButtonPressed
{

}

- (void)_voiceButtonHold
{

}

- (void)_voiceButtonReleased
{

}

- (void)_showPersonProfile
{

}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.remoteJid];
    NSString *body = [NSString stringWithFormat:@"%@%@", kMessageBodyTypeText, text];
    [message addBody:body];
    [message addSubject:kMessageBodyTypeText];
    [[JYXmppManager sharedInstance].xmppStream sendElement:message];

    [self finishSendingMessageAnimated:YES];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Send photo", @"Send location", @"Send video", nil];

    [sheet showFromToolbar:self.inputToolbar];
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
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
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
