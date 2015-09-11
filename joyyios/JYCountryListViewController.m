//
//  JYCountryListViewController.m
//  joyyios
//
//  Created by Ping Yang on 9/11/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

#import "JYCountryListViewController.h"
#import "JYCountryViewCell.h"

@interface JYCountryListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray *countryList;
@property (nonatomic) NSMutableDictionary *countryCodeDict;
@end

static NSString *const kCountryCellIdentifier = @"countryCell";

@implementation JYCountryListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _commonInit];
    [self.view addSubview:self.tableView];
    [self scrollToSelectedRow];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    self.countryList = nil;
    self.countryCodeDict = nil;
}

- (void)_commonInit
{
    NSArray *countryArray = [NSLocale ISOCountryCodes];

    NSLocale *locale = [NSLocale currentLocale];

    self.countryList = [[NSMutableArray alloc] init];
    self.countryCodeDict = [[NSMutableDictionary alloc] init];

    for (NSString *countryCode in countryArray) {

        NSString *displayNameString = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];

        [self.countryList addObject:displayNameString];
        [self.countryCodeDict setObject:countryCode forKey:displayNameString];
    }

    [self.countryList sortUsingSelector:@selector(localizedCompare:)];
}

- (void)scrollToSelectedRow
{
    NSUInteger row = [self.countryList indexOfObject:self.currentCountryName];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = JoyyWhiter;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = YES;
        [_tableView registerClass:[JYCountryViewCell class] forCellReuseIdentifier:kCountryCellIdentifier];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.countryList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCountryViewCell *cell = (JYCountryViewCell *)[tableView dequeueReusableCellWithIdentifier:kCountryCellIdentifier forIndexPath:indexPath];

    NSString *countryName = self.countryList[indexPath.row];
    NSString *countryCode = self.countryCodeDict[countryName];
    NSString *e164Prefix = [NSString e164PrefixForCountryCode:countryCode];

    BOOL selected = [countryName isEqualToString:self.currentCountryName];
    [cell presentCountry:countryName dailCode:e164Prefix selected:selected];

    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *countryName = self.countryList[indexPath.row];
    NSString *countryCode = self.countryCodeDict[countryName];

    NSDictionary *info = @{@"country_code": countryCode};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidChangeCountryCode object:nil userInfo:info];
}

@end
