

//
//  IJSNetworkRequestAgent.m
//  IJSNetworking
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNetworkRequestAgent.h"

#import "IJSNetworkConfig.h"
#import "IJSNBaseRequest+RequestAccessory.h"


#import "IJSNetworkUtils.h"
#import <pthread/pthread.h>

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

#define kIJSNetworkIncompleteDownloadFolderName @"Incomplete"

@implementation IJSNetworkRequestAgent
{
    AFHTTPSessionManager *_manager;
    IJSNetworkConfig *_config;
    AFJSONResponseSerializer *_jsonResponseSerializer;
    AFXMLParserResponseSerializer *_xmlParserResponseSerialzier;
    NSMutableDictionary<NSNumber *, IJSNBaseRequest *> *_requestsRecord;
    
    dispatch_queue_t _processingQueue;
    pthread_mutex_t _lock;
    NSIndexSet *_allStatusCodes;
}

+ (IJSNetworkRequestAgent *)sharedAgent
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _config = [IJSNetworkConfig sharedConfig];
        _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_config.sessionConfiguration];
        _requestsRecord = [NSMutableDictionary dictionary];
        _processingQueue = dispatch_queue_create("com.yuantiku.networkagent.processing", DISPATCH_QUEUE_CONCURRENT); // 并发队列
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)]; // NSIndexSet就是一个唯一的，有序的，无符号整数
        pthread_mutex_init(&_lock, NULL); //初始化互斥锁
        
        _manager.securityPolicy = _config.securityPolicy;
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        // Take over the status code validation
        _manager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
        _manager.completionQueue = _processingQueue;
    }
    return self;
}
// 添加请求
- (void)addRequest:(IJSNBaseRequest *)request
{
    NSParameterAssert(request != nil); //断言为真，则表明程序运行正常，而断言为假，则意味着它已经在代码中发现了意料之外的错误
    
    NSError *__autoreleasing requestSerializationError = nil; //__autoreleasing 为了兼容早期的代码,默认就是这种类型 可以不写
    
    NSURLRequest *customUrlRequest = request.buildCustomUrlRequest;//获取用户自定义的requestURL
    if (customUrlRequest)
    {
        __block NSURLSessionDataTask *dataTask = nil;
        //如果存在用户自定义request，则直接走AFNetworking的dataTaskWithRequest:方法
//        dataTask = [_manager dataTaskWithRequest:customUrlRequest completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
//            [self handleRequestResult:dataTask responseObject:responseObject error:error]; //响应的统一处理
//        }];
        
        dataTask =[_manager dataTaskWithRequest:customUrlRequest
                                 uploadProgress:request.resumableUploadProgressBlock
                               downloadProgress:request.resumableDownloadProgressBlock
                              completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
              [self handleRequestResult:dataTask responseObject:responseObject error:error]; //响应的统一处理
        }];

        request.requestTask = dataTask;
    }
    else
    {  // 如果用户没有自定义url，则直接走这里
        request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
    }
    
    if (requestSerializationError)  //序列化失败，则认定为请求失败
    {
        [self requestDidFailWithRequest:request error:requestSerializationError];  //失败的处理
        return;
    }
    
    NSAssert(request.requestTask != nil, @"requestTask 不能为空");//满足条件返回真值，程序继续运行，如果返回假值
    
    // 优先级的映射
    // ios8之上有效
    if ([request.requestTask respondsToSelector:@selector(priority)])
    {
        switch (request.requestPriority)
        {
            case IJSRequestPriorityHigh:
                request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case IJSRequestPriorityLow:
                request.requestTask.priority = NSURLSessionTaskPriorityLow;
                break;
            case IJSRequestPriorityDefault:
                // 空实现
            default:
                request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }
    
    // Retain request
    IJSNLog(@"添加的请求是: %@", NSStringFromClass([request class]));
    [self addRequestToRecord:request]; //将request放入保存请求的字典中，taskIdentifier为key，request为值
    [request.requestTask resume];   //开始task
}

