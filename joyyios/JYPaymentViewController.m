//
//  JYPaymentViewController.m
//  joyyios
//
//  Created by Ping Yang on 6/18/15.
//  Copyright (c) 2015 Joyy Technologies, Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <KVNProgress/KVNProgress.h>
#import <RKDropdownAlert/RKDropdownAlert.h>

#import "JYButton.h"
#import "JYCreditCardViewCell.h"
#import "JYPaymentViewController.h"
#import "JYUser.h"

@interface JYPaymentViewController ()

@property(nonatomic) NSString *stripeToken;
@property(nonatomic) STPCard *card;
@property(nonatomic) JYCreditCardType cardType;
@property(nonatomic, weak) JYButton *addButton;

@end


static NSString *const kCardCellIdentifier = @"cardCell";

@implementation JYPaymentViewController

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Credit Card", nil);
    self.view.backgroundColor = JoyyWhite;

    self.cardType = JYCreditCardTypeUnrecognized;
    self.card = nil;
    self.stripeToken = nil;

    [self _createSaveButton];

    if ([self _hasSavedCreditCard])
    {
        [self _createTableView];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)_hasSavedCreditCard
{
    return (self.creditCardList != nil && self.creditCardList.count > 0);
}

- (void)_createSaveButton
{
    CGFloat width = CGRectGetWidth(self.view.frame) - 16;
    CGRect frame = CGRectMake(8, 100, width, 45);

    JYButton *button = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault];

    button.backgroundColor = ClearColor;
    button.contentAnimateToColor = FlatGreen;
    button.contentColor = FlatWhite;
    button.cornerRadius = 8;
    button.foregroundAnimateToColor = FlatWhite;
    button.foregroundColor = FlatGreen;
    button.textLabel.font = [UIFont boldSystemFontOfSize:20];
    button.textLabel.text = NSLocalizedString(@"Add A Credit Card", nil);
    [button addTarget:self action:@selector(_addCreditCard) forControlEvents:UIControlEventTouchUpInside];

    self.addButton = button;
    [self.view addSubview:self.addButton];
}

- (void)_createTableView
{
    CGFloat y = CGRectGetMaxY(self.addButton.frame) + 10;

    CGRect frame =  CGRectMake(0, y, CGRectGetWidth(self.view.frame), 500);
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
    tableView.backgroundColor = JoyyWhite;
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[JYCreditCardViewCell class] forCellReuseIdentifier:kCardCellIdentifier];

    self.tableView = tableView;
    [self.view addSubview:self.tableView];
}

- (void)_addCreditCard
{
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    scanViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:scanViewController animated:YES completion:nil];
}

#pragma mark - CardIOPaymentViewControllerDelegate

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)info inPaymentViewController:(CardIOPaymentViewController *)paymentViewController
{
    NSLog(@"Credit card scan succeeded with card number = %@", info.cardNumber);

    self.card = [[STPCard alloc] init];
    self.card.number = info.cardNumber;
    self.card.expMonth = info.expiryMonth;
    self.card.expYear = info.expiryYear;
    self.card.cvc = info.cvv;

    self.cardType = (JYCreditCardType)info.cardType;

    __weak typeof(self) weakSelf = self;
    [[STPAPIClient sharedClient] createTokenWithCard:self.card
                                          completion:^(STPToken *token, NSError *error) {
                                              if (error)
                                              {
                                                  NSString *errorMessage = error.localizedDescription;
                                                  [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                                                                 message:errorMessage
                                                         backgroundColor:FlatYellow
                                                               textColor:FlatBlack
                                                                    time:5];
                                              }
                                              else
                                              {
                                                  [weakSelf dismissViewControllerAnimated:YES completion:nil];
                                                  weakSelf.stripeToken = token.tokenId;
                                                  [weakSelf _submitCreditCard];
                                              }
                                          }];
}

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)paymentViewController
{
    NSLog(@"User cancelled scan");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.creditCardList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JYCreditCardViewCell *cell =
    (JYCreditCardViewCell *)[tableView dequeueReusableCellWithIdentifier:kCardCellIdentifier forIndexPath:indexPath];

    JYCreditCard *card = self.creditCardList[indexPath.row];
    [cell presentCreditCard:card];
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [JYCreditCardViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    JYCreditCard *card = self.creditCardList[indexPath.row];
    if (self.delegate)
    {
        [self.delegate viewControllerDidCreateToken:card.stripeCustomerId];
        [self.delegate viewControllerDidFinish:self];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 100;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self _createHearderView];
}

- (UIView *)_createHearderView
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 100)];
    UILabel *orLabel = [self _createLabel];
    orLabel.text = NSLocalizedString(@"Or", nil);
    [header addSubview:orLabel];

    UILabel *chooseLabel = [self _createLabel];
    chooseLabel.y = 50;
    chooseLabel.text = NSLocalizedString(@"choose a saved credit card:", nil);
    [header addSubview:chooseLabel];

    return header;
}

- (UILabel *)_createLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 50)];
    label.font = [UIFont systemFontOfSize:22];
    label.textColor = FlatBlack;
    label.textAlignment = NSTextAlignmentCenter;

    return label;
}

#pragma mark - Network

- (void)_submitCreditCard
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *token = [NSString stringWithFormat:@"Bearer %@", [JYUser currentUser].token];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    NSString *url = [NSString stringWithFormat:@"%@%@", kUrlAPIBase, @"creditcards"];
    NSMutableDictionary *parameters = [self _submitCreditCardParameters];

    NSLog(@"parameters: %@", parameters);

    [KVNProgress show];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak typeof(self) weakSelf = self;
    [manager POST:url
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Credit card submit success responseObject: %@", responseObject);

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              NSDictionary *result = (NSDictionary *)responseObject;
              NSString *stripeCustomerId = [result valueForKey:@"customer_id"];

              if (weakSelf.delegate)
              {
                  [weakSelf.delegate viewControllerDidCreateToken:stripeCustomerId];
                  [weakSelf.delegate viewControllerDidFinish:weakSelf];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              if (weakSelf.delegate)
              {
                  [weakSelf.delegate viewControllerDidCreateToken:nil];
              }

              NSString *errorMessage = NSLocalizedString(@"Can't save the credit card due to network failure, please retry later", nil);
              [RKDropdownAlert title:NSLocalizedString(kErrorTitle, nil)
                             message:errorMessage
                     backgroundColor:FlatYellow
                           textColor:FlatBlack
                                time:5];
          }
     ];

}

- (NSMutableDictionary *)_submitCreditCardParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    [parameters setValue:@(self.cardType) forKey:@"card_type"];
    [parameters setValue:@(self.card.expYear) forKey:@"expiry_year"];
    [parameters setValue:@(self.card.expMonth) forKey:@"expiry_month"];
    [parameters setValue:self.card.last4 forKey:@"number_last_4"];
    [parameters setValue:[JYUser currentUser].email forKey:@"email"];
    [parameters setValue:self.stripeToken forKey:@"stripe_token"];

    return parameters;
}

@end
