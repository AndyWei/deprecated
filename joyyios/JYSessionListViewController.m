//
//  JYSessionListViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/27/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYSessionListViewCell.h"
#import "JYSessionListViewController.h"
#import "JYSessionViewController.h"
#import "JYXmppManager.h"

@interface JYSessionListViewController () <NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSFetchedResultsController *fetcher;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kContactCellIdentifier = @"contactCell";

@implementation JYSessionListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Chat", nil);

    self.view.backgroundColor = JoyyWhite;
    self.tableView.backgroundColor = JoyyWhite;

    // Connect to Message server
    [[JYXmppManager sharedInstance] xmppUserLogin:nil];

    // Hide the "Back" text on the pushed view navigation bar
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];

    // Start fetch data
    self.fetcher = [JYXmppManager fetcherOfSessions];
    self.fetcher.delegate = self;
    NSError *error = nil;
    [self.fetcher performFetch:&error];
    if (error)
    {
        NSLog(@"fetcher performFetch error = %@", error);
    }

    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = JoyyBlack;
        _tableView.showsHorizontalScrollIndicator = NO;
        [_tableView registerClass:[JYSessionListViewCell class] forCellReuseIdentifier:kContactCellIdentifier];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger number = self.fetcher.sections.count;
    return number;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger number = [[self.fetcher.sections objectAtIndex:section] numberOfObjects];
    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYSessionListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kContactCellIdentifier forIndexPath:indexPath];

    cell.contact = [self.fetcher objectAtIndexPath:indexPath];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYSessionViewController *viewController = [JYSessionViewController new];
    JYSessionListViewCell *cell = (JYSessionListViewCell *)[tableView cellForRowAtIndexPath:indexPath];

    if (cell.person)
    {
        viewController.thatPerson = cell.person;
        [self.navigationController pushViewController:viewController animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else
    {
        NSLog(@"Warning: The person object is not available, cannot push message view controller");
        // Use animation to tell user the table row has been selected 
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

// When a message received , XMPPFramework will archive the message to CoreData storage, and update contacts.
// Thus the controllerDidChangeContent will be triggered
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}
@end
