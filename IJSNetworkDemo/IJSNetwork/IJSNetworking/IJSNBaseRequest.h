//
//  IJSNBaseRequest.h
//  IJSNetworking
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 餐厅模式下的菜单
 所有请求类的基类。持有NSURLSessionTask实例，responseData，responseObject，error等重要数据，提供一些需要子类实现的与网络请求相关的方法，处理回调的代理和block，命令IJSNetworkAgent发起网络请求
 */
NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const IJSRequestValidationErrorDomain;

NS_ENUM(NSInteger){
    IJSRequestValidationErrorInvalidStatusCode = -8,
    IJSRequestValidationErrorInvalidJSONFormat = -9,
};

// 请求方式
typedef NS_ENUM(NSInteger, IJSRequestMethod) {
    IJSRequestMethodGET = 0,
    IJSRequestMethodPOST,
    IJSRequestMethodHEAD,
    IJSRequestMethodPUT,
    IJSRequestMethodDELETE,
    IJSRequestMethodPATCH,
};

// 请求序列化的类型
typedef NS_ENUM(NSInteger, IJSRequestSerializerType) {
    IJSRequestSerializerTypeHTTP = 0,
    IJSRequestSerializerTypeJSON,
};

// 响应体序列化类型
typedef NS_ENUM(NSInteger, IJSResponseSerializerType) {
    /// NSData type
    IJSResponseSerializerTypeHTTP,
    /// JSON object type
    IJSResponseSerializerTypeJSON,
    /// NSXMLParser type
    IJSResponseSerializerTypeXMLParser,
};

///  请求优先级
typedef NS_ENUM(NSInteger, IJSRequestPriority) {
    IJSRequestPriorityLow = -4L,
    IJSRequestPriorityDefault = 0,
    IJSRequestPriorityHigh = 4,
};

@protocol AFMultipartFormData;

typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);
typedef void (^AFURLSessionTaskProgressBlock)(NSProgress *progress);

@class IJSNBaseRequest;

typedef void (^IJSRequestCompletionBlock)(__kindof IJSNBaseRequest *request);

/**
     请求结果协议
     */
@protocol IJSRequestDelegate <NSObject>

@optional

/**
     请求结束
     
     @param request 请求对象
     */
- (void)requestFinished:(__kindof IJSNBaseRequest *)request;

/**
     请求失败
     
     @param request 请求对象
     */
- (void)requestFailed:(__kindof IJSNBaseRequest *)request;

@end

/**
     请求状态的协议
     */
@protocol IJSRequestAccessoryDelegate <NSObject>

@optional

/**
     请求开始
     
     @param request 请求对象
     */
- (void)requestWillStart:(id)request;

/**
     将请求结束 在  `requestFinished` and `successCompletionBlock` 方法之后执行
     
     @param request 请求对象
     */
- (void)requestWillStop:(id)request;

/**
     请求停止 `requestFinished` and `successCompletionBlock`. 之后执行
     
     @param request 请求对象
     */
- (void)requestDidStop:(id)request;

@end
/*-------------------------------------------------------------------------本类-------------------------------*/

/**
 请求的基类一个抽象的类 IJSNCacheRequest 继承自这个类
 */
@interface IJSNBaseRequest : NSObject
#pragma mark - -------------请求和响应信息------------------------------------------------------------------
/**
 这个对象实际上是nil,在 starts 方法之前不应该访问
 */
@property (nonatomic, strong, readonly) NSURLSessionTask *requestTask;

/**
 当前的请求  Shortcut for `requestTask.currentRequest`.
 */
@property (nonatomic, strong, readonly) NSURLRequest *currentRequest;

/**
 原始请求  Shortcut for `requestTask.originalRequest`.
 */
@property (nonatomic, strong, readonly) NSURLRequest *originalRequest;

/**
 响应对象  Shortcut for `requestTask.response`.
 */
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;

/**
 响应状态代码
 */
@property (nonatomic, readonly) NSInteger responseStatusCode;

/**
 响应头
 */
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseHeaders;

/**
 响应数据 如果响应失败就是空
 */
@property (nonatomic, strong, readonly, nullable) NSData *responseData;

/**
 响应的字符串标识形式,响应失败就是空
 */
@property (nonatomic, strong, readonly, nullable) NSString *responseString;

/**
 IJSResponseSerializerType 决定 serialized response  对象 失败就是空 如果使用 resumableDownloadPath 和 DownloadTask 他就是成功时候保存的路径对象
 */
@property (nonatomic, strong, readonly, nullable) id responseObject;

/**
 使用 IJSResponseSerializerTypeJSON 时候的对象
 */
@property (nonatomic, strong, readonly, nullable) id responseJSONObject;

/**
 错误信息
 */
@property (nonatomic, strong, readonly, nullable) NSError *error;

/**
 请求取消
 */
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;

/**
 请求任务执行状态
 */
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;

#pragma mark - ---------------------------------请求行为----------------------------------------------------------------------------------------

/**
 添加请求并开始
 */
- (void)start;

/**
 移除请求并接受
 */
- (void)stop;

/**
 开始请求的便利构造器 传入成功和失败的block,并保存起来
 
 @param success 成功
 @param failure 失败
 */
- (void)startWithCompletionBlockWithSuccess:(nullable IJSRequestCompletionBlock)success
                                    failure:(nullable IJSRequestCompletionBlock)failure;

#pragma mark-----------------------抽象的方法子类需要重写------------------------------------------------------------------------
/**
 请求成功就会在回到主线程之前在子线程回调 如果加了缓存就会在主线程回调 见 requestCompleteFilter
 */
