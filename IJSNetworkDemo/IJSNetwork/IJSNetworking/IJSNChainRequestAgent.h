//
//  IJSNChainRequestAgent.h
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@class IJSNChainRequest;
/**
 负责管理多个IJSChainRequestAgent实例，持有一个数组来保存IJSChainRequest。支持添加和删除IJSChainRequest实例
 */
@interface IJSNChainRequestAgent : NSObject

- (instancetype)init __attribute__((unavailable("用 +sharedAgent 这个去初始化")));
+ (instancetype) new __attribute__((unavailable("用 +sharedAgent 这个去初始化")));

/**
 单例
 */
+ (IJSNChainRequestAgent *)sharedAgent;

/**
 添加链式请求
 
 @param request 链式请求对象
 */
- (void)addChainRequest:(IJSNChainRequest *)request;

/**
 移除链式请求
 
 @param request 链式请求
 */
- (void)removeChainRequest:(IJSNChainRequest *)request;

@end

NS_ASSUME_NONNULL_END
