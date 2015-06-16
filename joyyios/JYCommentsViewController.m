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

#import "JYBid.h"
#import "JYComment.h"
#import "JYCommentTextView.h"
#import "JYCommentViewCell.h"
#import "JYCommentsViewController.h"
#import "JYOrderCard.h"
#import "JYUser.h"

@interface JYCommentsViewController ()

@property(nonatomic) JYOrder *order;
@property(nonatomic) NSMutableArray *commentList;
@property(nonatomic) NSUInteger maxCommentId;

@end

static NSString *const kCommentCellIdentifier = @"commentCell";

@implementation JYCommentsViewController

- (instancetype)initWithOrder:(JYOrder *)order
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self)
    {
        [self registerClassForTextView:[JYCommentTextView class]];
        self.order = order;
        self.commentList = [NSMutableArray arrayWithArray:order.comments];
        self.originalCommentIndex = -1;

        JYComment *lastComment = [self.commentList lastObject];
        self.maxCommentId = lastComment.commentId;
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
    self.shouldScrollToBottomAfterKeyboardShows = NO;
    self.inverted = NO;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[JYCommentViewCell class] forCellReuseIdentifier:kCommentCellIdentifier];

    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];

    [self.textInputbar.editorTitle setTextColor:[UIColor darkGrayColor]];
    [self.textInputbar.editortRightButton setTintColor:FlatGreen];

    self.textInputbar.autoHideRightButton = NO;
    self.textInputbar.maxCharCount = 1000;
    self.typingIndicatorView.canResignByTouch = YES;

    [self _autoFillMentions];

    [self _scrollTableViewToBottom];
    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{

}

- (void)_autoFillMentions
{
    if (self.originalCommentIndex < 0)
    {
        return;
    }

    NSMutableString *mentions = [NSMutableString new];

    JYComment *orginalComment = self.commentList[self.originalCommentIndex];
    NSString *originalAuthor = orginalComment.username;
    NSString *originalHandle = [NSString stringWithFormat:@"@%@", originalAuthor];
    NSString *userHandle = [NSString stringWithFormat:@"@%@", [JYUser currentUser].username];

    if (![userHandle isEqualToString:originalHandle])
    {
        [mentions appendString:[NSString stringWithFormat:@"%@ ", originalHandle]];
    }

    NSRegularExpression *mentionExpression = [NSRegularExpression regularExpressionWithPattern:@"(?:^|\\s)(@\\w+)" options:NO error:nil];

    NSString *text = orginalComment.body;
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
    if (self.commentList.count > 0)
    {
        NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:self.commentList.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
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

    [cell presentComment:self.commentList[indexPath.row]];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JYCommentViewCell cellHeightForComment:self.commentList[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [JYOrderCard cardHeightForOrder:self.order withAddress:NO andBid:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat height = [JYOrderCard cardHeightForOrder:self.order withAddress:NO andBid:YES];

    JYOrderCard *card = [[JYOrderCard alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), height)];
    card.tinyLabelsHidden = NO;
    [card presentOrder:self.order withAddress:NO andBid:YES];
    card.backgroundColor = self.order.bidColor;
    return card;
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

              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidCreateComment object:nil];
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
             for (NSDictionary *dict in responseObject)
             {
                 JYComment *newComment = [[JYComment alloc] initWithDictionary:dict];
                 [weakSelf.commentList addObject:newComment];
                 weakSelf.maxCommentId = newComment.commentId;
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
             [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
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

    [parameters setObject:@(self.order.orderId) forKey:@"order_id"];
    [parameters setValue:self.textView.text forKey:@"body"];

    return parameters;
}

- (NSDictionary *)_httpGetCommentParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:@(self.order.orderId) forKey:@"order_id"];
    [parameters setValue:@(self.maxCommentId) forKey:@"after"];

    return parameters;
}

@end
