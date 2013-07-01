//
//  MLHTTPConnection.m
//  ios-sdk
//
//  Created by Javier Alvarez on 6/29/13.
//  Copyright (c) 2013 Javier Alvarez. All rights reserved.
//

#import "MLHTTPConnection.h"
#import "MLConfig.h"

#pragma mark helpers

// Copyright (c) 2011 Gowalla (http://gowalla.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

typedef enum {
    AFFormURLParameterEncoding,
    AFJSONParameterEncoding,
    AFPropertyListParameterEncoding,
} AFHTTPClientParameterEncoding;

@interface AFQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (id)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;
@end

static NSString * AFPercentEscapedQueryStringPairMemberFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kAFCharactersToBeEscaped = @":/?&=;+!@#$()',*";
    static NSString * const kAFCharactersToLeaveUnescaped = @"[].";
    
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kAFCharactersToLeaveUnescaped, (__bridge CFStringRef)kAFCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
}

@implementation AFQueryStringPair
@synthesize field = _field;
@synthesize value = _value;

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return AFPercentEscapedQueryStringPairMemberFromStringWithEncoding([self.field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@", AFPercentEscapedQueryStringPairMemberFromStringWithEncoding([self.field description], stringEncoding), AFPercentEscapedQueryStringPairMemberFromStringWithEncoding([self.value description], stringEncoding)];
    }
}

@end

extern NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * AFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValueWithEncoding:stringEncoding]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return AFQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = [dictionary objectForKey:nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in set) {
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[AFQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

//  Copyright (c) 2013 Javier Alvarez. All rights reserved.
//

#pragma mark MLHTTPConnection

@interface MLHTTPConnection ()

@property (readwrite, nonatomic, strong) NSMutableDictionary *defaultHeaders;
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@property (readwrite, nonatomic, strong) NSMutableData *responseData;
@property (readwrite, nonatomic, strong) NSDictionary *responseHeaders;
@property (readwrite, nonatomic, strong) NSNumber *statusCode;
@property (nonatomic, assign) NSStringEncoding stringEncoding;

//@property (copy) void (^success)(id responseObject);
//@property (copy) void (^failure)(NSError *error);

@property (copy) SuccessBlock success;
@property (copy) FailureBlock failure;

- (void)setDefaultHeader:(NSString *)header
                   value:(NSString *)value;

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
                         parameterEncoding:(AFHTTPClientParameterEncoding)paramEncoding
                             urlParameters:(NSDictionary *)urlParameters;
- (id)jsonWithData:(NSData *)data;

@end

@implementation MLHTTPConnection

@synthesize defaultHeaders = _defaultHeaders;
@synthesize baseURL = _baseURL;
@synthesize stringEncoding = _stringEncoding;

+ (MLHTTPConnection *)sharedHTTPConnection
{
    static dispatch_once_t pred;
    static MLHTTPConnection *_sharedHTTPConnection = nil;
    
    dispatch_once(&pred, ^{ _sharedHTTPConnection = [[self alloc] initWithBaseURL:[NSURL URLWithString:MLAPIRootUrl]]; });
    return _sharedHTTPConnection;
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected
    if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    self.baseURL = url;
    self.stringEncoding = NSUTF8StringEncoding;
    self.defaultHeaders = [NSMutableDictionary dictionary];
    
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
	[self.defaultHeaders setValue:value forKey:header];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData = [[NSMutableData alloc] init];
    self.responseHeaders = [(NSHTTPURLResponse*)response allHeaderFields];
    self.statusCode = [NSNumber numberWithInt:[(NSHTTPURLResponse*)response statusCode]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    id jsonBody = [self jsonWithData:self.responseData];
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    [response setValue:self.statusCode forKey:MLKeyResponseHTTPCode];
    [response setValue:jsonBody forKey:MLKeyResponseBody];
    self.success(response);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.failure(error);
}

#pragma request methods

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(SuccessBlock)success
        failure:(FailureBlock)failure
{
    self.success = success;
    self.failure = failure;
	NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters parameterEncoding:AFFormURLParameterEncoding urlParameters:nil];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [conn start];
}

- (void)postFormUrlPath:(NSString *)path
             parameters:(NSDictionary *)parameters
                success:(SuccessBlock)success
                failure:(FailureBlock)failure
{
    self.success = success;
    self.failure = failure;
	NSURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters parameterEncoding:AFFormURLParameterEncoding urlParameters:nil];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [conn start];
}

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
            body:(NSDictionary *)body
         success:(SuccessBlock)success
         failure:(FailureBlock)failure
{
    self.success = success;
    self.failure = failure;
	NSURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:body parameterEncoding:AFJSONParameterEncoding urlParameters:parameters];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [conn start];
}

- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
           body:(NSDictionary *)body
        success:(SuccessBlock)success
        failure:(FailureBlock)failure
{
    self.success = success;
    self.failure = failure;
	NSURLRequest *request = [self requestWithMethod:@"PUT" path:path parameters:body parameterEncoding:AFJSONParameterEncoding urlParameters:parameters];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [conn start];
}

- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(SuccessBlock)success
           failure:(FailureBlock)failure
{
    self.success = success;
    self.failure = failure;
	NSURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:parameters parameterEncoding:AFFormURLParameterEncoding urlParameters:nil];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [conn start];
}


- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
                         parameterEncoding:(AFHTTPClientParameterEncoding)paramEncoding
                             urlParameters:(NSDictionary *)urlParameters
{
    NSParameterAssert(method);
    
    if (!path) {
        path = @"";
    }
    
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseURL];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    [request setAllHTTPHeaderFields:self.defaultHeaders];
    
    if (parameters) {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", AFQueryStringFromParametersWithEncoding(parameters, self.stringEncoding)]];
            [request setURL:url];
        } else {
            NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
            NSError *error = nil;
            
            switch (paramEncoding) {
                case AFFormURLParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
                    [request setHTTPBody:[AFQueryStringFromParametersWithEncoding(parameters, self.stringEncoding) dataUsingEncoding:self.stringEncoding]];
                    break;
                case AFJSONParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
                    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error]];
                    break;
                case AFPropertyListParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/x-plist; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
                    [request setHTTPBody:[NSPropertyListSerialization dataWithPropertyList:parameters format:NSPropertyListXMLFormat_v1_0 options:0 error:&error]];
                    break;
            }
            if (urlParameters) {
                url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", AFQueryStringFromParametersWithEncoding(urlParameters, self.stringEncoding)]];
                [request setURL:url];
            }
            
            if (error) {
                NSLog(@"%@ %@: %@", [self class], NSStringFromSelector(_cmd), error);
            }
        }
    }
    
	return request;
}

- (id)jsonWithData:(NSData *)data
{
    NSError *error = nil;
    id json = nil;
    if (data) {
        json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    }
    return json;
}
@end


