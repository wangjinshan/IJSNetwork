//
//  IJSNetworkConfig.h
//  IJSNetworking
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import <Foundation/Foundation.h>
/*
 NS_ASSUME_NONNULL_BEGIN 注释
 如果需要每个属性或每个方法都去指定nonnull和nullable，是一件非常繁琐的事。苹果为了减轻我们的工作量，专门提供了两个宏：NS_ASSUME_NONNULL_BEGIN和NS_ASSUME_NONNULL_END。在这两个宏之间的代码，所有简单指针对象都被假定为nonnull，因此我们只需要去指定那些nullable的指针
 
 用于统一设置网络请求的服务器和 CDN 的地址 被IJSCancheRequest和IJSNetworkAgent访问。负责所有请求的全局配置，例如baseUrl和CDNUrl等等。
 */
NS_ASSUME_NONNULL_BEGIN
@class IJSNBaseRequest;
@class AFSecurityPolicy;
// 接口用于实现对网络请求 URL 或参数的重写，例如可以统一为网络请求加上一些参数，或者修改一些路径
@protocol IJSUrlFilterDelegate <NSObject>
/**
 添加外部的配置信息,并将外部的配置信息作为返回值返回给里面的类
 
 @param originUrl 原始的url 通过requestUrl返回
 @param request 请求本身
 @return 新的URL 他将作为新的 requestUrl
 */
- (NSString *)filterUrl:(NSString *)originUrl withRequest:(IJSNBaseRequest *)request;

@end

/**
 每一次的请求用户都可以追加一个路径用作保存缓存的路径
 */
@protocol IJSCacheDirPathFilterDelegate <NSObject>

/**
 在实际保存之前先对缓存路径进行预处理
 
 @param originPath 原始路径
 @param request 请求
 @return 当缓存 返回新的路径作为 base path
 */
- (NSString *)filterCacheDirPath:(NSString *)originPath withRequest:(IJSNBaseRequest *)request;

@end
/**
 设置全局网络的配置 他将用在IJSNetworkAgent
 */
@interface IJSNetworkConfig : NSObject

- (instancetype)init __attribute__((unavailable("用 +sharedConfig 这个去初始化")));
+ (instancetype) new __attribute__((unavailable("用 +sharedConfig 这个去初始化")));

// 单例对象
+ (IJSNetworkConfig *)sharedConfig;

//  统一的基类请求地址  比如 http://www.xxxxx/ 默认是空
@property (nonatomic, strong) NSString *baseUrl;

// 使用CDN 默认是空
@property (nonatomic, strong) NSString *cdnUrl;

/**
 AFNetworking 的用来处理 SSL认证的类 AFSecurityPolicy
 */
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

/**
 是否开启Debug模式
 */
@property (nonatomic) BOOL debugLogEnabled;

/**
 将在初始化 AFHTTPSessionManager 的使用 默认是空
 */
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

/**
 添加一个信息的 URL 过滤器
 
 @param filter 过滤协议
 */
- (void)addUrlFilter:(id<IJSUrlFilterDelegate>)filter;

/**
 删除所有的  URL filters.
 */
- (void)clearUrlFilter;

/**
 添加新的缓存 path filter
 
 @param filter 协议
 */
- (void)addCacheDirPathFilter:(id<IJSCacheDirPathFilterDelegate>)filter;

/**
 清除所有的 缓存 path filters.
 */
- (void)clearCacheDirPathFilter;

/*-------------------------------------------------------------------------获取-------------------------------*/
/**
 URL filters 见 IJSUrlFilterDelegate
 */
@property (nonatomic, strong, readonly) NSMutableArray<id<IJSUrlFilterDelegate>> *urlFilters;

/**
 缓存 path filters 数组 见 IJSCacheDirPathFilterDelegate定义了用户可以自定义存储位置的代理方法
 */
@property (nonatomic, strong, readonly) NSMutableArray<id<IJSCacheDirPathFilterDelegate>> *cacheDirPathFilters;

@end

NS_ASSUME_NONNULL_END
