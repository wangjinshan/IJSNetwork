//
//  IJSNBatchRequest.h
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 用于方便地发送批量的网络请求，YTKBatchRequest 是一个容器类，它可以放置多个 YTKRequest 子类，并统一处理这多个网络请求的成功和失败
 */
NS_ASSUME_NONNULL_BEGIN
@class IJSNCacheRequest;
@class IJSNBatchRequest;
@protocol IJSRequestAccessoryDelegate;
/**
 批量请求的代理
 */
@protocol IJSNBatchRequestDelegate <NSObject>

@optional

/**
 批量请求结束
 
 @param batchRequest 批量请求的对象
 */
- (void)batchRequestFinished:(IJSNBatchRequest *)batchRequest;

/**
 批量请求失败
 
 @param batchRequest 自己
 */
- (void)batchRequestFailed:(IJSNBatchRequest *)batchRequest;

@end

/**
 批量请求类 当批量请求的对象是单个时候,单个请求的对象代理将代理批量请求的代理
 */
@interface IJSNBatchRequest : NSObject


/**
 批量请求的数组
 */
@property (nonatomic, strong, readonly) NSArray<IJSNCacheRequest *> *requestArray;

/**
 批量请求代理.默认是nil
 */
@property (nonatomic, weak, nullable) id<IJSNBatchRequestDelegate> delegate;

/**
 所有请求结束成功的block,主线程执行
 */
@property (nonatomic, copy, nullable) void (^successCompletionBlock)(IJSNBatchRequest *);

/**
 失败的回调
 */
@property (nonatomic, copy, nullable) void (^failureCompletionBlock)(IJSNBatchRequest *);

/**
 标记批量请求 默认是0
 */
@property (nonatomic) NSInteger tag;

/**
 请求状态协议数组,如果 调用 'addAccessory' 这个数组将自动创建,默认是空 的
 */
@property (nonatomic, strong, nullable) NSMutableArray<id<IJSRequestAccessoryDelegate>> *requestAccessories;

/**
 失败的请求对象
 */
@property (nonatomic, strong, readonly, nullable) IJSNCacheRequest *failedRequest;

/**
 初始化方法
 
 @param requestArray 请求的数组
 @return 自己
 */
- (instancetype)initWithRequestArray:(NSArray<IJSNCacheRequest *> *)requestArray;

/**
 设置成功失败的回调
 
 @param success 成功回调
 @param failure 失败回调
 */
- (void)setCompletionBlockWithSuccess:(nullable void (^)(IJSNBatchRequest *batchRequest))success
                              failure:(nullable void (^)(IJSNBatchRequest *batchRequest))failure;

/**
 清空block
 */
- (void)clearCompletionBlock;

/**
 添加请求状态的方法
 
 @param accessory 请求状态协议
 */
- (void)addAccessory:(id<IJSRequestAccessoryDelegate>)accessory;

/**
 添加请求到队列
 */
- (void)start;

/**
 停止所有的请求
 */
- (void)stop;

/**
 开始发起请求
 
 @param success 成功
 @param failure 失败
 */
- (void)startWithCompletionBlockWithSuccess:(nullable void (^)(IJSNBatchRequest *batchRequest))success
                                    failure:(nullable void (^)(IJSNBatchRequest *batchRequest))failure;

/**
 数据来自本地缓存
 
 @return 状态值
 */
- (BOOL)isDataFromCache;




@end
NS_ASSUME_NONNULL_END
