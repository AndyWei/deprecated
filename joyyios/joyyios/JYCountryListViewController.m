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
@property (nonatomic) NSMutableArray *countryArrays;
@property (nonatomic) NSMutableDictionary *countryCodeDict;
@end

static NSString *const kCountryCellIdentifier = @"countryCell";

@implementation JYCountryListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _initCountryList];

    [self.view addSubview:self.tableView];
    [self scrollToSelectedRow];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    self.countryArrays = nil;
    self.countryCodeDict = nil;
}

- (void)_initCountryList
{
    // Get sorted country name list
    NSArray *countryCodes = [NSLocale ISOCountryCodes];
    NSLocale *locale = [NSLocale currentLocale];
    NSMutableArray *countryNames = [[NSMutableArray alloc] initWithCapacity:300];
    self.countryCodeDict = [[NSMutableDictionary alloc] init];

    for (NSString *countryCode in countryCodes) {

        NSString *displayNameString = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];

        [countryNames addObject:displayNameString];
        [self.countryCodeDict setObject:countryCode forKey:displayNameString];
    }

    [countryNames sortUsingSelector:@selector(localizedCompare:)];

    // Construct countryArrays
    // self.countryArrays is a list of lists. Use countryArrays[section][row] to get a country name
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];

    NSInteger highSection = [[collation sectionTitles] count];
    self.countryArrays = [NSMutableArray arrayWithCapacity:highSection];
    for (int i = 0; i < highSection; i++)
    {
        NSMutableArray *countryArray = [NSMutableArray arrayWithCapacity:1];
        [self.countryArrays addObject:countryArray];
    }

    // Fill in countries
    for (NSString *countryName in countryNames)
    {
        NSInteger section = [collation sectionForObject:countryName collationStringSelector:@selector(self)];
        NSMutableArray *array = [self.countryArrays objectAtIndex:section];
        [array addObject:countryName];
    }
}

- (void)scrollToSelectedRow
{
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];

    NSInteger section = [collation sectionForObject:self.currentCountryName collationStringSelector:@selector(self)];
    NSMutableArray *array = [self.countryArrays objectAtIndex:section];

    if (array)
    {
        NSUInteger row = [array indexOfObject:self.currentCountryName];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = JoyyWhitePure;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = YES;
        [_tableView registerClass:[JYCountryViewCell class] forCellReuseIdentifier:kCountryCellIdentifier];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.countryArrays count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *array = [self.countryArrays objectAtIndex:section];
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCountryViewCell *cell = (JYCountryViewCell *)[tableView dequeueReusableCellWithIdentifier:kCountryCellIdentifier forIndexPath:indexPath];

    NSArray *array = [self.countryArrays objectAtIndex:indexPath.section];
    NSString *countryName =  [array objectAtIndex:indexPath.row];
    NSString *countryCode = self.countryCodeDict[countryName];
    NSString *dialingCode = [NSString dialingCodeForCountryCode:countryCode];

    BOOL selected = [countryName isEqualToString:self.currentCountryName];
    [cell presentCountry:countryName dialingCode:dialingCode selected:selected];

    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *array = [self.countryArrays objectAtIndex:section];

    if (array && [array count] > 0)
    {
        return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSArray *array = [self.countryArrays objectAtIndex:indexPath.section];
    NSString *countryName =  [array objectAtIndex:indexPath.row];
    NSString *countryCode = self.countryCodeDict[countryName];

    NSDictionary *info = @{@"country_code": countryCode};
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidChangeCountryCode object:nil userInfo:info];
}

@end
