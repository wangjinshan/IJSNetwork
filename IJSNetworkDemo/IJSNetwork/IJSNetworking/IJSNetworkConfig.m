
//
//  IJSNetworkConfig.m
//  IJSNetworking
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNetworkConfig.h"
#import "IJSNBaseRequest.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif


@interface IJSNetworkConfig ()

@property (nonatomic, strong) NSMutableArray<id<IJSUrlFilterDelegate>> *urlFilters;                   // url过滤数组
@property (nonatomic, strong) NSMutableArray<id<IJSCacheDirPathFilterDelegate>> *cacheDirPathFilters; // 缓存过滤数组

@end


@implementation IJSNetworkConfig

+ (IJSNetworkConfig *)sharedConfig {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.baseUrl = @"";
        self.cdnUrl = @"";
        self.securityPolicy = [AFSecurityPolicy defaultPolicy];
        self.debugLogEnabled = NO;
        self.urlFilters = [NSMutableArray array];
        self.cacheDirPathFilters = [NSMutableArray array];
    }
    return self;
}

- (void)addUrlFilter:(id<IJSUrlFilterDelegate>)filter {
    [self.urlFilters addObject:filter];
}

- (void)clearUrlFilter {
    [self.urlFilters removeAllObjects];
}

- (void)addCacheDirPathFilter:(id<IJSCacheDirPathFilterDelegate>)filter {
    [_cacheDirPathFilters addObject:filter];
}

- (void)clearCacheDirPathFilter {
    [_cacheDirPathFilters removeAllObjects];
}

- (NSArray<id<IJSUrlFilterDelegate>> *)urlFilters {
    return [_urlFilters copy];
}

- (NSArray<id<IJSCacheDirPathFilterDelegate>> *)cacheDirPathFilters {
    return [_cacheDirPathFilters copy];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ baseURL: %@ } { cdnURL: %@ }", NSStringFromClass([self class]), self, self.baseUrl, self.cdnUrl];
}

@end
