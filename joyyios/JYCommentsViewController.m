//
//  JYCommentsViewController.m
//  joyyios
//
//  Created by Ping Yang on 5/20/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYCommentTextView.h"
#import "JYCommentViewCell.h"
#import "JYCommentsViewController.h"
#import "JYOrderItemView.h"


@interface JYCommentsViewController ()

@property(nonatomic, copy) NSDictionary *order;
@property(nonatomic, copy) NSDictionary *bid;
@property(nonatomic) NSMutableArray *commentList;

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
    [self.textInputbar.editortRightButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];

    self.textInputbar.autoHideRightButton = NO;
    self.textInputbar.maxCharCount = 1000;

    self.typingIndicatorView.canResignByTouch = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{

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

#pragma mark - Network

- (void)_postComment
{
//    NSDictionary *parameters = @{@"after" : @(self.maxOrderId)};
//
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
//    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
//
//    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"orders/engaged"];
//
//    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//
//    __weak typeof(self) weakSelf = self;
//    [manager GET:url
//      parameters:parameters
//         success:^(AFHTTPRequestOperation *operation, id responseObject) {
//             //             NSLog(@"orders/engaged fetch success responseObject: %@", responseObject);
//
//             NSMutableArray *newOrderList = [NSMutableArray arrayWithArray:(NSArray *)responseObject];
//
//             if (newOrderList.count > 0)
//             {
//                 NSDictionary *lastOrder = [newOrderList firstObject];
//                 weakSelf.maxOrderId = [[lastOrder objectForKey:@"id"] unsignedIntegerValue];
//
//                 // create comments array for new orders
//                 for (NSUInteger i = 0; i < newOrderList.count; ++i)
//                 {
//                     [weakSelf.commentMatrix insertObject:[NSMutableArray new] atIndex:0];
//                 }
//
//                 [newOrderList addObjectsFromArray:weakSelf.orderList];
//                 weakSelf.orderList = newOrderList;
//             }
//
//             weakSelf.self.fetchThreadCount--;
//
//             if (weakSelf.orderList.count > 0)
//             {
//                 [weakSelf _fetchBids];
//                 [weakSelf _fetchComments];
//             }
//
//             [weakSelf _fetchEndCheck];
//         }
//         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//             weakSelf.fetchThreadCount--;
//             [weakSelf _fetchEndCheck];
//         }
//     ];
}

- (NSDictionary *)_httpCommentsParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
//    [parameters setValue:@(self.maxCommentId) forKey:@"after"];
//    [parameters setValue:orderIds forKey:@"order_id"];

    return parameters;
}

@end
