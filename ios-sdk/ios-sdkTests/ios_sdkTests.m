//
//  ios_sdkTests.m
//  ios-sdkTests
//
//  Created by Javier Alvarez on 6/29/13.
//  Copyright (c) 2013 Javier Alvarez. All rights reserved.
//

#import "ios_sdkTests.h"
#import "MLMeli.h"

typedef enum {

    AuthorizeTask = 1,
    RefreshTokenTask = 2,
    GetTask = 3,
    PostTask = 4,
    PutTask = 5,
    DeleteTask = 6
    
} TaskType;

@interface ios_sdkTests () {

    BOOL taskComplete;
    TaskType taskType;

}

@property (strong, nonatomic) MLMeli *meli;

@property (strong, nonatomic) NSString *clientId;
@property (strong, nonatomic) NSString *clientSecret;
@property (strong, nonatomic) NSString *redirectURI;
@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *refreshToken;

- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs;

@end

@implementation ios_sdkTests

- (void)setUp
{
    [super setUp];

    self.clientId = @"123";
    self.clientSecret = @"a secret";
    self.redirectURI = @"a redirect_uri";
    self.accessToken = @"a access_token";
    self.refreshToken = @"a refresh_token";
    
    self.meli = [[MLMeli alloc] initWithAppId:self.clientId andSecret:self.clientSecret andAccessToken:self.accessToken andRefreshToken:self.refreshToken];

    self.meli.delegate = self;
    
    taskComplete = NO;
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testGetAuthUrl
{
    NSString *authUrl = [self.meli getAuthUrlWithCallbackURI:self.redirectURI];
    
    NSString *expectedAuthUrl = [NSString stringWithFormat:@"https://auth.mercadolibre.com.ar/authorization?response_type=code&client_id=%@&redirect_uri=%@",
                                 self.clientId, self.redirectURI];
    STAssertTrue([authUrl isEqualToString:expectedAuthUrl] , @"getAuthUrlWithCallbackURI fails");
}

- (void)testAuthorize
{
    taskType = AuthorizeTask;
    [self.meli authorizeWihtCode:@"a code" andRedirectURI:self.redirectURI];
    [self waitForCompletion:30];
}

- (void)testRefreshAccessToken
{
    taskType = RefreshTokenTask;
    [self.meli doRefreshToken];
    [self waitForCompletion:30];    
}

- (void)testGet
{
    taskType = GetTask;
    [self.meli getPath:@"/sites/MLB" parameters:nil];
    [self waitForCompletion:30];
}

- (void)testPost
{
    taskType = PostTask;
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
    [self waitForCompletion:30];
}

- (void)testPut
{
    taskType = PutTask;
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:self.accessToken forKey:@"access_token"];
    
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    [body setValue:[NSNumber numberWithInt:10] forKey:@"available_quantity"];
    [body setValue:[NSNumber numberWithInt:280] forKey:@"price"];
    
    [self.meli putPath:@"/items/123" parameters:parameters body:body];
    [self waitForCompletion:30];
}

- (void)testDelete
{
    taskType = DeleteTask;
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:self.accessToken forKey:@"access_token"];
    
    [self.meli deletePath:@"/questions/123" parameters:parameters];
    [self waitForCompletion:30];
}

#pragma mark - Delegate Implementation

- (void)meliClient:(MLMeli *)client didUpdateWithData:(id)data
{
    NSString *expectedAccessToken;
    NSString *expectedRefreshToken;
    switch (taskType) {
        case AuthorizeTask:
            expectedAccessToken = @"valid access token";
            STAssertTrue([self.meli.accessToken isEqualToString:expectedAccessToken] , @"authorizeWihtCode:andRedirectURI fails : invalid access token");
            expectedRefreshToken = @"valid refresh token";
            STAssertTrue([self.meli.refreshToken isEqualToString:expectedRefreshToken] , @"authorizeWihtCode:andRedirectURI fails : invalid refresh token");
            break;
        case RefreshTokenTask:
            expectedAccessToken = @"valid access token";
            STAssertTrue([self.meli.accessToken isEqualToString:expectedAccessToken] , @"refreshToken fails : invalid access token");
            expectedRefreshToken = @"valid refresh token";
            STAssertTrue([self.meli.refreshToken isEqualToString:expectedRefreshToken] , @"refreshToken fails : invalid refresh token");
            break;
        case GetTask:
            STAssertNotNil(data, @"data should be instantiated");
            break;
        case PostTask:
            STAssertNotNil(data, @"data should be instantiated");
            break;
        case PutTask:
            STAssertNotNil(data, @"data should be instantiated");
            break;
        case DeleteTask:
            STAssertNotNil(data, @"data should be instantiated");
            break;
        default:
            break;
    }
    taskComplete = YES;
}

- (void)meliClient:(MLMeli *)client didFailWithError:(NSError *)error
{
    STAssertNotNil(error, @"error should be instantiated");
    taskComplete = YES;
}

#pragma mark helpers

- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
    
    do
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if ([timeoutDate timeIntervalSinceNow] < 0.0)
        {
            break;
        }
    }
    while (!taskComplete);
    
    return taskComplete;
}

@end
