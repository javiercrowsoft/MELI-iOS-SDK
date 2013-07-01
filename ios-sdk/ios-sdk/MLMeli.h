//
//  MLMeli.h
//  ios-sdk
//
//  Created by Javier Alvarez on 6/29/13.
//  Copyright (c) 2013 Javier Alvarez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLConfig.h"

FOUNDATION_EXPORT NSString *const MLMeliErrorDomain;
FOUNDATION_EXPORT NSString *const MLKeyResponseAccessToken;
FOUNDATION_EXPORT NSString *const MLKeyResponseExpiresIn;
FOUNDATION_EXPORT NSString *const MLKeyResponseRefreshToken;

@protocol MLMeliDelegate;

@interface MLMeli : NSObject

@property(weak) id<MLMeliDelegate> delegate;

@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *refreshToken;

- (id)initWithAppId:(NSString *)appId
          andSecret:(NSString *)secret
     andAccessToken:(NSString *)accessToken
    andRefreshToken:(NSString *)refreshToken;

// AUTH METHODS
- (NSString*)getAuthUrlWithCallbackURI:(NSString *)callbackURI;

- (void)authorizeWihtCode:(NSString *)code
           andRedirectURI:(NSString *)redirectURI;

- (void) doRefreshToken;

// REQUEST METHODS
- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters;

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
            body:(NSDictionary *)body;

- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
           body:(NSDictionary *)body;

- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters;

@end

@protocol MLMeliDelegate <NSObject>

- (void)meliClient:(MLMeli *)client
 didUpdateWithData:(id)data;

- (void)meliClient:(MLMeli *)client
  didFailWithError:(NSError *)error;

@end