- (void)requestCompletePreprocessor;

/**
 请求成功主线程回调 --- 实际上这个是一个空的实现,用户可以实现这个方法做处理
 */
- (void)requestCompleteFilter;

/**
 子线程请求失败回调
 */
- (void)requestFailedPreprocessor;

/**
 主线程请求失败回调
 */
- (void)requestFailedFilter;

/**
 请求网络的 baseurl
 
 @return 请求的 baseurl
 */
- (NSString *)baseUrl;

/**
 拼接在baseurl 后面的具体的请求的网络的url,如果你写这个地址是一个有效的地址,那么 baseurl 将直接忽略
 
 @return 完整的地址
 */
- (NSString *)requestUrl;

/**
 CDN 请求的URL
 
 @return CDN地址
 */
- (NSString *)cdnUrl;

/**
 请求超时时间,设置resumableDownloadPath 则session NSURLRequest的 timeoutInterval会被忽略,有效的设置方法是 NSURLSessionConfiguration的 timeoutIntervalForResource
 
 @return 默认是60秒
 */
- (NSTimeInterval)requestTimeoutInterval;

/**
 填写请求的参数
 
 @return 比如 post 请求需要携带的参数
 */
- (nullable id)requestArgument;

/**
 缓存文件名字
 
 @param argument 参数名字
 @return 缓存的文件名字
 */
- (id)cacheFileNameFilterForRequestArgument:(id)argument;

/**
 请求方式
 
 @return 方式
 */
- (IJSRequestMethod)requestMethod;

/**
 请求序列化的方式
 
 @return 序列化方式
 */
- (IJSRequestSerializerType)requestSerializerType;

/**
 响应序列化类型
 
 @return 响应体序列化
 */
- (IJSResponseSerializerType)responseSerializerType;

/**
 请求http 请求权限的方法 形式应该是 @[@"Username", @"Password"]
 
 @return 权限参数信息
 */
- (nullable NSArray<NSString *> *)requestAuthorizationHeaderFieldArray;

/**
 添加请求头信息
 
 @return 请求头信息
 */
- (nullable NSDictionary<NSString *, NSString *> *)requestHeaderFieldValueDictionary;

/**
 构建自定义请求 如果这个方法返回 non-nil value 将忽略 `requestUrl`, `requestTimeoutInterval`,`requestArgument`, `allowsCellularAccess`, `requestMethod` and `requestSerializerType` 这些方法
 
 @return 自定义请求
 */
- (nullable NSURLRequest *)buildCustomUrlRequest;

/**
 使用CDN
 
 @return 是否使用CDN
 */
- (BOOL)useCDN;

/**
 是否允许蜂窝煤数据 默认是YES
 
 @return 允许蜂窝煤
 */
- (BOOL)allowsCellularAccess;

/**
 设置responseJSONObject 验证服务器返回的信息 没有特殊的要求不要重写这个方法
 
 @return 检查的范围的数据类型
 */
- (nullable id)jsonValidator;

/**
 设置responseStatusCode 检验服务器数据格式信息
 
 @return 状态码信息
 */
- (BOOL)statusCodeValidator;

#pragma mark - ------------------------------请求的配置信息------------------------------------------------------------------------------------------
/**
 标识 默认是 0
 */
@property (nonatomic) NSInteger tag;

/**
 请求的用户信息,默认是 空
 */
@property (nonatomic, strong, nullable) NSDictionary *userInfo;

/**
 代理属性
 */
@property (nonatomic, weak, nullable) id<IJSRequestDelegate> delegate;

/**
 成功的回调
 */
@property (nonatomic, copy, nullable) IJSRequestCompletionBlock successCompletionBlock;

/**
 失败的回调
 */
@property (nonatomic, copy, nullable) IJSRequestCompletionBlock failureCompletionBlock;

/**
 添加的附加信息 如果使用 addAccessory 数字将自动创建
 */
@property (nonatomic, strong, nullable) NSMutableArray<id<IJSRequestAccessoryDelegate>> *requestAccessories;

/**
 发起 post 请求的body体 默认是空,这个对象属于AFN的对象
 */
@property (nonatomic, copy, nullable) AFConstructingBlock constructingBodyBlock;

/**
 恢复下载的路径 为空则使用NSURLSessionDownloadTask 在执行前会删除之前的路径,如果成功数据将自动保存 同时response 保存到responseData和 responseString
 为此 服务器需要支持  `Last-Modified` and/or `Etag`
 */
@property (nonatomic, strong, nullable) NSString *resumableDownloadPath;

/**
 恢复下载的进度的block ,和 resumableDownloadPath 作用相同
 */
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock resumableDownloadProgressBlock;

/**
 上传进度条
 */
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock resumableUploadProgressBlock;

/**
 请求的优先级 ios8之上有效 默认是 RequestPriorityDefault
 */
@property (nonatomic) IJSRequestPriority requestPriority;

/**
 设置成功失败的回调
 
 @param success 成功
 @param failure 失败
 */
- (void)setCompletionBlockWithSuccess:(nullable IJSRequestCompletionBlock)success
                              failure:(nullable IJSRequestCompletionBlock)failure;

/**
 清空失败成功的回调方法
 */
- (void)clearCompletionBlock;

/**
 添加附加信息的遍历构造器
 
 @param accessory 附加信息 详见 requestAccessories
 */
- (void)addAccessory:(id<IJSRequestAccessoryDelegate>)accessory;

@end
NS_ASSUME_NONNULL_END
