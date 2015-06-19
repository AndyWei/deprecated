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
#import <PaymentKit/PTKView.h>

#import "JYButton.h"
#import "JYPaymentViewController.h"
#import "JYUser.h"

@interface JYPaymentViewController () <PTKViewDelegate>

@property(nonatomic) NSString *stripeToken;
@property(nonatomic, weak) JYButton *saveButton;
@property(nonatomic, weak) PTKView *paymentView;

@end

@implementation JYPaymentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.stripeToken = nil;
    [self _createPaymentView];
    [self _createSaveButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)_createPaymentView
{
    PTKView *view = [[PTKView alloc] initWithFrame:CGRectMake(8, 80, 290, 55)];
    self.paymentView = view;
    self.paymentView.delegate = self;

    [self.view addSubview:self.paymentView];
}

- (void)_createSaveButton
{
    CGFloat x = CGRectGetMaxX(self.paymentView.frame) + 8;
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] applicationFrame]) - x - 8;
    CGRect frame = CGRectMake(x, 80, width, 45);

    JYButton *button = [[JYButton alloc] initWithFrame:frame buttonStyle:JYButtonStyleDefault];

    button.backgroundColor = ClearColor;
    button.contentAnimateToColor = FlatGreen;
    button.contentColor = FlatWhite;
    button.cornerRadius = 8;
    button.foregroundAnimateToColor = FlatWhite;
    button.foregroundColor = FlatGreen;
    button.textLabel.font = [UIFont boldSystemFontOfSize:16];
    button.textLabel.text = NSLocalizedString(@"Save", nil);
    [button addTarget:self action:@selector(_save) forControlEvents:UIControlEventTouchUpInside];

    self.saveButton = button;
    self.saveButton.enabled = NO;
    [self.view addSubview:self.saveButton];
}

- (void)_save
{
    STPCard *card = [[STPCard alloc] init];
    card.number = self.paymentView.card.number;
    card.expMonth = self.paymentView.card.expMonth;
    card.expYear = self.paymentView.card.expYear;
    card.cvc = self.paymentView.card.cvc;

    __weak typeof(self) weakSelf = self;
    [[STPAPIClient sharedClient] createTokenWithCard:card
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
                                                  weakSelf.stripeToken = token.tokenId;
                                                  [weakSelf _submitCreditCard];
                                              }
                                          }];
}

#pragma mark - PTKViewDelegate

- (void)paymentView:(PTKView *)view withCard:(PTKCard *)card isValid:(BOOL)valid
{
    self.saveButton.enabled = valid;
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
              [weakSelf.delegate viewController:weakSelf didCreateToken:stripeCustomerId];
              [weakSelf.delegate viewControllerDidFinish:weakSelf];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {

              [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
              [KVNProgress dismiss];

              [weakSelf.delegate viewController:weakSelf didCreateToken:nil];
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

    [parameters setValue:@(self.paymentView.card.expYear) forKey:@"expire_year"];
    [parameters setValue:@(self.paymentView.card.expMonth) forKey:@"expire_month"];
    [parameters setValue:self.paymentView.card.last4 forKey:@"number_last_4"];
    [parameters setValue:[JYUser currentUser].email forKey:@"email"];
    [parameters setValue:self.stripeToken forKey:@"stripe_token"];

    return parameters;
}

@end
