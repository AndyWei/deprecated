//
//  JYPlacesViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/8/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPlacesViewCell.h"
#import "JYPlacesViewController.h"

@interface JYPlacesViewController ()

@property (nonatomic) MKLocalSearch *search;
@property (nonatomic) NSArray *placesList;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UITextField *searchBar;

@end


@implementation JYPlacesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = FlatWhite;
    self.placesList = [NSArray new];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(_close)];

    [self _createSearchBar];
    [self _createTableView];
    [self.searchBar becomeFirstResponder];
}

- (void)_createSearchBar
{
    UITextField *searchBar = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 280, 35)];
    searchBar.backgroundColor = ClearColor;
    searchBar.borderStyle = UITextBorderStyleRoundedRect;
    searchBar.clearButtonMode = UITextFieldViewModeAlways;
    searchBar.delegate = self;
    searchBar.leftView = [[UIImageView alloc] initWithImage:self.searchBarImage];
    searchBar.leftView.frame = CGRectMake(0, 0, 30, 30);
    searchBar.leftViewMode = UITextFieldViewModeAlways;
    searchBar.placeholder = NSLocalizedString(@"Enter address or place name", nil);

    self.searchBar = searchBar;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView: self.searchBar];
}

- (void)_createTableView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    tableView.backgroundColor = FlatWhite;
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[JYPlacesViewCell class] forCellReuseIdentifier:@"placesCellIdentifier"];

    self.tableView = tableView;
    [self.view addSubview:self.tableView];
}

- (void)_close
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)_searchForInput:(NSString *)string
{
    if (self.search)
    {
        [self.search cancel];
    }

    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = string;

    request.region = MKCoordinateRegionMakeWithDistance(self.searchCenter, 30000, 30000);

    self.search = [[MKLocalSearch alloc] initWithRequest:request];

    __weak typeof(self) weakSelf = self;
    [self.search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
    {
        weakSelf.search = nil;

        if (error)
        {
            NSLog(@"error = %@", error);
            return;
        }

        weakSelf.placesList = response.mapItems;
        [weakSelf.tableView reloadData];
    }];
}

- (NSString *)_imageNameForMapItem:(MKMapItem *)item
{
    NSString *defaultName = @"search";

    NSValue *place = [item valueForKey:@"place"];
    NSArray *businessArray = (NSArray *)[place valueForKey:@"business"];

    if (!businessArray || businessArray.count == 0)
    {
        return defaultName;
    }

    id business = businessArray[0];
    NSArray *localizedCategoriesArray = [business valueForKey:@"localizedCategories"];

    if (!localizedCategoriesArray || localizedCategoriesArray.count == 0)
    {
        return defaultName;
    }

    id localizedCategory = localizedCategoriesArray[0];
    NSArray *localizedNamesArray = [localizedCategory valueForKey:@"localizedNames"];

    if (!localizedNamesArray || localizedNamesArray.count == 0)
    {
        return defaultName;
    }

    id localizedName = localizedNamesArray[0];

    NSString *name = [localizedName valueForKey:@"name"];

    if (!name)
    {
        return defaultName;
    }
    else if ([name isEqualToString:@"Shopping"] || [name isEqualToString:@"Food"] || [name isEqualToString:@"Grocery"])
    {
        return @"shopping";
    }
    else if ([name isEqualToString:@"Restaurants"])
    {
        return @"restaurant";
    }
    else if ([name isEqualToString:@"Health and Medical"] || [name isEqualToString:@"Hospitals"])
    {
        return @"hospital";
    }

    return defaultName;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.placesList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYPlacesViewCell *cell =
    (JYPlacesViewCell *)[tableView dequeueReusableCellWithIdentifier:@"placesCellIdentifier" forIndexPath:indexPath];

    MKMapItem *item = (MKMapItem *)[self.placesList objectAtIndex:indexPath.row];

    cell.topLabel.text = item.name;
    cell.bottomLabel.text = (item.placemark)? item.placemark.title: NSLocalizedString(@"Current Place", nil);
    cell.iconView.image = [UIImage imageNamed:[self _imageNameForMapItem:item]];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MKMapItem *item = (MKMapItem *)[self.placesList objectAtIndex:indexPath.row];
    [self.delegate placesViewController:self placemarkSelected:item.placemark];
    [self _close];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString * inputString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
    if (inputString.length >= 3)
    {
        [self _searchForInput:inputString];
    }

    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

@end
