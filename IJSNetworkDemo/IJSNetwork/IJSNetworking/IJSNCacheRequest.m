

//
//  IJSNCacheRequest.m
//  IJSNetworking
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNCacheRequest.h"
#import "IJSCacheMetadata.h"
#import "IJSNetworkUtils.h"
#import "IJSNetworkConfig.h"
#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_With_QoS_Available 1140.11
#else
#define NSFoundationVersionNumber_With_QoS_Available NSFoundationVersionNumber_iOS_8_0
#endif

NSString *const IJSRequestCacheErrorDomain = @"com.shenzoom.ijsnetwork.cacheRequest";

static dispatch_queue_t ijsrequest_cache_writing_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = DISPATCH_QUEUE_SERIAL;                            // 串行队列对垒
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_With_QoS_Available) // 大于ios8 系统宏 到ios9.3
        {
            // 服务于与用户交互的优先级，该级别任务会占用几乎所有的时间片和 I/O 带宽。可以进行处理主事件循环、视图绘制、动画等操作，
            //*  - QOS_CLASS_USER_INTERACTIVE
            // 服务于用户发起并等待的优先级
            //*  - QOS_CLASS_USER_INITIATED
            // 默认的优先级
            //*  - QOS_CLASS_DEFAULT
            // 用户不太关心任务的进度，但是需要知道结果，比如下拉刷新操作
            //*  - QOS_CLASS_UTILITY
            // 用户不会察觉的任务，比如，预加载一些数据，
            //*  - QOS_CLASS_BACKGROUND
            attr = dispatch_queue_attr_make_with_qos_class(attr, QOS_CLASS_BACKGROUND, 0); // 用户不会察觉的任务，比如，预加载一些数据，
        }
        queue = dispatch_queue_create("com.shenzoom.ijsnetwork.cacheRequest", attr);
    });

    return queue;
}
/*-------------------------------------------------------------------------本类实现-------------------------------*/
@interface IJSNCacheRequest ()

@property (nonatomic, strong) NSData *cacheData;
@property (nonatomic, strong) NSString *cacheString;
@property (nonatomic, strong) id cacheJSON;
@property (nonatomic, strong) NSXMLParser *cacheXML;

@property (nonatomic, strong) IJSCacheMetadata *cacheMetadata;
@property (nonatomic, assign) BOOL dataFromCache; // 数据是不是来自缓存

@end


@implementation IJSNCacheRequest

// 先走子类的方法
- (void)start {
    //1. 如果忽略缓存 -> 请求
    if (self.ignoreCache) // 属性是用户手动设置的，如果用户强制忽略缓存，则无论是否缓存是否存在，直接发送请求
    {
        [self startWithoutCache]; // 开始无缓存请求方式
        return;
    }

    //2 如果存在下载未完成的文件 -> 请求
    if (self.resumableDownloadPath) // 是断点下载路径，如果该路径不为空，说明有未完成的下载任务，则直接发送请求继续下载
    {
        [self startWithoutCache];
        return;
    }
    //3  获取缓存失败 -> 请求
    if (![self loadCacheWithError:nil]) //方法验证了加载缓存是否成功的方法（返回值为YES，说明可以加载缓存；反之亦然）
    {
        [self startWithoutCache];
        return;
    }
    //4,  到这里，说明一定能拿到可用的缓存，可以直接回调了（因为一定能拿到可用的缓存，所以一定是调用成功的block和代理）
    _dataFromCache = YES; // 当确认缓存可以成功取出后，手动设置dataFromCache属性为 YES，说明当前的请求结果是来自于缓存，而没有通过网络请求

    dispatch_async(dispatch_get_main_queue(), ^{
        //5. 回调之前的操作
        //5.1 缓存处理
        [self requestCompletePreprocessor];
        //5.2 用户可以在这里进行真正回调前的操作
        [self requestCompleteFilter]; // 父类空实现需要用户自己实现的方法

        //6. 执行回调
        //6.1 请求完成的代理
        IJSNCacheRequest *strongSelf = self; //-------设置原因未知------------
        if ([strongSelf.delegate respondsToSelector:@selector(requestFinished:)]) {
            [strongSelf.delegate requestFinished:strongSelf];
        }
        //6.2 请求成功的block
        if (strongSelf.successCompletionBlock) {
            strongSelf.successCompletionBlock(strongSelf);
        }
        //7. 把成功和失败的block都设置为nil，避免循环引用
        [strongSelf clearCompletionBlock];
    });
}

