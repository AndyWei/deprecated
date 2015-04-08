//
//  JYPlacesViewController.m
//  joyyios
//
//  Created by Ping Yang on 4/8/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import "JYPlacesViewCell.h"
#import "JYPlacesViewController.h"
#import "UIImageView+AFNetworking.h"

@interface JYPlacesViewController ()

@property (nonatomic) LPGoogleFunctions *googleFunctions;
@property (nonatomic) NSMutableArray *placesList;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UITextField *searchBar;

@end


@implementation JYPlacesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = FlatWhite;
    self.placesList = [NSMutableArray new];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(_cancel)];

    [self _createSearchBar];
    [self _createTableView];
    [self.searchBar becomeFirstResponder];
}

- (void)_createSearchBar
{
    self.searchBar = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 280, 35)];
    self.searchBar.backgroundColor = ClearColor;
    self.searchBar.borderStyle = UITextBorderStyleRoundedRect;
    self.searchBar.clearButtonMode = UITextFieldViewModeAlways;
    self.searchBar.delegate = self;
    self.searchBar.leftView = [[UIImageView alloc] initWithImage:self.searchBarImage];
    self.searchBar.leftView.frame = CGRectMake(0, 0, 30, 30);
    self.searchBar.leftViewMode = UITextFieldViewModeAlways;
    self.searchBar.placeholder = NSLocalizedString(@"Enter address or place name", nil);

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView: self.searchBar];
}

- (void)_createTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.backgroundColor = FlatWhite;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[JYPlacesViewCell class] forCellReuseIdentifier:@"placesCellIdentifier"];
    [self.view addSubview:self.tableView];
}

- (void)_cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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

    LPPlaceDetails *placeDetails = (LPPlaceDetails *)[self.placesList objectAtIndex:indexPath.row];

    cell.topLabel.text = placeDetails.name;
    cell.bottomLabel.text = placeDetails.formattedAddress;

    [self setImageForCell:cell fromURL:placeDetails.icon];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

#pragma mark - LPGoogleFunctions

- (LPGoogleFunctions *)googleFunctions
{
    if (!_googleFunctions) {
        _googleFunctions = [LPGoogleFunctions new];
        _googleFunctions.googleAPIBrowserKey = kGoogleAPIBrowserKey;
        _googleFunctions.delegate = self;
        _googleFunctions.sensor = YES;
        _googleFunctions.languageCode = @"en";
    }
    return _googleFunctions;
}

- (void)loadPlacesAutocompleteForInput:(NSString *)input
{
    self.searchDisplayController.searchBar.text = input;

    __weak typeof(self) weakSelf = self;
    [self.googleFunctions loadPlacesAutocompleteWithDetailsForInput:input offset:(int)[input length] radius:0 location:nil placeType:LPGooglePlaceTypeGeocode countryRestriction:nil
    successfulBlock:^(NSArray *placesWithDetails)
    {
        NSLog(@"successful");
        weakSelf.placesList = [NSMutableArray arrayWithArray:placesWithDetails];
        [weakSelf.tableView reloadData];
    }
    failureBlock:^(LPGoogleStatus status) {
        NSLog(@"Error - Block: %@", [LPGoogleFunctions getGoogleStatus:status]);
        weakSelf.placesList = [NSMutableArray new];
        [weakSelf.tableView reloadData];
    }];
}

#pragma mark - LPGoogleFunctions Delegate

- (void)googleFunctionsWillLoadPlacesAutocomplate:(LPGoogleFunctions *)googleFunctions forInput:(NSString *)input
{
    NSLog(@"willLoadPlacesAutcompleteForInput: %@", input);
}

- (void)googleFunctions:(LPGoogleFunctions *)googleFunctions didLoadPlacesAutocomplate:(LPPlacesAutocomplete *)placesAutocomplate
{
    NSLog(@"didLoadPlacesAutocomplete - Delegate");
}

- (void)googleFunctions:(LPGoogleFunctions *)googleFunctions errorLoadingPlacesAutocomplateWithStatus:(LPGoogleStatus)status
{
    NSLog(@"errorLoadingPlacesAutocomplateWithStatus - Delegate: %@", [LPGoogleFunctions getGoogleStatus:status]);
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString * inputString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
    if (inputString.length >= 3)
    {
        [self loadPlacesAutocompleteForInput:inputString];
    }

    return YES;
}

#pragma mark - LPImage

- (void)setImageForCell:(JYPlacesViewCell *)cell fromURL:(NSString *)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];

    __weak JYPlacesViewCell *weakCell = cell;
    [cell.iconView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
    {
        weakCell.iconView.image = image;
    } failure:nil];
}

@end
