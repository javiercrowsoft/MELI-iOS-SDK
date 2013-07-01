//
//  MLHTTPConnection.h
//  ios-sdk
//
//  Created by Javier Alvarez on 6/29/13.
//  Copyright (c) 2013 Javier Alvarez. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    /**
     * 200 OK.
     */
    kHTTPStatusCodeOK = 200,
    
    /**
     * 201 Created.
     */
    kHTTPStatusCodeCreated = 201,
    
    /**
     * 400 Bad Request.
     */
    kHTTPStatusCodeBadRequest = 400
    
}HTTPStatusCode;

typedef void(^SuccessBlock)(id responseObject);
typedef void(^FailureBlock)(NSError *error);

@interface MLHTTPConnection : NSObject <NSURLConnectionDelegate>

+ (MLHTTPConnection *)sharedHTTPConnection;

- (id)initWithBaseURL:(NSURL *)url;

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(SuccessBlock)success
        failure:(FailureBlock)failure;


- (void)postFormUrlPath:(NSString *)path
             parameters:(NSDictionary *)parameters
                success:(SuccessBlock)success
                failure:(FailureBlock)failure;

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
            body:(NSDictionary *)body
         success:(SuccessBlock)success
         failure:(FailureBlock)failure;


- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
           body:(NSDictionary *)body
        success:(SuccessBlock)success
        failure:(FailureBlock)failure;


- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(SuccessBlock)success
           failure:(FailureBlock)failure;

@end
