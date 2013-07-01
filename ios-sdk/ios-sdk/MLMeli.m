//
//  MLMeli.m
//  ios-sdk
//
//  Created by Javier Alvarez on 6/29/13.
//  Copyright (c) 2013 Javier Alvarez. All rights reserved.
//

#import "MLMeli.h"
#import "MLHTTPConnection.h"

NSString * const MLMeliErrorDomain = @"MLMeliErrorDomain";
NSString * const MLKeyResponseAccessToken = @"access_token";
NSString * const MLKeyResponseExpiresIn = @"expires_in";
NSString * const MLKeyResponseRefreshToken = @"refresh_token";

@interface MLMeli ()

@property (strong, nonatomic) NSString *appId;
@property (strong, nonatomic) NSString *secret;

@property (readwrite, nonatomic, strong) NSMutableData *responseData;

- (void)execute:(NSInvocation *)action;

- (void)execute:(NSInvocation *)action
        success:(SuccessBlock)success
        failure:(FailureBlock)failure;

- (void)executeWithBody:(NSInvocation *)action;

- (NSInvocation *)invocationForSelector:(SEL)sel
                                andPath:(NSString *)path
                             parameters:(NSDictionary *)parameters
                                   body:(NSDictionary *)body;

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(SuccessBlock)success
         failure:(FailureBlock)failure;


- (SuccessBlock)successRequestTokenBlock;
- (SuccessBlock)successBlock;
- (FailureBlock)failureBlock;

@end

@implementation MLMeli

- (id)initWithAppId:(NSString *)appId
          andSecret:(NSString *)secret
     andAccessToken:(NSString *)accessToken
    andRefreshToken:(NSString *)refreshToken
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.appId = appId;
    self.secret = secret;
    self.accessToken = accessToken;
    self.refreshToken = refreshToken;
    
    return self;
}

- (SuccessBlock)successRequestTokenBlock
{
    return ^(id responseObject) {
        id body = [responseObject valueForKey:MLKeyResponseBody];
        if ([[responseObject valueForKey:MLKeyResponseHTTPCode] intValue] == kHTTPStatusCodeOK) {
            self.accessToken = [body valueForKey:MLKeyResponseAccessToken];
            self.refreshToken = [body valueForKey:MLKeyResponseRefreshToken];
            
            if([self.delegate respondsToSelector:@selector(meliClient:didUpdateWithData:)])
                [self.delegate meliClient:self didUpdateWithData:responseObject];
        }
        else {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[body valueForKey:MLKeyResponseError] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[body valueForKey:MLKeyResponseMessage] forKey:NSLocalizedFailureReasonErrorKey];
            NSError *error = [[NSError alloc] initWithDomain:MLMeliErrorDomain code:[[body valueForKey:MLKeyResponseStatus] intValue] userInfo:userInfo];
            
            if([self.delegate respondsToSelector:@selector(meliClient:didFailWithError:)])
                [self.delegate meliClient:self didFailWithError:error];
        }
    };
}

- (SuccessBlock)successBlock
{
    return ^(id responseObject) {
        if([self.delegate respondsToSelector:@selector(meliClient:didUpdateWithData:)])
            [self.delegate meliClient:self didUpdateWithData:responseObject];
    };
}

- (FailureBlock)failureBlock
{
    return ^(NSError *error) {
        if([self.delegate respondsToSelector:@selector(meliClient:didFailWithError:)])
            [self.delegate meliClient:self didFailWithError:error];
    };
}

// AUTH METHODS
- (NSString*)getAuthUrlWithCallbackURI:(NSString *)callbackURI
{
    return [NSString stringWithFormat:@"%@?response_type=code&client_id=%@&redirect_uri=%@", MLAuthUrl, self.appId, callbackURI];
}

- (void)authorizeWihtCode:(NSString *)code
           andRedirectURI:(NSString *)redirectURI
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@"authorization_code" forKey:@"grant_type"];
    [parameters setObject:self.appId forKey:@"client_id"];
    [parameters setObject:self.secret forKey:@"client_secret"];
    [parameters setObject:code forKey:@"code"];
    [parameters setObject:redirectURI forKey:@"redirect_uri"];
    
    [self postPath:MLOauthUrl
        parameters:parameters
           success:[self successRequestTokenBlock]
           failure:[self failureBlock]];
}

- (void)doRefreshToken
{
    if ([self.refreshToken length] > 0) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:@"refresh_token" forKey:@"grant_type"];
        [parameters setObject:self.appId forKey:@"client_id"];
        [parameters setObject:self.secret forKey:@"client_secret"];
        [parameters setObject:self.refreshToken forKey:@"refresh_token"];
        [self postPath:MLOauthUrl
            parameters:parameters
               success:[self successRequestTokenBlock]
               failure:[self failureBlock]];
    }
    else {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:@"Offline-Access is not allowed." forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:@"invalid_grant" forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [[NSError alloc] initWithDomain:MLMeliErrorDomain code:kHTTPStatusCodeBadRequest userInfo:userInfo];
        
        if([self.delegate respondsToSelector:@selector(meliClient:didFailWithError:)])
            [self.delegate meliClient:self didFailWithError:error];
    }
}

// REQUEST METHODS
- (void)execute:(NSInvocation *)action
{
    [self execute:action success:[self successBlock] failure:[self failureBlock]];
}

- (void)execute:(NSInvocation *)action
        success:(SuccessBlock)success
        failure:(FailureBlock)failure
{
    [action setArgument:&success atIndex:4];
    [action setArgument:&failure atIndex:5];
    [action invoke];
}

- (void)executeWithBody:(NSInvocation *)action
{
    SuccessBlock success = [self successBlock];
    FailureBlock failure = [self failureBlock];
    [action setArgument:&success atIndex:5];
    [action setArgument:&failure atIndex:6];
    [action invoke];
}

- (NSInvocation *)invocationForSelector:(SEL)sel
                                andPath:(NSString *)path
                             parameters:(NSDictionary *)parameters
                                   body:(NSDictionary *)body
{
    MLHTTPConnection *connection = [MLHTTPConnection sharedHTTPConnection];
    NSInvocation *action = [NSInvocation invocationWithMethodSignature:[connection methodSignatureForSelector:sel]];
    [action setSelector:sel];
    [action setTarget:connection];
    [action setArgument:&path atIndex:2];
    [action setArgument:&parameters atIndex:3];
    if (body) {
        [action setArgument:&body atIndex:4];
    }
    
    return action;
}

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
{
    SEL sel = @selector(getPath:parameters:success:failure:);
    [self execute:[self invocationForSelector:sel andPath:path parameters:parameters body:nil]];
}

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(SuccessBlock)success
         failure:(FailureBlock)failure
{
    SEL sel = @selector(postFormUrlPath:parameters:success:failure:);
    [self execute:[self invocationForSelector:sel andPath:path parameters:parameters body:nil] success:success failure:failure];
}

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
            body:(NSDictionary *)body
{
    SEL sel = @selector(postPath:parameters:body:success:failure:);
    [self executeWithBody:[self invocationForSelector:sel andPath:path parameters:parameters body:body]];
}

- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
           body:(NSDictionary *)body
{
    SEL sel = @selector(putPath:parameters:body:success:failure:);
    [self executeWithBody:[self invocationForSelector:sel andPath:path parameters:parameters body:body]];
}

- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
{
    SEL sel = @selector(deletePath:parameters:success:failure:);
    [self execute:[self invocationForSelector:sel andPath:path parameters:parameters body:nil]];
}

@end
