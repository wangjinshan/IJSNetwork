# IJSNetworking
感谢猿题库和afnetworking的开源框架给了我学习的机会

AFN的二次封装,学习Command设计模式的一次实践, 支持请求 批量请求 依赖请求 断点续传 增加了进度条的显示

所有请求的类都应该继承自 **IJSNCacheRequest**  
关系树如下: 

**IJSNBaseRequest**(请求基类) <-- **IJSNCacheRequest**(缓存处理类) <-- **你自己的类,填充数据类**
你自己的类主要的工作就是 重写 **IJSNBaseRequest** 属性的get 方法方便传给sdk 内部使用
上面是 请求的配置,

初次之外还可以进行全局配置 **IJSNetworkConfig**
这个类主要负责配置 baseurl cdnUrl AFSecurityPolicy 等等

具体实现方案如下:

appdelegate中配置

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupConfig];
    return YES;
}
//  进行配置比如 设置请求的 baseurl  cdn 等等
-(void)setupConfig
{
    IJSNetworkConfig *config =[IJSNetworkConfig sharedConfig];
    config.baseUrl = @"http://s.budejie.com";
    config.debugLogEnabled = YES;
}
```
创建你自己的类 IJSRegisterAPI 继承自 IJSNCacheRequest
实现如下:

```
@implementation IJSRegisterAPI
{
    NSString *_username;
    NSString *_password;
}
// 初始化方法
- (id)initWithUsername:(NSString *)username password:(NSString *)password
{
    self = [super init];
    if (self)
    {
        _username = username;
        _password = password;
    }
    return self;
}
// 需要和baseUrl拼接的地址
- (NSString *)requestUrl
{
    return @"/topic/list/zuixin/41/budejie-android-6.2.8/0-20.json";
}
//请求方法，某人是GET
- (IJSRequestMethod)requestMethod
{
    return IJSRequestMethodGET;
}
// 请求体,这个是在post 请求的时候添加 get 就重写
- (id)requestArgument
{
    return @{
             @"username": _username,
             @"password": _password
             };
}
// 服务器返回数据检验 注意返回的数据必须是检查的类型否则就是回调失败
- (id)jsonValidator
{
    return @{
             //        @"userId": [NSNumber class],
             //        @"nick": [NSString class],
             //        @"level": [NSNumber class]
             };
}

// 设置缓存时间单位 秒
- (NSInteger)cacheTimeInSeconds
{
    return 100;
}

// 缓存数据加载的类型
- (IJSResponseSerializerType)responseSerializerType
{
    return IJSResponseSerializerTypeHTTP;
}

/**
 请求序列化的方式
 
 @return 序列化方式
 */
- (IJSRequestSerializerType)requestSerializerType
{
    return IJSRequestSerializerTypeHTTP;
}

// 异步写入缓存
- (BOOL)writeCacheAsynchronously
{
    return YES;
}

- (void)requestCompleteFilter
{
    NSLog(@"----------qq-----------老子要在回调之前干点事情");
}
//
//-(NSURLRequest *)buildCustomUrlRequest
//{
//    return [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:@"http://s.budejie.com/topic/list/zuixin/41/budejie-android-6.2.8/0-20.json"]];
//}
```
写完就可以到 viewcontroller 中进行实际的调用
你可以在 viewdidload 方法中调用下面的方法

```
// 请求网络数据
-(void)_singleLoad
{
    IJSRegisterAPI *api =[[IJSRegisterAPI alloc]init];
  
    [api startWithCompletionBlockWithSuccess:^(__kindof IJSNBaseRequest * _Nonnull request) {
        
    } failure:^(__kindof IJSNBaseRequest * _Nonnull request) {
        
    }];
    // 进度条
    api.resumableDownloadProgressBlock = ^(NSProgress * _Nonnull progress) {
        NSLog(@"-------11---------%@",progress);
    };
    // 进队条
    api.resumableUploadProgressBlock = ^(NSProgress * _Nonnull progress) {
        NSLog(@"-----22---------%@",progress);
    };
}

// 下载
-(void)_downloadMP4
{
    IJSDownloadMP4 *mp4 =[[IJSDownloadMP4 alloc]init];
    
    [mp4 startWithCompletionBlockWithSuccess:^(__kindof IJSNBaseRequest * _Nonnull request) {
        
        NSLog(@"----ww-------------");
    } failure:^(__kindof IJSNBaseRequest * _Nonnull request) {
        NSLog(@"---------ee-----------");
    }];
    
    mp4.resumableDownloadProgressBlock = ^(NSProgress * _Nonnull progress) {
        NSLog(@"-------11---------%@",progress);
    };
    
    mp4.resumableUploadProgressBlock = ^(NSProgress * _Nonnull progress) {
        NSLog(@"-----22---------%@",progress);
    };
}

// 上传
-(void)_uploadImage
{
    IJSUploadApi *api =[[IJSUploadApi alloc] init];
    [api startWithCompletionBlockWithSuccess:^(__kindof IJSNBaseRequest * _Nonnull request) {
        
    } failure:^(__kindof IJSNBaseRequest * _Nonnull request) {
        
    }];
    // 进度检测
    api.resumableUploadProgressBlock = ^(NSProgress * _Nonnull progress) {
        
        
    };
}

//  同时发起多个请求的
-(void)_sendMoreRequest
{
    IJSRegisterAPI *api1 =[[IJSRegisterAPI alloc]init];
    IJSRegisterAPI *api2 =[[IJSRegisterAPI alloc]init];
    IJSRegisterAPI *api3 =[[IJSRegisterAPI alloc]init];
    
    IJSNBatchRequest *batch = [[IJSNBatchRequest alloc]initWithRequestArray:@[api1,api2,api3]];
    
    [batch startWithCompletionBlockWithSuccess:^(IJSNBatchRequest * _Nonnull batchRequest) {
        
    } failure:^(IJSNBatchRequest * _Nonnull batchRequest) {
        
        
    }];
    
}

/// 相互依赖的请求
-(void)_chainRequest
{
    IJSRegisterAPI *api =[[IJSRegisterAPI alloc]init];
    IJSNChainRequest *chain =[[IJSNChainRequest alloc]init];
  
    [chain addRequest:api callback:^(IJSNChainRequest * _Nonnull chainRequest, IJSNBaseRequest * _Nonnull baseRequest) {
        
        // 进行二次链式请求
        IJSDownloadMP4 *mp4 =[[IJSDownloadMP4 alloc]init];
        [chainRequest addRequest:mp4 callback:^(IJSNChainRequest * _Nonnull chainRequest, IJSNBaseRequest * _Nonnull baseRequest) {
            
            NSLog(@"成功");
        }];
    }];
    chain.delegate = self;
    [chain start];
    
}
/**
 链式请求成功
 */
- (void)chainRequestFinished:(IJSNChainRequest *)chainRequest
{
    NSLog(@"-----成功----");
}

/**
 链式请求失败
 */
- (void)chainRequestFailed:(IJSNChainRequest *)chainRequest failedBaseRequest:(IJSNBaseRequest *)request
{
    NSLog(@"-----失败的那个请求------%@",request);
}

```

下次更新计划 增加 afnetworking的api 
优化 IJSBaseRequest 这个类 增加一些接口方便调用


