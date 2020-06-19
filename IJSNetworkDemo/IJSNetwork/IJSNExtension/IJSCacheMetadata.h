//
//  IJSCacheMetadata.h
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import <Foundation/Foundation.h>
// 序列化的类 用来保存序列化的东西
@interface IJSCacheMetadata : NSObject <NSSecureCoding>

@property (nonatomic, assign) long long version;               //版本
@property (nonatomic, strong) NSString *sensitiveDataString;   //敏感信息
@property (nonatomic, assign) NSStringEncoding stringEncoding; //编码格式
@property (nonatomic, strong) NSDate *creationDate;            //创建时间
@property (nonatomic, strong) NSString *appVersionString;      //app版本等信息

@end