//  根据不同请求类型，序列化类型，和请求参数来返回NSURLSessionTask
- (NSURLSessionTask *)sessionTaskForRequest:(IJSNBaseRequest *)request error:(NSError *_Nullable __autoreleasing *)error
{
    IJSRequestMethod method = request.requestMethod; //  获得请求类型（GET，POST等）
    NSString *url = [self buildRequestUrl:request];   // 2. 获得请求url 解析好的url
    id param = request.requestArgument;  // 请求的参数
    AFConstructingBlock constructingBlock =request.constructingBodyBlock; // 构建的body体
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request]; //4. 获得request serializer
    
    switch (method)
    {
        case IJSRequestMethodGET:
            if (request.resumableDownloadPath)
            { //下载任务
                return [self downloadTaskWithDownloadPath:request.resumableDownloadPath requestSerializer:requestSerializer URLString:url parameters:param progress:request.resumableDownloadProgressBlock error:error];
            }
            else
            {  // //普通get请求
                return [self dataTaskWithHTTPMethod:@"GET" requestSerializer:requestSerializer URLString:url parameters:param error:error];
            }
        case IJSRequestMethodPOST:
        {    // post
            return [self dataTaskWithHTTPMethod:@"POST" requestSerializer:requestSerializer URLString:url parameters:param constructingBodyWithBlock:constructingBlock error:error];
        }
        case IJSRequestMethodHEAD:
        {    // hrad
            return [self dataTaskWithHTTPMethod:@"HEAD" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        }
        case IJSRequestMethodPUT:
        {   // put
            return [self dataTaskWithHTTPMethod:@"PUT" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        }
        case IJSRequestMethodDELETE:
        {   //delte
            return [self dataTaskWithHTTPMethod:@"DELETE" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        }
        case IJSRequestMethodPATCH:
        {    //patch
            return [self dataTaskWithHTTPMethod:@"PATCH" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        }
    }
}

- (void)cancelRequest:(IJSNBaseRequest *)request
{
    NSParameterAssert(request != nil);
    
    if (request.resumableDownloadPath)
    {
        NSURLSessionDownloadTask *requestTask = (NSURLSessionDownloadTask *) request.requestTask;
        [requestTask cancelByProducingResumeData:^(NSData *resumeData) {
            NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath];
            [resumeData writeToURL:localUrl atomically:YES];
        }];
    }
    else
    {
        [request.requestTask cancel]; //获取request的task，并取消
    }
    
    [self removeRequestFromRecord:request]; //从字典里移除当前request
    [request clearCompletionBlock]; //清理所有block
}

- (void)cancelAllRequests
{
    Lock();
    NSArray *allKeys = [_requestsRecord allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0)
    {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys)
        {
            Lock();
            IJSNBaseRequest *request = _requestsRecord[key];
            Unlock();
            // 使用的是 非递归锁 不要锁住 stop 否则可能导致死锁
            [request stop];
        }
    }
}
//判断code是否符合范围和json的有效性
- (BOOL)validateResult:(IJSNBaseRequest *)request error:(NSError *_Nullable __autoreleasing *)error
{
    BOOL result = [request statusCodeValidator]; //1. 判断code是否在200~299之间
    if (!result)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:IJSRequestValidationErrorDomain code:IJSRequestValidationErrorInvalidStatusCode userInfo:@{ NSLocalizedDescriptionKey: @"Invalid status code" }];
        }
        return result;
    }
    //2. result 存在的情况判断json是否有效
    id json = request.responseJSONObject; // [request responseJSONObject];
    id validator =request.jsonValidator;  // [request jsonValidator];
    if (json && validator)
    { //通过json和validator来判断json是否有效
        result = [IJSNetworkUtils validateJSON:json withValidator:validator];
        //如果json无效
        if (!result)
        {
            if (error)
            {
                *error = [NSError errorWithDomain:IJSRequestValidationErrorDomain code:IJSRequestValidationErrorInvalidJSONFormat userInfo:@{ NSLocalizedDescriptionKey: @"Invalid JSON format" }];
            }
            return result;
        }
    }
    return YES;
}

