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
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

//    [self _singleLoad];
    [self _downloadMP4];
}

-(void)_singleLoad
{
    IJSRegisterAPI *api =[[IJSRegisterAPI alloc]initWithUsername:@"1999" password:@"1000"];
  
    [api startWithCompletionBlockWithSuccess:^(__kindof IJSNBaseRequest * _Nonnull request) {
        
    } failure:^(__kindof IJSNBaseRequest * _Nonnull request) {
        
        
    }];

    api.resumableDownloadProgressBlock = ^(NSProgress * _Nonnull progress) {
        NSLog(@"-------11---------%@",progress);
    };
    
    api.resumableUploadProgressBlock = ^(NSProgress * _Nonnull progress) {
        NSLog(@"-----22---------%@",progress);
    };
    
}

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







@end
