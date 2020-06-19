

//
//  IJSNBaseRequest.m
//  IJSNetworking
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNBaseRequest.h"
#import "IJSNetworkRequestAgent.h"
#import "IJSNBaseRequest+RequestAccessory.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

NSString *const IJSRequestValidationErrorDomain = @"com.shenzoom.ijsnetwork.baseRequest";


@interface IJSNBaseRequest ()

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) id responseJSONObject;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) NSString *responseString;
@property (nonatomic, strong, readwrite) NSError *error;

@end


@implementation IJSNBaseRequest

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}
// 方法响应的code
- (NSInteger)responseStatusCode {
    return self.response.statusCode;
}

- (NSDictionary *)responseHeaders {
    return self.response.allHeaderFields;
}

- (NSURLRequest *)currentRequest {
    return self.requestTask.currentRequest;
}

- (NSURLRequest *)originalRequest {
    return self.requestTask.originalRequest;
}

- (BOOL)isCancelled {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCanceling;
}

- (BOOL)isExecuting {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateRunning;
}

#pragma mark - Request Configuration
// 将外部传进来的 block 保存起来
- (void)setCompletionBlockWithSuccess:(IJSRequestCompletionBlock)success
                              failure:(IJSRequestCompletionBlock)failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

/**
 清空block 避免循环引用
 */
- (void)clearCompletionBlock {
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (void)addAccessory:(id<IJSRequestAccessoryDelegate>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

#pragma mark - Request Action
//  开始发起网路请求
- (void)start {
    [self toggleAccessoriesWillStartCallBack]; // //1. 告诉Accessories即将请求回调了（其实是即将发起请求）toggle 切换

    [[IJSNetworkRequestAgent sharedAgent] addRequest:self]; //2. 令agent添加请求并发起请求，在这里并不是组合关系，agent只是一个单例
}
// 停止请求
- (void)stop {
    [self toggleAccessoriesWillStopCallBack];                  //告诉Accessories将要回调了
    self.delegate = nil;                                       //清空代理
    [[IJSNetworkRequestAgent sharedAgent] cancelRequest:self]; //调用agent的取消某个request的方法
    [self toggleAccessoriesDidStopCallBack];                   //告诉Accessories回调完成了
}

- (void)startWithCompletionBlockWithSuccess:(IJSRequestCompletionBlock)success
                                    failure:(IJSRequestCompletionBlock)failure {
    [self setCompletionBlockWithSuccess:success failure:failure]; //保存成功和失败的回调block，便于将来调用
    [self start];                                                 //发起请求
}

#pragma mark - Subclass Override

- (void)requestCompletePreprocessor {
}

- (void)requestCompleteFilter {
}

- (void)requestFailedPreprocessor {
}

- (void)requestFailedFilter {
}

- (NSString *)requestUrl {
    return @"";
}

- (NSString *)cdnUrl {
    return @"";
}

- (NSString *)baseUrl {
    return @"";
}

- (NSTimeInterval)requestTimeoutInterval {
    return 60;
}

- (id)requestArgument {
    return nil;
}

- (id)cacheFileNameFilterForRequestArgument:(id)argument {
    return argument;
}

- (IJSRequestMethod)requestMethod {
    return IJSRequestMethodGET;
}

- (IJSRequestSerializerType)requestSerializerType {
    return IJSRequestSerializerTypeHTTP;
}

- (IJSResponseSerializerType)responseSerializerType {
    return IJSResponseSerializerTypeJSON;
}

- (NSArray *)requestAuthorizationHeaderFieldArray {
    return nil;
}

- (NSDictionary *)requestHeaderFieldValueDictionary {
    return nil;
}

- (NSURLRequest *)buildCustomUrlRequest {
    return nil;
}

- (BOOL)useCDN {
    return NO;
}

- (BOOL)allowsCellularAccess {
    return YES;
}

- (id)jsonValidator {
    return nil;
}
// 方法判断响应的code是否在正确的范围
- (BOOL)statusCodeValidator {
    NSInteger statusCode = [self responseStatusCode];
    return (statusCode >= 200 && statusCode <= 299);
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass([self class]), self, self.currentRequest.URL, self.currentRequest.HTTPMethod, self.requestArgument];
}

@end