// 无缓存开始启动
- (void)startWithoutCache {
    [self clearCacheVariables]; //清楚缓存
    [super start];              // 调用父类发请求
}

#pragma mark - Network Request Delegate
// 缓存处理
- (void)requestCompletePreprocessor {
    [super requestCompletePreprocessor]; // 父类是抽象的方法
    //是否异步将responseData写入缓存（写入缓存的任务放在专门的队列IJSrequest_cache_writing_queue进行）
    if (self.writeCacheAsynchronously) {
        dispatch_async(ijsrequest_cache_writing_queue(), ^{
            [self saveResponseDataToCacheFile:[super responseData]]; // 从响应数据获取数据
        });
    } else {
        [self saveResponseDataToCacheFile:[super responseData]];
    }
}

#pragma mark -
// 开始加载缓存 --- 判断有没有缓存
- (BOOL)loadCacheWithError:(NSError *_Nullable __autoreleasing *)error {
    // 缓存时间小于0，则返回（缓存时间默认为-1，需要用户手动设置，单位是秒）
    if (self.cacheTimeInSeconds < 0) {
        if (error) {
            *error = [NSError errorWithDomain:IJSRequestCacheErrorDomain code:IJSRequestCacheErrorInvalidCacheTime userInfo:@{ NSLocalizedDescriptionKey : @"无效的缓存时间" }];
        }
        return NO;
    }

    // 是否有缓存的元数据，如果没有，返回错误
    // 元数据是指数据的数据，在这里描述了缓存数据本身的一些特征：包括版本号，缓存时间，敏感信息等等
    if (![self loadCacheMetadata]) {
        if (error) {
            *error = [NSError errorWithDomain:IJSRequestCacheErrorDomain code:IJSRequestCacheErrorInvalidMetadata userInfo:@{ NSLocalizedDescriptionKey : @"无效的元数据,缓存可能不存在" }];
        }
        return NO;
    }

    // 有缓存，再验证是否有效
    if (![self validateCacheWithError:error]) {
        return NO;
    }

    // 有缓存，而且有效，再验证是否能取出来
    if (![self loadCacheData]) {
        if (error) {
            *error = [NSError errorWithDomain:IJSRequestCacheErrorDomain code:IJSRequestCacheErrorInvalidCacheData userInfo:@{ NSLocalizedDescriptionKey : @"无效的缓存数据" }];
        }
        return NO;
    }

    return YES;
}
// 检查缓存是否有效
- (BOOL)validateCacheWithError:(NSError *_Nullable __autoreleasing *)error {
    //  是否大于过期时间
    NSDate *creationDate = self.cacheMetadata.creationDate;
    NSTimeInterval duration = -[creationDate timeIntervalSinceNow]; // 指定时间和当前时间的差值
    if (duration < 0 || duration > [self cacheTimeInSeconds]) {
        if (error) {
            *error = [NSError errorWithDomain:IJSRequestCacheErrorDomain code:IJSRequestCacheErrorExpired userInfo:@{ NSLocalizedDescriptionKey : @"缓存过期" }];
        }
        return NO;
    }
    // 缓存的版本号是否符合
    long long cacheVersionFileContent = self.cacheMetadata.version;
    if (cacheVersionFileContent != self.cacheVersion) {
        if (error) {
            *error = [NSError errorWithDomain:IJSRequestCacheErrorDomain code:IJSRequestCacheErrorVersionMismatch userInfo:@{ NSLocalizedDescriptionKey : @"缓存版本不匹配" }];
        }
        return NO;
    }
    //敏感信息是否符合
    NSString *sensitiveDataString = self.cacheMetadata.sensitiveDataString;
    NSString *currentSensitiveDataString = ((NSObject *)self.cacheSensitiveData).description;
    if (sensitiveDataString || currentSensitiveDataString) {
        // 需要同时满足
        if (sensitiveDataString.length != currentSensitiveDataString.length || ![sensitiveDataString isEqualToString:currentSensitiveDataString]) {
            if (error) {
                *error = [NSError errorWithDomain:IJSRequestCacheErrorDomain code:IJSRequestCacheErrorSensitiveDataMismatch userInfo:@{ NSLocalizedDescriptionKey : @"敏感信息不存在" }];
            }
            return NO;
        }
    }
    //  app的版本是否符合
    NSString *appVersionString = self.cacheMetadata.appVersionString;
    NSString *currentAppVersionString = [IJSNetworkUtils appVersionString];
    if (appVersionString || currentAppVersionString) {
        if (appVersionString.length != currentAppVersionString.length || ![appVersionString isEqualToString:currentAppVersionString]) {
            if (error) {
                *error = [NSError errorWithDomain:IJSRequestCacheErrorDomain code:IJSRequestCacheErrorAppVersionMismatch userInfo:@{ NSLocalizedDescriptionKey : @"app 版本信息不匹配" }];
            }
            return NO;
        }
    }
    return YES;
}

