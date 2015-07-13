//
//  JYMenuViewController.m
//  joyyios
//
//  Created by Ping Yang on 7/1/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYMenuViewController.h"
#import "JYMenuViewCell.h"
#import "JYOrdersBidsViewController.h"
#import "JYOrdersHistoryViewController.h"
#import "JYAnonymousViewController.h"
#import "JYPaymentViewController.h"
#import "JYUser.h"


typedef NS_ENUM(NSUInteger, JYMenuItem)
{
    JYMenuItemBids = 0,    // The bids for the active orders 
    JYMenuItemOrders = 1,  // The dealt, started, finished orders
    JYMenuItemHistory = 2, // The paid orders
    JYMenuItemPayment = 3, // Payment method
    JYMenuItemHelp = 4,
    JYMenuItemSettings = 5
};

@interface JYMenuViewController ()

@property(nonatomic) NSArray *stringList;
@property(nonatomic) NSArray *iconList;
@property(nonatomic, weak) UITableView *tableView;

@end


static CGFloat kHeaderHeight = 100;
static NSString *const kMenuCellIdentifier = @"menuCell";


@implementation JYMenuViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.stringList = [NSArray arrayWithObjects:
                       NSLocalizedString(@"BIDS", nil),
                       NSLocalizedString(@"ORDERS", nil),
                       NSLocalizedString(@"HISTORY", nil),
                       NSLocalizedString(@"PAYMENT", nil),
                       NSLocalizedString(@"HELP", nil),
                       NSLocalizedString(@"SETTINGS", nil),
                       nil];
    self.iconList = [NSArray new];

    [self _createTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_createTableView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    tableView.separatorColor = ClearColor;
    tableView.backgroundColor = FlatBlack;
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[JYMenuViewCell class] forCellReuseIdentifier:kMenuCellIdentifier];
    self.tableView = tableView;
    [self.view addSubview:self.tableView];
}

- (UILabel *)_createLabel
{
    CGFloat width = CGRectGetWidth(self.view.frame) - kMarginLeft;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kMarginLeft, 0, width, kHeaderHeight)];
    label.font = [UIFont boldSystemFontOfSize:22];
    label.backgroundColor = FlatBlack;
    label.textColor = FlatWhite;
    label.textAlignment = NSTextAlignmentLeft;

    return label;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.stringList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYMenuViewCell *cell =
    (JYMenuViewCell *)[tableView dequeueReusableCellWithIdentifier:kMenuCellIdentifier forIndexPath:indexPath];

    cell.text = self.stringList[indexPath.row];
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JYMenuViewCell height];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *base = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), kHeaderHeight)];
    UILabel *label = [self _createLabel];
    label.text = [JYUser currentUser].email;

    [base addSubview:label];
    return base;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UIViewController *viewController = nil;

    JYMenuItem selection = (JYMenuItem)indexPath.row;
    switch (selection)
    {
        case JYMenuItemBids:
            viewController = [JYOrdersBidsViewController new];
            break;
        case JYMenuItemOrders:
            viewController = [JYAnonymousViewController new];
            break;
        case JYMenuItemHistory:
            viewController = [JYOrdersHistoryViewController new];
            break;
        case JYMenuItemPayment:
            viewController = [JYPaymentViewController new];
            break;
        case JYMenuItemHelp:
            break;
        case JYMenuItemSettings:
            break;
        default:
            break;
    }

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: viewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}


@end
