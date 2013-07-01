//
//  ViewController.m
//  ios-sdk
//
//  Created by Javier Alvarez on 6/29/13.
//  Copyright (c) 2013 Javier Alvarez. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "ViewController.h"

@interface ViewController () {

    BOOL keyboardIsShown;
    
}

@property (strong, nonatomic) MLMeli *meli;

@property (strong, nonatomic) NSString *clientId;
@property (strong, nonatomic) NSString *clientSecret;
@property (strong, nonatomic) NSString *redirectURI;
@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *refreshToken;
@property (strong, nonatomic) NSString *callbackURI;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clientId = @"123";
    self.clientSecret = @"a secret";
    self.redirectURI = @"ha redirect_uri";
    self.accessToken = @"a access_token";
    self.refreshToken = @"a refresh_token";
    
    self.meli = [[MLMeli alloc] initWithAppId:self.clientId andSecret:self.clientSecret andAccessToken:self.accessToken andRefreshToken:self.refreshToken];
    
    self.meli.delegate = self;
    
    [self.scrollView setScrollEnabled:YES];
    [self.scrollView setContentSize:CGSizeMake(320,900)];
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
    keyboardIsShown = NO;
    //make contentSize bigger than your scrollSize (you will need to figure out for your own use case)
    CGSize scrollContentSize = CGSizeMake(320, 345);
    self.scrollView.contentSize = scrollContentSize;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)getAuthURL:(id)sender {
    NSString *authUrl = [self.meli getAuthUrlWithCallbackURI:self.redirectURI];
    self.responseLabel.text = authUrl;
    NSLog(@"%@", authUrl);
}

- (IBAction)authorize:(id)sender {
    [self.meli authorizeWihtCode:self.codeText.text andRedirectURI:self.redirectURI];
}

- (IBAction)doRefreshAccessToken:(id)sender {
    [self.meli doRefreshToken];
}

- (IBAction)doGet:(id)sender {
    [self.meli getPath:@"/sites/MLA" parameters:nil];
}

- (IBAction)doPost:(id)sender {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:self.accessToken forKey:@"access_token"];

    NSMutableArray *pictures = [[NSMutableArray alloc] init];
    NSMutableDictionary *picture = [[NSMutableDictionary alloc] init];
    [picture setValue:@"http://upload.wikimedia.org/wikipedia/commons/f/fd/Ray_Ban_Original_Wayfarer.jpg" forKey:@"source"];
    [pictures addObject:picture];
    picture = [[NSMutableDictionary alloc] init];
    [picture setValue:@"http://upload.wikimedia.org/wikipedia/commons/a/ab/Teashades.gif" forKey:@"source"];
    [pictures addObject:picture];

    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    [body setValue:@"new" forKey:@"condition"];
    [body setValue:@"60 dias" forKey:@"warranty"];
    [body setValue:@"ARS" forKey:@"currency_id"];
    [body setValue:@"true" forKey:@"accepts_mercadopago"];
    [body setValue:@"Lindo Ray_Ban_Original_Wayfarer" forKey:@"description"];
    [body setValue:@"bronze" forKey:@"listing_type_id"];
    [body setValue:@"Test - (it is a testing item) Gafas Ray Ban Aviator estreno !!!" forKey:@"title"];
    [body setValue:[NSNumber numberWithInt:64] forKey:@"available_quantity"];
    [body setValue:[NSNumber numberWithInt:289] forKey:@"price"];
    [body setValue:@"Acompaña 3 Pares De Lentes!! Compra 100% Segura" forKey:@"subtitle"];
    [body setValue:@"buy_it_now" forKey:@"buying_mode"];
    [body setValue:@"MLA3530" forKey:@"category_id"];
    [body setValue:pictures forKey:@"pictures"];
    
    [self.meli postPath:@"/items" parameters:parameters body:body];
}

- (IBAction)doPut:(id)sender {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:self.accessToken forKey:@"access_token"];
    
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    [body setValue:[NSNumber numberWithInt:10] forKey:@"available_quantity"];
    [body setValue:[NSNumber numberWithInt:280] forKey:@"price"];
    
    [self.meli putPath:@"/items/123" parameters:parameters body:body];
}

- (IBAction)doDelete:(id)sender {
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:self.accessToken forKey:@"access_token"];
    
    [self.meli deletePath:@"/questions/123" parameters:parameters];
}

#pragma mark - Delegate Implementation

- (void)meliClient:(MLMeli *)client didUpdateWithData:(id)data
{
    self.responseLabel.text = [NSString stringWithFormat:@"STATUS: %@\n%@", [data objectForKey:MLKeyResponseHTTPCode], [data description]];
    NSLog(@"%@", [data description]);
}

- (void)meliClient:(MLMeli *)client didFailWithError:(NSError *)error
{
    self.responseLabel.text = [error description];
    NSLog(@"%@", [error description]);
}

#pragma mark - Input

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Keyboard positioning

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidUnload {
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)dealloc {
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)keyboardWillHide:(NSNotification *)n
{
    NSDictionary* userInfo = [n userInfo];
    
    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    
    // resize the scrollview
    CGRect viewFrame = self.scrollView.frame;

    viewFrame.size.height += (keyboardSize.height);
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];

    [UIView setAnimationDuration:0.3];
    [self.scrollView setFrame:viewFrame];
    [UIView commitAnimations];
    
    keyboardIsShown = NO;
}

- (void)keyboardWillShow:(NSNotification *)n
{
    if (keyboardIsShown) {
        return;
    }
    
    NSDictionary* userInfo = [n userInfo];
    
    // get the size of the keyboard
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // resize the noteView
    CGRect viewFrame = self.scrollView.frame;

    viewFrame.size.height -= (keyboardSize.height);
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];

    [UIView setAnimationDuration:0.3];
    [self.scrollView setFrame:viewFrame];
    [UIView commitAnimations];
    
    keyboardIsShown = YES;
}
@end