//统一处理请求结果，包括成功和失败的情况
- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error
{
    //1. 获取task对应的request
    Lock();
    IJSNBaseRequest *request = _requestsRecord[@(task.taskIdentifier)];
    Unlock();
    
    //如果不存在对应的request，则立即返回 包括删除任务取消任务等等,回调依然走
    if (!request)
    {
        return;
    }
    
    IJSNLog(@"完成请求: %@", NSStringFromClass([request class]));
    
    NSError *__autoreleasing serializationError = nil;
    NSError *__autoreleasing validationError = nil;
    
    NSError *requestError = nil;
    BOOL succeed = NO;
    
    request.responseObject = responseObject;  //2. 获取request对应的response
    //3. 获取responseObject，responseData和responseString
    if ([request.responseObject isKindOfClass:[NSData class]])
    {
        request.responseData = responseObject;  //3.1 获取 responseData
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[IJSNetworkUtils stringEncodingWithRequest:request]]; //3.2 获取responseString
        //3.3 获取responseObject（或responseJSONObject）
        //根据返回的响应的序列化的类型来得到对应类型的响应
        switch (request.responseSerializerType)
        {
            case IJSResponseSerializerTypeHTTP:
            {
                break;
            }
            case IJSResponseSerializerTypeJSON:
            {
                request.responseJSONObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                //                request.responseJSONObject = request.responseObject;
                break;
            }
            case IJSResponseSerializerTypeXMLParser:
            {
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                break;
            }
        }
    }
    //4. 判断是否有错误，将错误对象赋值给requestError，改变succeed的布尔值。目的是根据succeed的值来判断到底是进行成功的回调还是失败的回调
    if (error)
    {
        succeed = NO;
        requestError = error;
    }
    else if (serializationError)
    {  //如果序列化失败了
        succeed = NO;
        requestError = serializationError;
    }
    else
    {//即使没有error而且序列化通过，也要验证request是否有效
        succeed = [self validateResult:request error:&validationError];
        requestError = validationError;
    }
    //5. 根据succeed的布尔值来调用相应的处理
    if (succeed)
    {
        [self requestDidSucceedWithRequest:request];
    }
    else
    {  // 失败
        [self requestDidFailWithRequest:request error:requestError];
    }
    //6. 回调完成的处理
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request]; //6.1 在字典里移除当前request
        [request clearCompletionBlock];                 //6.2 清除所有block
    });
}
//请求成功：主要负责将结果写入缓存&回调成功的代理和block
- (void)requestDidSucceedWithRequest:(IJSNBaseRequest *)request
{
    @autoreleasepool
    {
        [request requestCompletePreprocessor]; //写入缓存
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [request toggleAccessoriesWillStopCallBack]; //告诉Accessories请求就要停止了
        [request requestCompleteFilter];  //在真正的回调之前做的处理,用户自定义
        
        if (request.delegate != nil)
        { //如果有代理，则调用成功的代理
            [request.delegate requestFinished:request];  // 请求结束
        }
        if (request.successCompletionBlock)
        {
            request.successCompletionBlock(request);
        }
        [request toggleAccessoriesDidStopCallBack];  // 协议的方法已经停止
    });
}

- (void)requestDidFailWithRequest:(IJSNBaseRequest *)request error:(NSError *)error
{
    request.error = error;
    IJSNLog(@"请求 %@ 失败, status code = %ld, error = %@,原因可能是序列化失败", NSStringFromClass([request class]), (long) request.responseStatusCode, error.localizedDescription);
    
    // 储存未完成的下载数据
    NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    if (incompleteDownloadData)
    {
        [incompleteDownloadData writeToURL:[self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath] atomically:YES];
    }
    
    // 如果下载任务失败，则取出对应的响应文件并清空
    if ([request.responseObject isKindOfClass:[NSURL class]])
    {
        NSURL *url = request.responseObject;
        //isFileURL：是否是文件，如果是，则可以再isFileURL获取；&&后面是再次确认是否存在改url对应的文件
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path])
        {
            request.responseData = [NSData dataWithContentsOfURL:url]; //将url的data和string赋给request
            request.responseString = [[NSString alloc] initWithData:request.responseData encoding:[IJSNetworkUtils stringEncodingWithRequest:request]];
            
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil; //清空request
    }
    
    @autoreleasepool
    {
        [request requestFailedPreprocessor]; //请求失败的预处理，YTK没有定义，需要用户定义
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [request toggleAccessoriesWillStopCallBack]; //告诉Accessories请求就要停止了
        [request requestFailedFilter]; //在真正的回调之前做的处理
        
        if (request.delegate != nil)
        {
            [request.delegate requestFailed:request];
        }
        if (request.failureCompletionBlock)
        {
            request.failureCompletionBlock(request);
        }
        [request toggleAccessoriesDidStopCallBack]; //告诉Accessories请求已经停止了
    });
}

- (void)addRequestToRecord:(IJSNBaseRequest *)request
{
    Lock();
    _requestsRecord[@(request.requestTask.taskIdentifier)] = request;
    Unlock();
}

- (void)removeRequestFromRecord:(IJSNBaseRequest *)request
{
    Lock();  //打开互斥锁
    [_requestsRecord removeObjectForKey:@(request.requestTask.taskIdentifier)];
    IJSNLog(@"请求队列的大小 = %zd", [_requestsRecord count]);
    Unlock();
}

