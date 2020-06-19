//
//  IJSNBatchRequest+RequestAccessory.h
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNBatchRequest.h"


@interface IJSNBatchRequest (RequestAccessory)
/**
 请求将开始
 */
- (void)toggleAccessoriesWillStartCallBack;

/**
 请求将停止
 */
- (void)toggleAccessoriesWillStopCallBack;

/**
 请求已经停止
 */
- (void)toggleAccessoriesDidStopCallBack;
@end
