//
//  AppDelegate.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "AppDelegate.h"
#import "IJSNetworkConfig.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupConfig];
    
    
    return YES;
}

-(void)setupConfig
{
    //    http://s.budejie.com/topic/list/zuixin/41/budejie-android-6.2.8/0-20.json
    // http://dvideo.spriteapp.cn/video/2018/0305/91dae4b4202711e897b5842b2b4c75ab_wpdm.mp4
   
    IJSNetworkConfig *config =[IJSNetworkConfig sharedConfig];
    config.baseUrl = @"http://s.budejie.com";
//    config.cdnUrl = @"http://dvideo.spriteapp.cn";
    config.debugLogEnabled = YES;

}















@end