#pragma mark -
//最终返回NSURLSessionDataTask实例
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError *_Nullable __autoreleasing *)error
{
    return [self dataTaskWithHTTPMethod:method requestSerializer:requestSerializer URLString:URLString parameters:parameters constructingBodyWithBlock:nil error:error];
}
//最终返回NSURLSessionDataTask实例
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                       constructingBodyWithBlock:(nullable void (^)(id<AFMultipartFormData> formData))block
                                           error:(NSError *_Nullable __autoreleasing *)error
{
    NSMutableURLRequest *request = nil;
    //根据有无构造请求体的block的情况来获取request
    if (block)
    {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:block error:error];
    }
    else
    {
        request = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    }
    //获得request以后来获取dataTask
    __block NSURLSessionDataTask *dataTask = nil;
    //1. 获取task对应的request
//    dataTask = [_manager dataTaskWithRequest:request
//                           completionHandler:^(NSURLResponse *__unused response, id responseObject, NSError *_error) {
//                               [self handleRequestResult:dataTask responseObject:responseObject error:_error];  //响应的统一处理
//                           }];
    
    dataTask = [_manager dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
//        Lock();
        IJSNBaseRequest *baseRequest = _requestsRecord[@(dataTask.taskIdentifier)];
//        Unlock();
        if (baseRequest.resumableUploadProgressBlock)
        {
            baseRequest.resumableUploadProgressBlock(uploadProgress);
        }
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
//        Lock();
        IJSNBaseRequest *baseRequest = _requestsRecord[@(dataTask.taskIdentifier)];
//        Unlock();
        if (baseRequest.resumableDownloadProgressBlock)
        {
            baseRequest.resumableDownloadProgressBlock(downloadProgress);
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
         [self handleRequestResult:dataTask responseObject:responseObject error:error];  //响应的统一处理
    }];
    return dataTask;
}
// 下载任务
- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(NSString *)downloadPath
                                         requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                                 URLString:(NSString *)URLString
                                                parameters:(id)parameters
                                                  progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                     error:(NSError *_Nullable __autoreleasing *)error
{
    // 网 URL 参数中添加 parameters
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];
    
    NSString *downloadTargetPath;
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory])
    {
        isDirectory = NO;
    }
    // 如果目标是一个文件 我们通过urlRequest 获取一个文件
    // 确保downloadTargetPath 始终是一个目录 而不是一个文件
    if (isDirectory)
    {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    }
    else
    {
        downloadTargetPath = downloadPath;
    }
    
    // AFN使用` moveitematurl `移动下载文件到目标路径
    //如果此路径下该文件存在,此方法也将考虑移除
    //因此，在启动下载任务之前，我们先删除已存在的文件。
    // https://github.com/AFNetworking/AFNetworking/issues/3775
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }
    
    BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self incompleteDownloadTempPathForDownloadPath:downloadPath].path];
    NSData *data = [NSData dataWithContentsOfURL:[self incompleteDownloadTempPathForDownloadPath:downloadPath]];
    BOOL resumeDataIsValid = [IJSNetworkUtils validateResumeData:data];
    
    BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *downloadTask = nil;
    //resumeData  尝试继续
    //尽管我们试图验证resumedata，这不能提高excecption
    if (canBeResumed)
    {
        @try
        {
            downloadTask = [_manager downloadTaskWithResumeData:data progress:downloadProgressBlock destination:^NSURL *_Nonnull(NSURL *_Nonnull targetPath, NSURLResponse *_Nonnull response) {
                return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
            } completionHandler:
                            ^(NSURLResponse *_Nonnull response, NSURL *_Nullable filePath, NSError *_Nullable error) {
                                [self handleRequestResult:downloadTask responseObject:filePath error:error];
                            }];
            resumeSucceeded = YES;
        }
        @catch (NSException *exception)
        {
            IJSNLog(@"重新下载失败, reason = %@", exception.reason);
            resumeSucceeded = NO;
        }
    }
    if (!resumeSucceeded)
    {
        downloadTask = [_manager downloadTaskWithRequest:urlRequest progress:downloadProgressBlock destination:^NSURL *_Nonnull(NSURL *_Nonnull targetPath, NSURLResponse *_Nonnull response) {
            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
        } completionHandler:
                        ^(NSURLResponse *_Nonnull response, NSURL *_Nullable filePath, NSError *_Nullable error) {
                            [self handleRequestResult:downloadTask responseObject:filePath error:error];
                        }];
    }
    return downloadTask;
}

