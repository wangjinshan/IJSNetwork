
//
//  IJSRegisterAPI.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSRegisterAPI.h"

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
// 请求体
- (id)requestArgument
{
    return @{
             @"username": _username,
             @"password": _password
             };
}
// 服务器返回数据检验
- (id)jsonValidator
{
    return @{
             //        @"userId": [NSNumber class],
             //        @"nick": [NSString class],
             //        @"level": [NSNumber class]
             };
}

- (NSString *)userId
{
    return [[[self responseJSONObject] objectForKey:@"userId"] stringValue];
}

- (NSInteger)cacheTimeInSeconds
{
    return 0;
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




























@end
