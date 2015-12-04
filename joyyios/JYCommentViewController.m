//
//  JYCommentViewController.m
//  joyyios
//
//  Created by Ping Yang on 5/20/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <MJRefresh/MJRefresh.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYCommentTextView.h"
#import "JYCommentViewCell.h"
#import "JYCommentViewController.h"

@interface JYCommentViewController ()
@property (nonatomic) JYPost *post;
@property (nonatomic) JYComment *orginalComment;
@property (nonatomic) JYCommentViewCell *sizingCell;
@property (nonatomic) NSInteger networkThreadCount;
@property (nonatomic) NSMutableArray *commentList;
@property (nonatomic) UIImageView *photoView;
@property (nonatomic) UIView *backgroundView;
@end

static NSString *const kCommentCellIdentifier = @"commentCell";

@implementation JYCommentViewController

- (instancetype)initWithPost:(JYPost *)post comment:(JYComment *)originalComment
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self)
    {
        [self.tableView registerClass:[JYCommentViewCell class] forCellReuseIdentifier:kCommentCellIdentifier];
        [self registerClassForTextView:[JYCommentTextView class]];
        _post = post;
        _orginalComment = originalComment;
        _networkThreadCount = 0;
        _commentList = [NSMutableArray arrayWithArray:_post.commentList];

        // enwrap the caption text as a comment
//        if ([_post.caption length] != 0)
//        {
//            JYComment *captionComment = [[JYComment alloc] initWithOwnerId:_post.ownerId content:_post.caption];
//            [_commentList insertObject:captionComment atIndex:0];
//        }
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
    self.title = NSLocalizedString(@"COMMENTS", nil);
    self.view.backgroundColor = JoyyBlack;

    // textInput view
    self.bounces = YES;
    self.shakeToClearEnabled = NO;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = NO;
    self.inverted = NO;

    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    self.rightButton.tintColor = JoyyBlue;
    self.textInputbar.backgroundColor = JoyyBlack;
    self.textInputbar.autoHideRightButton = NO;
    self.typingIndicatorView.canResignByTouch = YES;

    // tableView
    self.tableView.allowsSelection = NO;
    self.tableView.backgroundColor = JoyyBlack;
    self.tableView.backgroundView = self.backgroundView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;

    [self _showBackgroundImage];
    [self _fetchNewComments];

//    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIView *)backgroundView
{
    if (!_backgroundView)
    {
        _backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
        [_backgroundView addSubview:self.photoView];
    }
    return _backgroundView;
}

- (UIImageView *)photoView
{
    if (!_photoView)
    {
        CGFloat y = STATUS_BAR_HEIGHT + NAVIGATION_BAR_HEIGHT;
        _photoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, y, SCREEN_WIDTH, SCREEN_WIDTH)];
        _photoView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _photoView;
}

- (void)_showBackgroundImage
{
    // Fetch network image
    NSURL *url = [NSURL URLWithString:_post.URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    __weak typeof(self) weakSelf = self;
    [self.photoView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
     {
         weakSelf.photoView.image = image;

     } failure:nil];
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
    }
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
    return self.commentList.count; // Use 1 dummy cell to cover the background photo with JoyyBlack50 color
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCommentViewCell *cell =
    (JYCommentViewCell *)[tableView dequeueReusableCellWithIdentifier:kCommentCellIdentifier forIndexPath:indexPath];

    if (indexPath.row < self.commentList.count)
    {
        cell.comment = self.commentList[indexPath.row];
    }
    else
    {
        cell.comment = nil;
    }

    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.commentList.count)
    {
        return 600;
    }

    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)])
    {
        NSOperatingSystemVersion ios8_0_0 = (NSOperatingSystemVersion){8, 0, 0};
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios8_0_0])
        {
            return UITableViewAutomaticDimension;
        }
    }

    if (!self.sizingCell)
    {
        self.sizingCell = [[JYCommentViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"JYCommentViewCell_sizing"];
    }

    // Configure sizing cell for this indexPath
    self.sizingCell.comment = self.commentList[indexPath.row];

    // Make sure the constraints have been added to this cell, since it may have just been created from scratch
    [self.sizingCell setNeedsUpdateConstraints];
    [self.sizingCell updateConstraintsIfNeeded];

    self.sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(self.sizingCell.bounds));

    [self.sizingCell setNeedsLayout];
    [self.sizingCell layoutIfNeeded];

    // Get the actual height required for the cell
    CGSize size = [self.sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

    // Add an extra point to the height to account for the cell separator, which is added between the bottom
    // of the cell's contentView and the bottom of the table view cell.
    CGFloat height = size.height;
    
    return height;
}