#pragma mark - Resumable Download

- (NSString *)incompleteDownloadTempCacheFolder
{
    NSFileManager *fileManager = [NSFileManager new];
    static NSString *cacheFolder;
    
    if (!cacheFolder)
    {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:kIJSNetworkIncompleteDownloadFolderName];
    }
    
    NSError *error = nil;
    if (![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error])
    {
        IJSNLog(@"不能够创建缓存文件目录: %@", cacheFolder);
        cacheFolder = nil;
    }
    return cacheFolder;
}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath
{
    NSString *tempPath = nil;
    NSString *md5URLString = [IJSNetworkUtils md5StringFromString:downloadPath];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return [NSURL fileURLWithPath:tempPath];
}

#pragma mark - Testing

- (AFHTTPSessionManager *)manager
{
    return _manager;
}

- (void)resetURLSessionManager
{
    _manager = [AFHTTPSessionManager manager];
}

- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration
{
    _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
}
- (AFJSONResponseSerializer *)jsonResponseSerializer
{
    if (!_jsonResponseSerializer)
    {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableStatusCodes = _allStatusCodes;
    }
    return _jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier
{
    if (!_xmlParserResponseSerialzier)
    {
        _xmlParserResponseSerialzier = [AFXMLParserResponseSerializer serializer];
        _xmlParserResponseSerialzier.acceptableStatusCodes = _allStatusCodes;
    }
    return _xmlParserResponseSerialzier;
}

#pragma mark -

//格式化当前的请求---返回当前请求url
- (NSString *)buildRequestUrl:(IJSNBaseRequest *)request
{
    NSParameterAssert(request != nil);
    
    NSString *detailUrl =request.requestUrl;  //用户自定义的url（不包括在YTKConfig里面设置的base_url）
    NSURL *temp = [NSURL URLWithString:detailUrl];
    // 如果请求的url 是一个完整的url 则会直接忽略之前的 baseurl 参数等等的 配置 存在host和scheme的url立即返回正确
    if (temp && temp.host && temp.scheme)
    {
        return detailUrl;
    }
    // 如果需要过滤url，则过滤
    NSArray *filters = _config.urlFilters;
    for (id<IJSUrlFilterDelegate> f in filters)
    {
        detailUrl = [f filterUrl:detailUrl withRequest:request];
    }
    
    NSString *baseUrl;
    if (request.useCDN)
    {
        if ([request cdnUrl].length > 0)
        {
            baseUrl = request.cdnUrl; //如果使用CDN，在当前请求没有配置CDN地址的情况下，返回全局配置的CDN
        }
        else
        {
            baseUrl = _config.cdnUrl;
        }
    }
    else
    {
        if ([request baseUrl].length > 0)
        {//如果使用baseUrl，在当前请求没有配置baseUrl，返回全局配置的baseUrl
            baseUrl = request.baseUrl;
        }
        else
        {
            baseUrl = _config.baseUrl;
        }
    }
    // 如果末尾没有/，则在末尾添加一个／
    NSURL *url = [NSURL URLWithString:baseUrl];
    
    if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"])
    {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    return [NSURL URLWithString:detailUrl relativeToURL:url].absoluteString; //完整的url字符串
}
// 序列化
- (AFHTTPRequestSerializer *)requestSerializerForRequest:(IJSNBaseRequest *)request
{
    AFHTTPRequestSerializer *requestSerializer = nil;
    // http  或者 json
    if (request.requestSerializerType == IJSRequestSerializerTypeHTTP)
    {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    else if (request.requestSerializerType == IJSRequestSerializerTypeJSON)
    {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    requestSerializer.timeoutInterval = request.requestTimeoutInterval;  // 请求超时时间
    requestSerializer.allowsCellularAccess = request.allowsCellularAccess;  //是否允许数据服务
    
    //如果当前请求需要账号 密码 验证
    NSArray<NSString *> *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
    if (authorizationHeaderFieldArray != nil)
    {
        [requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
                                                          password:authorizationHeaderFieldArray.lastObject];
    }
    
    //如果当前请求需要自定义 HTTPHeaderField
    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = request.requestHeaderFieldValueDictionary;
    if (headerFieldValueDictionary != nil)
    {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys)
        {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    return requestSerializer;
}














@end
