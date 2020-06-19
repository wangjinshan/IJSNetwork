//
//  IJSNChainRequest.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNChainRequest.h"
#import "IJSNetworkUtils.h"
#import "IJSNCacheRequest.h"
#import "IJSNChainRequest+RequestAccessory.h"
#import "IJSNChainRequestAgent.h"
#import "IJSNBaseRequest.h"


@interface IJSNChainRequest () <IJSRequestDelegate>

@property (strong, nonatomic) NSMutableArray<IJSNBaseRequest *> *requestArray;
@property (strong, nonatomic) NSMutableArray<IJSNChainCallback> *requestCallbackArray;
@property (assign, nonatomic) NSUInteger nextRequestIndex;
@property (strong, nonatomic) IJSNChainCallback emptyCallback;

@end


@implementation IJSNChainRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        _nextRequestIndex = 0;                          //下一个请求的index
        _requestArray = [NSMutableArray array];         //保存链式请求的数组
        _requestCallbackArray = [NSMutableArray array]; //保存回调的数组
        _emptyCallback = ^(IJSNChainRequest *chainRequest, IJSNBaseRequest *baseRequest) {
            //空回调，用来填充用户没有定义的回调block
        };
    }
    return self;
}

- (void)start {
    if (_nextRequestIndex > 0) //如果第1个请求已经结束，就不再重复start了
    {
        IJSNLog(@"Error! 链式请求已经开始了.");
        return;
    }

    if ([_requestArray count] > 0) //如果请求队列数组里面还有request，则取出并start
    {
        [self toggleAccessoriesWillStartCallBack];
        [self startNextRequest]; //取出当前request并start
        [[IJSNChainRequestAgent sharedAgent] addChainRequest:self];
    } else {
        IJSNLog(@"Error! 链式请求数组为空");
    }
}
//终止当前的chain
- (void)stop {
    [self toggleAccessoriesWillStopCallBack];                      //首先调用即将停止的callback
    [self clearRequest];                                           //然后stop当前的请求，再清空chain里所有的请求和回掉block
    [[IJSNChainRequestAgent sharedAgent] removeChainRequest:self]; //在IJSChainRequestAgent里移除当前的chain
    [self toggleAccessoriesDidStopCallBack];                       //最后调用已经结束的callback
}
//在当前chain添加request和callback
- (void)addRequest:(IJSNBaseRequest *)request callback:(IJSNChainCallback)callback {
    [_requestArray addObject:request];
    if (callback != nil) {
        [_requestCallbackArray addObject:callback];
    } else { //之所以特意弄一个空的callback，是为了避免在用户没有给当前request的callback传值的情况下，造成request数组和callback数组的不对称
        [_requestCallbackArray addObject:_emptyCallback];
    }
}

- (NSArray<IJSNBaseRequest *> *)requestArray {
    return _requestArray;
}

// 开始下一个请求
- (BOOL)startNextRequest {
    if (_nextRequestIndex < _requestArray.count) {
        IJSNBaseRequest *request = _requestArray[_nextRequestIndex];
        _nextRequestIndex++;
        request.delegate = self;
        [request clearCompletionBlock];
        [request start];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - 网络请求代理方法 Delegate
// 成功
- (void)requestFinished:(IJSNBaseRequest *)request {
    //1. 取出当前的request和callback，进行回调
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    IJSNChainCallback callback = _requestCallbackArray[currentRequestIndex];
    if (callback) { // 这个回调只是当前request的回调，而不是当前chain全部完成的回调。当前chain的回调在下面
        callback(self, request);
    }
    //2. 如果不能再继续请求了，说明当前成功的request已经是chain里最后一个request，也就是说当前chain里所有的回调都成功了，即这个chain请求成功了。
    if (![self startNextRequest]) {
        [self toggleAccessoriesWillStopCallBack];
        if ([_delegate respondsToSelector:@selector(chainRequestFinished:)]) {
            [_delegate chainRequestFinished:self];
            [[IJSNChainRequestAgent sharedAgent] removeChainRequest:self];
        }
        [self toggleAccessoriesDidStopCallBack];
    } else { // 判断else 情况
        [self startNextRequest];
    }
}
// 失败
- (void)requestFailed:(IJSNBaseRequest *)request {
    [self toggleAccessoriesWillStopCallBack];
    //如果当前 chain里的某个request失败了，则判定当前chain失败。调用当前chain失败的回调
    if ([_delegate respondsToSelector:@selector(chainRequestFailed:failedBaseRequest:)]) {
        [_delegate chainRequestFailed:self failedBaseRequest:request];
        [[IJSNChainRequestAgent sharedAgent] removeChainRequest:self];
    }
    [self toggleAccessoriesDidStopCallBack];
}

- (void)clearRequest {
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    if (currentRequestIndex < [_requestArray count]) {
        IJSNBaseRequest *request = _requestArray[currentRequestIndex];
        [request stop];
    }
    [_requestArray removeAllObjects];
    [_requestCallbackArray removeAllObjects];
}

#pragma mark - Request Accessoies

- (void)addAccessory:(id<IJSRequestAccessoryDelegate>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

@end
