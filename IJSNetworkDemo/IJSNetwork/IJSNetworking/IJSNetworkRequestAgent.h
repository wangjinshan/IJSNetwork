//
//  IJSNetworkRequestAgent.h
//  IJSNetworking
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 参订模式下的服务员   AFN是厨师
 
 网络请求的总代理，是对AFNetworking的封装，此类是一个单例 真正发起请求的类。负责发起请求，结束请求，并持有一个字典来存储正在执行的请求。
 */

NS_ASSUME_NONNULL_BEGIN
@class IJSNBaseRequest;
/**
 这个是网络请求直接和 AFN 交互
 */
@interface IJSNetworkRequestAgent : NSObject

- (instancetype)init __attribute__((unavailable("用 +sharedAgent 这个去初始化"))); // NS_UNAVAILABLE 变异错误的提示方法
+ (instancetype) new __attribute__((unavailable("用 +sharedAgent 这个去初始化")));

//  单例对象
+ (IJSNetworkRequestAgent *)sharedAgent;

/**
 添加请求给session 然后开始请求
 
 @param request 请求
 */
- (void)addRequest:(IJSNBaseRequest *)request;

/**
 取消请求
 
 @param request 请求
 */
- (void)cancelRequest:(IJSNBaseRequest *)request;

/**
 取消所有的请求
 */
- (void)cancelAllRequests;

/**
 返回解析好的url,解析外部出入的 URL
 
 @param request 解析的url 不应该是nil
 @return 请求的url
 */
- (NSString *)buildRequestUrl:(IJSNBaseRequest *)request;












@end
NS_ASSUME_NONNULL_END