#pragma mark - Maintain Table

- (void)_updateTableWithComments:(NSArray *)list toEnd:(BOOL)toEnd
{
    if (!list.count)
    {
        return;
    }

    BOOL firstLoad = self.commentList.count == 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _addCommentsFromList:list toEnd:toEnd];

        if (firstLoad)
        {
            [self.tableView reloadData];
            [self _scrollTableViewToBottom];
        }
        else
        {
            CGSize beforeContentSize = self.tableView.contentSize;
            [self.tableView reloadData];
            CGSize afterContentSize = self.tableView.contentSize;

            CGPoint afterContentOffset = self.tableView.contentOffset;
            CGPoint newContentOffset = CGPointMake(afterContentOffset.x, afterContentOffset.y + afterContentSize.height - beforeContentSize.height);
            self.tableView.contentOffset = newContentOffset;
        }
    });
}

- (void)_addCommentsFromList:(NSArray *)list toEnd:(BOOL)toEnd
{
//    if (!list.count)
//    {
//        return;
//    }
//
//    // The items in commentsList are DESC sorted by id
//    if (toEnd)
//    {
//        for (NSDictionary *dict in [list reverseObjectEnumerator])
//        {
//            JYComment *comment = [JYComment commentWithDictionary:dict];
//            [self.commentList addObject:comment];
//        }
//    }
//    else
//    {
//        for (NSDictionary *dict in list)
//        {
//            JYComment *comment = [JYComment commentWithDictionary:dict];
//            [self.commentList insertObject:comment atIndex:0];
//        }
//    }
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
    [self _networkThreadBegin];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager managerWithToken];
    NSString *url = [NSString apiURLWithPath:@"comment"];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:[self _parametersForCreatingComment]
          success:^(NSURLSessionTask *operation, id responseObject) {
              NSLog(@"Comment POST Success responseObject: %@", responseObject);

              [weakSelf _networkThreadEnd];
//              NSUInteger commentCount = [responseObject unsignedIntegerValueForKey:@"comments"];
//              weakSelf.post.commentCount = commentCount;

              [weakSelf _fetchNewComments];
          }
          failure:^(NSURLSessionTask *operation, NSError *error) {

              [weakSelf _networkThreadEnd];

              [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                             message:error.localizedDescription
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
          }
     ];
}

- (void)_fetchNewComments
{
//    if (self.networkThreadCount > 0)
//    {
//        return;
//    }
//    [self _networkThreadBegin];
//
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//    NSString *url = [NSString apiURLWithPath:@"comment"];
//
//    __weak typeof(self) weakSelf = self;
//    [manager GET:url
//      parameters:[self _parametersForCommentOfPost:toEnd]
//         success:^(NSURLSessionTask *operation, id responseObject) {
//
//             NSLog(@"comment GET success responseObject: %@", responseObject);
//             [weakSelf _updateTableWithComments:responseObject toEnd:toEnd];
//             [weakSelf _networkThreadEnd];
//         }
//         failure:^(NSURLSessionTask *operation, NSError *error) {
//             [weakSelf _networkThreadEnd];
//         }
//     ];
}

- (NSDictionary *)_parametersForCreatingComment
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:self.post.postId forKey:@"post"];
    [parameters setObject:self.textView.text forKey:@"content"];

    return parameters;
}

- (NSDictionary *)_parametersForCommentOfPost:(BOOL)toEnd
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setObject:self.post.postId forKey:@"post"];

//    if (self.commentList.count > 0)
//    {
//        if (toEnd)
//        {
//            JYComment *comment = self.commentList.lastObject;
//            [parameters setValue:@(comment.timestamp) forKey:@"after"];
//        }
//        else
//        {
//            JYComment *comment = self.commentList.firstObject;
//            [parameters setValue:@(comment.timestamp) forKey:@"before"];
//        }
//    }

    return parameters;
}

@end
