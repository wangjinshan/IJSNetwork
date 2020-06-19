
//
//  IJSDownloadMP4.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSDownloadMP4.h"


@implementation IJSDownloadMP4 {
    NSString *_username;
    NSString *_password;
}

// 需要和baseUrl拼接的地址
- (NSString *)requestUrl {
    return @"http://dvideo.spriteapp.cn/video/2018/0305/91dae4b4202711e897b5842b2b4c75ab_wpdm.mp4";
    //    return @"/topic/list/zuixin/41/budejie-android-6.2.8/0-20.json";
}
//请求方法，某人是GET
- (IJSRequestMethod)requestMethod {
    return IJSRequestMethodGET;
}
/**
 构建自定义请求 如果这个方法返回 non-nil value 将忽略 `requestUrl`, `requestTimeoutInterval`,`requestArgument`, `allowsCellularAccess`, `requestMethod` and `requestSerializerType` 这些方法
 
 @return 自定义请求
 */

//- (NSURLRequest *)buildCustomUrlRequest
//{
//    return [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://s.budejie.com/topic/list/zuixin/41/budejie-android-6.2.8/0-20.json"]];
//}

- (NSInteger)cacheTimeInSeconds {
    return 0;
}

// 缓存数据加载的类型
//- (IJSResponseSerializerType)responseSerializerType
//{
//    return IJSResponseSerializerTypeJSON;
//}

/**
 请求序列化的方式
 
 @return 序列化方式
 */
//- (IJSRequestSerializerType)requestSerializerType
//{
//    return IJSRequestSerializerTypeJSON;
//}
// 缓存路径
- (NSString *)resumableDownloadPath {
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *cachePath = [libPath stringByAppendingPathComponent:@"Caches"];
    NSString *filePath = [cachePath stringByAppendingPathComponent:@"1999.mp4"];
    NSLog(@"--------file------------%@", filePath);
    return filePath;
}
@end
