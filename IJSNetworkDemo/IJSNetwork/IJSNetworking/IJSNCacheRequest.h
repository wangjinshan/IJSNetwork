//
//  IJSNCacheRequest.h
//  IJSNetworking
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNBaseRequest.h"
NS_ASSUME_NONNULL_BEGIN
/**
 所有的网络请求类需要继承于 IJSNCacheRequest 类，每一个 IJSNCacheRequest 类的子类代表一种专门的网络请求。
 IJSNBaseRequest的子类。负责缓存的处理：请求前查询缓存；请求后写入缓存
 */
// 定义全局变量 IJSNRequestCacheErrorDomain
FOUNDATION_EXPORT NSString *const IJSNRequestCacheErrorDomain;
// 错误码
NS_ENUM(NSInteger){
    IJSRequestCacheErrorExpired = -1,
    IJSRequestCacheErrorVersionMismatch = -2,
    IJSRequestCacheErrorSensitiveDataMismatch = -3,
    IJSRequestCacheErrorAppVersionMismatch = -4,
    IJSRequestCacheErrorInvalidCacheTime = -5,
    IJSRequestCacheErrorInvalidMetadata = -6,
    IJSRequestCacheErrorInvalidCacheData = -7,
    };
    
    /**
     你需要继承并实现的类 继承自 IJSBaseRequest,增加了本地缓存的功能 由于负责环境请求不会缓存 `Cache-Control`, `Last-Modified`, 等控制
     */
@interface IJSNCacheRequest : IJSNBaseRequest

/**
 是否忽略缓存,默认是No,但是需要设置缓存有效时间,默认是-1 实际上就是不生效,注意及时属性是YES response也是会被缓存
 */
@property (nonatomic) BOOL ignoreCache;

/**
 数据是不是来自本地
 */
- (BOOL)isDataFromCache;


/**
 从缓存中加载数据
 
 @param error 错误信息
 @return 成功与否
 */
- (BOOL)loadCacheWithError:(NSError *__autoreleasing *)error;

/**
 更新本地缓存,不管缓存在不在都更新
 */
- (void)startWithoutCache;

/**
 缓存响应信息到响应缓存中
 
 @param data 数据
 */
- (void)saveResponseDataToCacheFile:(NSData *)data;

#pragma mark - Subclass Override

/**
 缓存在磁盘中的最大持续时间，直到它被认为过期为止。
 默认值是 -1，这意味着响应实际上不作为缓存保存。 必须返回一个大于 0 的值才能开启缓存,默认是关闭
 
 @return 缓存有效时间
 */
- (NSInteger)cacheTimeInSeconds;

/**
 本非缓存的版本号默认是0
 
 @return 版本号
 */
- (long long)cacheVersion;

/**
 用作附加信息告知需要更新,这个信息的描述将用作判断缓存是否有效,建议使用NSArray` or `NSDictionary`作为返回值,如果使用自定义的类型,请确保 "description"能够正确执行
 
 @return 附加信息
 */
- (nullable id)cacheSensitiveData;

/**
 异步写入缓存
 
 @return 默认是YES
 */
- (BOOL)writeCacheAsynchronously;









@end
NS_ASSUME_NONNULL_END
