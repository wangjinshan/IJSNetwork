//
//  IJSNBatchRequestAgent.h
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
/**
 负责管理多个YTKBatchRequest实例，持有一个数组来保存YTKBatchRequest。支持添加和删除YTKBatchRequest实例
 */
@class IJSNBatchRequest;
@interface IJSNBatchRequestAgent : NSObject

- (instancetype)init  __attribute__((unavailable("用 +sharedAgent 这个去初始化")));
+ (instancetype) new __attribute__((unavailable("用 +sharedAgent 这个去初始化")));

/**
 单例方法
 
 @return 自己
 */
+ (IJSNBatchRequestAgent *)sharedAgent;

///  Add a batch request.

/**
 添加请求
 
 @param request 批量请求
 */
- (void)addBatchRequest:(IJSNBatchRequest *)request;

/**
 删除批量请求
 
 @param request 批量请求
 */
- (void)removeBatchRequest:(IJSNBatchRequest *)request;



@end

NS_ASSUME_NONNULL_END