- (BOOL)loadCacheMetadata {
    NSString *path = [self cacheMetadataFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        @try { //将序列化之后被保存在磁盘里的文件反序列化到当前对象的属性cacheMetadata
            _cacheMetadata = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
            return YES;
        }
        @catch (NSException *exception) {
            IJSNLog(@"加载元数据失败, reason = %@", exception.reason);
            return NO;
        }
    }
    return NO;
}
// 验证缓存是否能被取出来
- (BOOL)loadCacheData {
    NSString *path = [self cacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        _cacheData = data;
        _cacheString = [[NSString alloc] initWithData:_cacheData encoding:self.cacheMetadata.stringEncoding];
        switch (self.responseSerializerType) {
            case IJSResponseSerializerTypeHTTP:
                // Do nothing.
                return YES;
            case IJSResponseSerializerTypeJSON:
                _cacheJSON = [NSJSONSerialization JSONObjectWithData:_cacheData options:(NSJSONReadingOptions)0 error:&error];
                return error == nil;
            case IJSResponseSerializerTypeXMLParser:
                _cacheXML = [[NSXMLParser alloc] initWithData:_cacheData];
                return YES;
        }
    }
    return NO;
}
// 保存响应数据到缓存
- (void)saveResponseDataToCacheFile:(NSData *)data { // 1 缓存时间大于 0  缓存不可用
    // 如果发送了请求，则isDataFromCache一定是NO的，那么在上面这个判断里面，(!isDataFromCache)就一定为YES了
    if ([self cacheTimeInSeconds] > 0 && !self.isDataFromCache) {
        if (data != nil) {
            @try {
                // 新数据会覆盖老的数据  保存request的responseData到cacheFilePath
                [data writeToFile:[self cacheFilePath] atomically:YES];
                // 保存request的metadata到cacheMetadataFilePath
                IJSCacheMetadata *metadata = [[IJSCacheMetadata alloc] init];
                metadata.version = self.cacheVersion;                                               // 缓存的版本，默认返回为0，用户可以自定义
                metadata.sensitiveDataString = ((NSObject *)[self cacheSensitiveData]).description; // 敏感数据，类型为id，默认返回nil，用户可以自定义
                metadata.stringEncoding = [IJSNetworkUtils stringEncodingWithRequest:self];         //NSString的编码格式
                metadata.creationDate = [NSDate date];                                              // 当前日期
                metadata.appVersionString = [IJSNetworkUtils appVersionString];                     // app版本号
                [NSKeyedArchiver archiveRootObject:metadata toFile:[self cacheMetadataFilePath]];   // 保存的路径通过cacheMetadataFilePath方法获取。
            }
            @catch (NSException *exception) {
                IJSNLog(@"保存缓存失败, reason = %@", exception.reason);
            }
        }
    }
}

