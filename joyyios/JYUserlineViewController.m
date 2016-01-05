//
//  JYUserlineViewController.m
//  joyyios
//
//  Created by Ping Yang on 12/8/15.
//  Copyright © 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIButton+AFNetworking.h>
#import <MJRefresh/MJRefresh.h>

#import "JYMonth.h"
#import "JYButton.h"
#import "JYCardView.h"
#import "JYComment.h"
#import "JYCommentViewController.h"
#import "JYFilename.h"
#import "JYLocalDataManager.h"
#import "JYPhotoCaptionViewController.h"
#import "JYPost.h"
#import "JYUserlineCell.h"
#import "JYUserlineViewController.h"

@interface JYUserlineViewController () <JYCardViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) JYMonth *month;
@property (nonatomic) JYUser *user;
@property (nonatomic) JYCardView *cardView;
@property (nonatomic) NSInteger networkThreadCount;
@property (nonatomic) NSLayoutConstraint *cardViewHeightConstraint;
@property (nonatomic) NSMutableArray *postList;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kUserlineCellIdentifier = @"userlineCell";
static CGFloat kCardViewDefaultHeight = 150;

@implementation JYUserlineViewController

- (instancetype)initWithUser:(JYUser *)user
{
    if (self = [super init])
    {
        self.user = user;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.user.username;

    self.navigationController.navigationBar.translucent = YES;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    self.networkThreadCount = 0;
    self.postList = [NSMutableArray new];
    self.month = [[JYMonth alloc] initWithDate:[NSDate date]];

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.cardView];

    NSDictionary *views = @{ @"cardView": self.cardView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[cardView]-0-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cardView]-(>=100@500)-|" options:0 metrics:nil views:views]];
    self.cardViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.cardView
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:0.0f
                                                                  constant:kCardViewDefaultHeight];
    [self.view addConstraint:self.cardViewHeightConstraint];
    [self _updateCardViewContent];
    [self _fetchUserline];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 415;
        [_tableView registerClass:[JYUserlineCell class] forCellReuseIdentifier:kUserlineCellIdentifier];

        _tableView.contentInset = UIEdgeInsetsMake(kCardViewDefaultHeight, 0, 0, 0);

        // Setup the pull-up-to-refresh footer
        MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(_fetchUserline)];
        footer.refreshingTitleHidden = YES;
        footer.stateLabel.hidden = YES;
        _tableView.mj_footer = footer;
    }
    return _tableView;
}

- (JYCardView *)cardView
{
    if (!_cardView)
    {
        _cardView = [JYCardView new];
        _cardView.delegate = self;
        [_cardView addBlur];
    }
    return _cardView;
}

- (void)_updateCardViewContent
{
    self.cardView.titleLabel.text = self.user.username;

    NSURLRequest *request = [NSURLRequest requestWithURL:self.user.avatarURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.cardView.avatarButton setImageForState:UIControlStateNormal withURLRequest:request placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse *response, UIImage *image) {

        weakSelf.cardView.coverView.image = image;
        [weakSelf.cardView.avatarButton setImage:image forState:UIControlStateNormal];
    } failure:^(NSError *error) {
         NSLog(@"_updateCardViewContent setImageForState failed with error = %@", error);
    }];
}

- (void)_networkThreadBegin
{
    if (self.networkThreadCount == 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    self.networkThreadCount++;
}

- (void)_networkThreadEnd
{
    self.networkThreadCount--;
    if (self.networkThreadCount <= 0)
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self.tableView.mj_footer endRefreshing];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView
{
    CGFloat offset = (-1) * _tableView.contentOffset.y;

    self.cardViewHeightConstraint.constant = fmax(offset, kCardViewDefaultHeight);

    if (offset < 120)
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.cardView.alpha = 0;
        }];
    }
    else
    {
        self.cardView.alpha = 1.0;
    }

    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
}

#pragma mark - JYCardViewDelegate

- (void)didTapAvatarOnView:(JYCardView *)view
{

}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.postList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYUserlineCell *cell =
    (JYUserlineCell *)[tableView dequeueReusableCellWithIdentifier:kUserlineCellIdentifier forIndexPath:indexPath];

    JYPost *post = self.postList[indexPath.row];
    cell.post = post;

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];

    return cell;
}

#pragma mark - UITableView Delegate

#pragma mark - Maintain table

- (void)_receivedOldPosts:(NSMutableArray *)postList
{
    if ([postList count] == 0) // no more old post, do nothing
    {
        return;
    }

    [self.postList addObjectsFromArray:postList];
    [self.tableView reloadData];
    [self.tableView.mj_footer endRefreshing];
}

#pragma mark - Network

- (void)_fetchUserline
{
    if (self.networkThreadCount > 0)
    {
        return;
    }

    uint64_t monthValue = self.month.value;
    self.month = [self.month prev];
    [self _fetchUserlineOfMonth:monthValue];
}

- (void)_fetchUserlineOfMonth:(uint64_t)month
{
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];

    NSString *url = [NSString apiURLWithPath:@"post/userline"];
    NSDictionary *parameters = @{@"userid": @([self.user.userId unsignedLongLongValue]), @"month": @(month)};

    __weak typeof(self) weakSelf = self;
    [manager GET:url
      parameters:parameters
         success:^(NSURLSessionTask *operation, id responseObject) {
             NSLog(@"post/userline fetch success responseObject: %@", responseObject);

             // the post json is in ASC order, so iterate reversely
             NSMutableArray *postList = [NSMutableArray new];
             for (NSDictionary *dict in [responseObject reverseObjectEnumerator])
             {
                 NSError *error = nil;
                 JYPost *post = (JYPost *)[MTLJSONAdapter modelOfClass:JYPost.class fromJSONDictionary:dict error:&error];
                 if (post)
                 {
                     [postList addObject:post];
                 }
             }

             [weakSelf _receivedOldPosts:postList];
             [weakSelf _networkThreadEnd];
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             NSLog(@"Error: post/userline fetch failed with error: %@", error);
             [weakSelf _networkThreadEnd];
         }
     ];
}

@end
