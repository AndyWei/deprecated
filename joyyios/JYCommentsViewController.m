//
//  JYCommentsViewController.m
//  joyyios
//
//  Created by Ping Yang on 5/20/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYCommentTextView.h"
#import "JYCommentViewCell.h"
#import "JYCommentsViewController.h"
#import "JYOrderItemView.h"
#import "JYUser.h"

@interface JYCommentsViewController ()

@property(nonatomic, copy) NSDictionary *order;
@property(nonatomic, copy) NSDictionary *bid;
@property(nonatomic) NSMutableArray *commentList;
@property(nonatomic) NSUInteger maxCommentId;

@end

static NSString *const kCommentCellIdentifier = @"commentCell";

@implementation JYCommentsViewController

- (instancetype)initWithOrder:(NSDictionary *)order bid:(NSDictionary *)bid comments:(NSArray *)commentList
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self)
    {
        [self registerClassForTextView:[JYCommentTextView class]];
        self.order = order;
        self.bid = bid;
        self.commentList = [NSMutableArray arrayWithArray:commentList];

        NSDictionary *lastComment = [self.commentList lastObject];
        self.maxCommentId = [[lastComment objectForKey:@"id"] unsignedIntegerValue];
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
    self.title = NSLocalizedString(@"Comments", nil);

    self.bounces = YES;
    self.shakeToClearEnabled = NO;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = YES;
    self.inverted = NO;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[JYCommentViewCell class] forCellReuseIdentifier:kCommentCellIdentifier];

    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];

    [self.textInputbar.editorTitle setTextColor:[UIColor darkGrayColor]];
    [self.textInputbar.editortRightButton setTintColor:FlatGreen];

    self.textInputbar.autoHideRightButton = NO;
    self.textInputbar.maxCharCount = 1000;
    self.typingIndicatorView.canResignByTouch = YES;

    [self _autoInputMentions];

    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{

}

- (void)_autoInputMentions
{
    if (!self.originalComment)
    {
        return;
    }

    NSMutableString *mentions = [NSMutableString new];

    NSString *originalAuthor = [self.originalComment objectForKey:@"username"];
    NSString *originalHandle = [NSString stringWithFormat:@"@%@", originalAuthor];
    NSString *userHandle = [NSString stringWithFormat:@"@%@", [JYUser currentUser].username];

    if (![userHandle isEqualToString:originalHandle])
    {
        [mentions appendString:[NSString stringWithFormat:@"%@ ", originalHandle]];
    }

    NSRegularExpression *mentionExpression = [NSRegularExpression regularExpressionWithPattern:@"(?:^|\\s)(@\\w+)" options:NO error:nil];

    NSString *text = [self.originalComment objectForKey:@"body"];
    NSArray *matches = [mentionExpression matchesInString:text options:0 range:NSMakeRange(0, [text length])];

    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *mentionedHandle = [text substringWithRange:matchRange];

        if (![userHandle isEqualToString:mentionedHandle])
        {
            [mentions appendString:[NSString stringWithFormat:@"%@ ", mentionedHandle]];
        }
    }

    self.textView.text = mentions;
}

- (void)_scrollTableViewToBottom
{
    NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:self.commentList.count-1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.commentList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCommentViewCell *cell =
    (JYCommentViewCell *)[tableView dequeueReusableCellWithIdentifier:kCommentCellIdentifier forIndexPath:indexPath];

    NSDictionary *comment = (NSDictionary *)[self.commentList objectAtIndex:indexPath.row];
    [cell presentComment:comment];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *comment = (NSDictionary *)[self.commentList objectAtIndex:indexPath.row];
    return [JYCommentViewCell cellHeightForComment:comment];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *orderBodyText = [self.order objectForKey:@"note"];
    return [JYOrderItemView viewHeightForText:orderBodyText withBid:(self.bid != NULL)];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *orderBodyText = [self.order objectForKey:@"note"];
    CGFloat height = [JYOrderItemView viewHeightForText:orderBodyText withBid:(self.bid != NULL)];

    JYOrderItemView *itemView = [[JYOrderItemView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];
    itemView.tinyLabelsHidden = NO;
    itemView.bidLabelHidden = (self.bid == NULL);
    itemView.viewColor = FlatWhite;
    [itemView presentOrder:self.order andBid:self.bid];

    return itemView;
}

#pragma mark - Overriden Method

// Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
- (void)didPressRightButton:(id)sender
{
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];

    [self _postComment];
    [super didPressRightButton:sender];
}

#pragma mark - Network

- (void)_postComment
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"comments"];

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:[self _httpPostCommentParameters]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
//              NSLog(@"Comment POST Success responseObject: %@", responseObject);

              [weakSelf _fetchComments];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              NSString *errorMessage = NSLocalizedString(@"Can't create comment due to network failure, please retry later", nil);
              [RKDropdownAlert title:NSLocalizedString(@"Something wrong ...", nil)
                             message:errorMessage
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
          }
     ];
}

- (void)_fetchComments
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"comments/of/orders"];

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:[self _httpGetCommentParameters]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {

             NSLog(@"comments/of/orders GET success responseObject: %@", responseObject);
             NSArray *newComments = (NSArray *)responseObject;

             if (newComments.count > 0)
             {
                 NSDictionary *lastComment = [newComments lastObject];
                 weakSelf.maxCommentId = [[lastComment objectForKey:@"id"] unsignedIntegerValue];

                 // comments are in ASC order, just append them to the end
                 [weakSelf.commentList addObjectsFromArray:newComments];
             }

             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [KVNProgress dismiss];

             [weakSelf.tableView reloadData];
             [weakSelf _scrollTableViewToBottom];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             [KVNProgress dismiss];

             NSString *errorMessage = NSLocalizedString(@"Can't update comment list due to network failure, please retry later", nil);
             [RKDropdownAlert title:NSLocalizedString(@"Something wrong ...", nil)
                            message:errorMessage
                    backgroundColor:FlatYellow
                          textColor:FlatBlack
                               time:5];
         }
     ];
}

- (NSDictionary *)_httpPostCommentParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    NSString *orderId = [self.order objectForKey:@"id"];
    [parameters setValue:orderId forKey:@"order_id"];
    [parameters setValue:self.textView.text forKey:@"body"];

    return parameters;
}

- (NSDictionary *)_httpGetCommentParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    NSString *orderId = [self.order objectForKey:@"id"];
    [parameters setValue:orderId forKey:@"order_id"];
    [parameters setValue:@(self.maxCommentId) forKey:@"after"];

    return parameters;
}

@end
