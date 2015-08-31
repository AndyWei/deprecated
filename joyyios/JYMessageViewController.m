//
//  JYMessageViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/23/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "JYMessage.h"
#import "JYMessageAvatar.h"
#import "JYMessageViewController.h"
#import "JYXmppManager.h"

@interface JYMessageViewController() <UIActionSheetDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (nonatomic) JYMessageAvatar *remoteAvatar;
@property (nonatomic) JYMessageAvatar *myAvatar;
@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) XMPPJID *remoteJid;
@end

@implementation JYMessageViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = self.person.name;

    self.view.backgroundColor = JoyyWhite;
    self.collectionView.backgroundColor = JoyyWhite;
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont systemFontOfSize:16];

    XMPPJID *myJid = [JYXmppManager myJid];
    self.senderId = myJid.bare;
    self.senderDisplayName = [JYCredential current].name;

    self.remoteJid = [JYXmppManager jidWithIdString:self.person.idString];

    // Bubble images
    UIImage *bubble = [UIImage imageNamed:@"message_bubble"];

    JSQMessagesBubbleImageFactory *factory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:bubble capInsets:UIEdgeInsetsZero];
    self.outgoingBubbleImageData = [factory outgoingMessagesBubbleImageWithColor:JoyyBlue];
    self.incomingBubbleImageData = [factory incomingMessagesBubbleImageWithColor:JoyyWhitePure];

    self.showLoadEarlierMessagesHeader = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"me_selected"]
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(_showPersonProfile)];

    /**
     *  Customize your toolbar buttons
     *
     *  self.inputToolbar.contentView.leftBarButtonItem = custom button or nil to remove
     *  self.inputToolbar.contentView.rightBarButtonItem = custom button or nil to remove
     */
    self.inputToolbar.maximumHeight = 150;

    // Start fetch data
    self.fetchedResultsController = [JYXmppManager fetchedResultsControllerForRemoteJid:self.remoteJid];
    self.fetchedResultsController.delegate = self;
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    if (error)
    {
        NSLog(@"fetchedResultsController performFetch error = %@", error);
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

- (JYMessageAvatar *)remoteAvatar
{
    if (!_remoteAvatar)
    {
        UIImage *image = [UIImage imageNamed:@"me"];
        _remoteAvatar = [JYMessageAvatar avatarWithImage:image];
    }

    return _remoteAvatar;
}

- (JYMessageAvatar *)myAvatar
{
    if (!_myAvatar)
    {
        UIImage *image = [UIImage imageNamed:@"me_selected"];
        _myAvatar = [JYMessageAvatar avatarWithImage:image];
    }

    return _myAvatar;
}

#pragma mark - Actions

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
    XMPPMessageArchiving_Message_CoreDataObject *coreDataMessage = [self.fetchedResultsController objectAtIndexPath:indexPath];
    JYMessage *message = [[JYMessage alloc] initWithXMPPCoreDataMessage:coreDataMessage];
    return message;
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *coreDataMessage = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (coreDataMessage.isOutgoing)
    {
        return self.outgoingBubbleImageData;
    }

    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Message_CoreDataObject *coreDataMessage = [self.fetchedResultsController objectAtIndexPath:indexPath];

    if (coreDataMessage.isOutgoing)
    {
        return self.myAvatar;
    }

    return self.remoteAvatar;
}

// Return timestamp label text
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // Show timestamp label for messages 5+ minutes later than its prior
    XMPPMessageArchiving_Message_CoreDataObject *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSAttributedString *timestampStr = [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.timestamp];
    if (indexPath.section == 0 && indexPath.item == 0)
    {
        return timestampStr;
    }

    NSIndexPath *prevIndexPath = [self previousIndexPath:indexPath];
    XMPPMessageArchiving_Message_CoreDataObject *prevMessage = [self.fetchedResultsController objectAtIndexPath:prevIndexPath];

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
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self.fetchedResultsController.sections objectAtIndex:section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

    XMPPMessageArchiving_Message_CoreDataObject *coreDataMessage = [self.fetchedResultsController objectAtIndexPath:indexPath];

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
    XMPPMessageArchiving_Message_CoreDataObject *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (indexPath.section == 0 && indexPath.item == 0)
    {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }

    NSIndexPath *prevIndexPath = [self previousIndexPath:indexPath];
    XMPPMessageArchiving_Message_CoreDataObject *prevMessage = [self.fetchedResultsController objectAtIndexPath:prevIndexPath];

    if ([message.timestamp timeIntervalSinceDate:prevMessage.timestamp] > k5Minutes)
    {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }

    return 0.0f;
}

// Return the previous indexPath of the given one
// If the given one is the first one, then return itself
- (NSIndexPath *)previousIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.item == 0)
    {
        return indexPath;
    }

    NSInteger item = indexPath.item;
    NSInteger section = indexPath.section;
    if (item == 0)
    {
        --section;
    }
    else
    {
        --item;
    }
    return [NSIndexPath indexPathForItem:item inSection:section];
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

#pragma mark - CoreData

// When a message received , XMPPFramework will archive the message to CoreData storage,
// and if the message belongs to this conversation, the controllerDidChangeContent will be triggered
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.collectionView reloadData];
    [self scrollToBottomAnimated:YES];
}

@end
