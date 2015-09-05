//
//  JYMessageListViewController.m
//  joyyios
//
//  Created by Ping Yang on 8/27/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYMessageContactViewCell.h"
#import "JYMessageListViewController.h"
#import "JYMessageViewController.h"
#import "JYXmppManager.h"

@interface JYMessageListViewController () <NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) NSFetchedResultsController *fetcher;
@property (nonatomic) UITableView *tableView;
@end

static NSString *const kContactCellIdentifier = @"contactCell";

@implementation JYMessageListViewController

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
    self.fetcher = [JYXmppManager fetcherForForContacts];
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
        [_tableView registerClass:[JYMessageContactViewCell class] forCellReuseIdentifier:kContactCellIdentifier];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetcher.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.fetcher.sections objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYMessageContactViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kContactCellIdentifier forIndexPath:indexPath];

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
    JYMessageViewController *viewController = [JYMessageViewController new];
    JYMessageContactViewCell *cell = (JYMessageContactViewCell *)[tableView cellForRowAtIndexPath:indexPath];

    if (cell.person)
    {
        viewController.person = cell.person;
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
