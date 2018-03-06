
//
//  IJSNBatchRequest.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNBatchRequest.h"
#import "IJSNetworkUtils.h"

#import "IJSNBatchRequestAgent.h"
#import "IJSNCacheRequest.h"

#import "IJSNBatchRequest+RequestAccessory.h"

@interface IJSNBatchRequest () <IJSRequestDelegate>

@property (nonatomic) NSInteger finishedCount;

@end
@implementation IJSNBatchRequest

- (instancetype)initWithRequestArray:(NSArray<IJSNCacheRequest *> *)requestArray
{
    self = [super init];
    if (self)
    {
        _requestArray = [requestArray copy];  //浅拷贝 ---- 保存为属性
        _finishedCount = 0; //批量请求完成的数量初始化为0
        for (IJSNCacheRequest *req in _requestArray)
        { //类型检查，所有元素都必须为YTKRequest或的它的子类，否则强制初始化失败
            if (![req isKindOfClass:[IJSNCacheRequest class]])
            {
                IJSNLog(@"请求的类必须是 YTKRequest 对象");
                return nil;
            }
        }
    }
    return self;
}

//batch请求开始
- (void)startWithCompletionBlockWithSuccess:(void (^)(IJSNBatchRequest *batchRequest))success
                                    failure:(void (^)(IJSNBatchRequest *batchRequest))failure
{
    [self setCompletionBlockWithSuccess:success failure:failure];  //设置成功和失败的block
    [self start];
}
// 开始请求
- (void)start
{
    //如果batch里第一个请求已经成功结束，则不能再start
    if (_finishedCount > 0)
    {
        IJSNLog(@"Error! 多任务请求已经开始.");
        return;
    }
    _failedRequest = nil; //最开始设定失败的request为nil
    [[IJSNBatchRequestAgent sharedAgent] addBatchRequest:self]; //使用YTKBatchRequestAgent来管理当前的批量请求
    [self toggleAccessoriesWillStartCallBack];  // 通知代理请求将要开始
    for (IJSNCacheRequest *req in _requestArray)
    { //遍历所有request，并开始请求
        req.delegate = self;
        [req clearCompletionBlock];
        [req start];
    }
}
// 停止所有的请求
- (void)stop
{
    [self toggleAccessoriesWillStopCallBack];
    _delegate = nil;
    [self clearRequest];
    [self toggleAccessoriesDidStopCallBack];
    [[IJSNBatchRequestAgent sharedAgent] removeBatchRequest:self];
}

//设置成功和失败的block
- (void)setCompletionBlockWithSuccess:(void (^)(IJSNBatchRequest *batchRequest))success
                              failure:(void (^)(IJSNBatchRequest *batchRequest))failure
{
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock
{
    // 清空block
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (BOOL)isDataFromCache
{
    BOOL result = YES;
    for (IJSNCacheRequest *request in _requestArray)
    {
        if (!request.isDataFromCache)
        {
            result = NO;
        }
    }
    return result;
}

#pragma mark - Network Request Delegate
// 批量请求结束
- (void)requestFinished:(IJSNCacheRequest *)request
{
    _finishedCount++;  //某个request成功后，首先让_finishedCount + 1
    if (_finishedCount == _requestArray.count) //如果_finishedCount等于_requestArray的个数，则判定当前batch请求成功
    {
        [self toggleAccessoriesWillStopCallBack];//调用即将结束的代理
        if ([_delegate respondsToSelector:@selector(batchRequestFinished:)])
        {
            [_delegate batchRequestFinished:self];
        }
        if (_successCompletionBlock)
        {
            _successCompletionBlock(self);
        }
        [self clearCompletionBlock];
        [self toggleAccessoriesDidStopCallBack];
        [[IJSNBatchRequestAgent sharedAgent] removeBatchRequest:self]; //从YTKBatchRequestAgent里移除当前的batch
    }
}

- (void)requestFailed:(IJSNCacheRequest *)request
{
    _failedRequest = request;
    [self toggleAccessoriesWillStopCallBack];  //调用即将结束的代理
    // 停止batch里所有的请求
    for (IJSNCacheRequest *req in _requestArray)
    {
        [req stop];
    }
    // 回调
    if ([_delegate respondsToSelector:@selector(batchRequestFailed:)])
    {
        [_delegate batchRequestFailed:self];
    }
    if (_failureCompletionBlock)
    {
        _failureCompletionBlock(self);
    }
    // 清空block
    [self clearCompletionBlock];
    
    [self toggleAccessoriesDidStopCallBack];  //回调状态值
    [[IJSNBatchRequestAgent sharedAgent] removeBatchRequest:self]; //从YTKBatchRequestAgent里移除当前的batch
}

- (void)clearRequest
{
    for (IJSNCacheRequest *req in _requestArray)
    {
        [req stop];
    }
    [self clearCompletionBlock];
}

#pragma mark - Request Accessoies

- (void)addAccessory:(id<IJSRequestAccessoryDelegate>)accessory
{
    if (!self.requestAccessories)
    {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

- (void)dealloc
{
    [self clearRequest];
}
@end