//1. 清除缓存
- (void)clearCacheVariables {
    _cacheData = nil;
    _cacheXML = nil;
    _cacheJSON = nil;
    _cacheString = nil;
    _cacheMetadata = nil;
    _dataFromCache = NO;
}

#pragma mark -
//创建文件夹
- (void)createDirectoryIfNeeded:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        [self createBaseDirectoryAtPath:path];
    } else {
        if (!isDir) {
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            [self createBaseDirectoryAtPath:path];
        }
    }
}
// 创建基础文件
- (void)createBaseDirectoryAtPath:(NSString *)path {
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error) {
        IJSNLog(@"创建缓存目录失败, error = %@", error);
    } else {
        [IJSNetworkUtils addDoNotBackupAttribute:path];
    }
}
//  创建用户保存所有缓存的文件夹
- (NSString *)cacheBasePath {
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:@"LazyRequestCache"];

    // IJSCacheDirPathFilterDelegate定义了用户可以自定义存储位置的代理方法
    NSArray<id<IJSCacheDirPathFilterDelegate>> *filters = [IJSNetworkConfig sharedConfig].cacheDirPathFilters;
    if (filters.count > 0) {
        for (id<IJSCacheDirPathFilterDelegate> f in filters) {
            path = [f filterCacheDirPath:path withRequest:self];
        }
    }

    [self createDirectoryIfNeeded:path]; //创建文件夹
    return path;
}
//纯NSData数据缓存的文件名
- (NSString *)cacheFileName {
    NSString *requestUrl = self.requestUrl; // [self requestUrl];
    NSString *baseUrl = [IJSNetworkConfig sharedConfig].baseUrl;
    id argument = [self cacheFileNameFilterForRequestArgument:self.requestArgument]; // 请求的参数
    NSString *requestInfo = [NSString stringWithFormat:@"Method:%ld Host:%@ Url:%@ Argument:%@",
                                                       (long)self.requestMethod, baseUrl, requestUrl, argument];
    NSString *cacheFileName = [IJSNetworkUtils md5StringFromString:requestInfo];
    return cacheFileName;
}
// 缓存文件的路径
- (NSString *)cacheFilePath {
    NSString *cacheFileName = [self cacheFileName];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheFileName];
    return path;
}
// 缓存的元数据的路径
- (NSString *)cacheMetadataFilePath {
    NSString *cacheMetadataFileName = [NSString stringWithFormat:@"%@.metadata", [self cacheFileName]];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheMetadataFileName];
    return path;
}
#pragma mark - Subclass Override
// 缓存时间,默认是 -1
- (NSInteger)cacheTimeInSeconds {
    return -1;
}

- (long long)cacheVersion {
    return 0;
}

- (id)cacheSensitiveData {
    return nil;
}

- (BOOL)writeCacheAsynchronously {
    return YES;
}

#pragma mark -
//  本类数据是不是来自缓存放到外部数据中
- (BOOL)isDataFromCache {
    return _dataFromCache;
}

- (NSData *)responseData {
    if (_cacheData) {
        return _cacheData;
    }
    return [super responseData];
}

- (NSString *)responseString {
    if (_cacheString) {
        return _cacheString;
    }
    return [super responseString];
}

- (id)responseJSONObject {
    if (_cacheJSON) {
        return _cacheJSON;
    }
    return [super responseJSONObject];
}

- (id)responseObject {
    if (_cacheJSON) {
        return _cacheJSON;
    }
    if (_cacheXML) {
        return _cacheXML;
    }
    if (_cacheData) {
        return _cacheData;
    }
    return [super responseObject];
}

@end
