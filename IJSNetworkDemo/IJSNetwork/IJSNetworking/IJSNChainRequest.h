//
//  IJSNChainRequest.h
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

/**
 用于管理有相互依赖(Chain 链)的网络请求，它实际上最终可以用来管理多个拓扑排序后的网络请求。
 例如，
 我们有一个需求，需要用户在注册时，先发送注册的 Api，
 然后 :
 如果注册成功，再发送读取用户信息的 Api。并且，读取用户信息的 Api 需要使用注册成功返回的用户 id 号。
 如果注册失败，则不发送读取用户信息的 Api 了
 可以发起链式请求，持有一个数组来保存所有的请求类。当某个请求结束后才能发起下一个请求，如果其中有一个请求返回失败，则认定本请求链失败。
 */
@class IJSNChainRequest;
@class IJSNBaseRequest;
@protocol IJSRequestAccessoryDelegate;

/**
 链式请求的代理
 */
@protocol IJSNChainRequestDelegate <NSObject>

@optional

/**
 链式请求成功
 
 @param chainRequest 自己
 */
- (void)chainRequestFinished:(IJSNChainRequest *)chainRequest;

/**
 链式请求失败
 
 @param chainRequest 自己
 @param request 第一个导致失败的请求请求
 */
- (void)chainRequestFailed:(IJSNChainRequest *)chainRequest failedBaseRequest:(IJSNBaseRequest *)request;

@end

typedef void (^IJSNChainCallback)(IJSNChainRequest *chainRequest, IJSNBaseRequest *baseRequest);

/**
 链式请求的对象,如果链式请求对象只有一个,那会走单个请求对象的回调
 */
@interface IJSNChainRequest : NSObject

/**
 所有请求的数组
 
 @return 请求的数组
 */
- (NSArray<IJSNBaseRequest *> *)requestArray;

/**
 代理
 */
@property (nonatomic, weak, nullable) id<IJSNChainRequestDelegate> delegate;

/**
 请求状态协议数组
 */
@property (nonatomic, strong, nullable) NSMutableArray<id<IJSRequestAccessoryDelegate>> *requestAccessories;

/**
 添加请求的状态协议 'requestAccessories'
 
 @param accessory 请求的状态
 */
- (void)addAccessory:(id<IJSRequestAccessoryDelegate>)accessory;

/**
 开始请求
 */
- (void)start;

/**
 停止请求
 */
- (void)stop;

/**
 添加链式请求,此方法不支持平行调用
 
 @param request 请求对象
 @param callback 回调
 */
- (void)addRequest:(IJSNBaseRequest *)request callback:(nullable IJSNChainCallback)callback;

@end

NS_ASSUME_NONNULL_END
