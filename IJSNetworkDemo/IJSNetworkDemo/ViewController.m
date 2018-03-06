//
//  ViewController.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "ViewController.h"
#import "IJSRegisterAPI.h"
#import "IJSDownloadMP4.h"
#import "IJSUploadApi.h"
#import "IJSNetworking.h"

@interface ViewController ()<IJSNChainRequestDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

//    [self _singleLoad];
    [self _downloadMP4];
}

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





@end
