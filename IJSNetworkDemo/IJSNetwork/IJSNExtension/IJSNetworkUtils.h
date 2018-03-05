//
//  IJSNetworkUtils.h
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IJSNBaseRequest.h"
#import "IJSNetworkRequestAgent.h"
NS_ASSUME_NONNULL_BEGIN
/**
 提供JSON验证，appVersion等辅助性的方法；给YTKBaseRequest增加一些分类。
 */
FOUNDATION_EXPORT void IJSNLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
@class AFHTTPSessionManager;

@interface IJSNetworkUtils : NSObject

+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;

+ (void)addDoNotBackupAttribute:(NSString *)path;

+ (NSString *)md5StringFromString:(NSString *)string;

+ (NSString *)appVersionString;

+ (NSStringEncoding)stringEncodingWithRequest:(IJSNBaseRequest *)request;

+ (BOOL)validateResumeData:(NSData *)data;


@end

#pragma mark -----------------------添加分类添加几个属性,只有声明没有实现,然后去实现分类的属性方法------------------------------

@interface IJSNBaseRequest (Getter)

- (NSString *)cacheBasePath;

@end

/**
 此分类的主要目的是解决外部暴露的接口只读属性的设置
 */
@interface IJSNBaseRequest (Setter)

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite, nullable) NSData *responseData;
@property (nonatomic, strong, readwrite, nullable) id responseJSONObject;
@property (nonatomic, strong, readwrite, nullable) id responseObject;
@property (nonatomic, strong, readwrite, nullable) NSString *responseString;
@property (nonatomic, strong, readwrite, nullable) NSError *error;

@end

@interface IJSNetworkRequestAgent (Private)

- (AFHTTPSessionManager *)manager;
- (void)resetURLSessionManager;
- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration;

- (NSString *)incompleteDownloadTempCacheFolder;


@end

NS_ASSUME_NONNULL_END
