//
//  IJSNBaseRequest+RequestAccessory.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNBaseRequest+RequestAccessory.h"


@implementation IJSNBaseRequest (RequestAccessory)

//  协议方法即将开始
- (void)toggleAccessoriesWillStartCallBack {
    for (id<IJSRequestAccessoryDelegate> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(requestWillStart:)]) {
            [accessory requestWillStart:self];
        }
    }
}

// 告知协议 协议的方法即将开始
- (void)toggleAccessoriesWillStopCallBack {
    for (id<IJSRequestAccessoryDelegate> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(requestWillStop:)]) {
            [accessory requestWillStop:self];
        }
    }
}
// 协议的方法已经停止
- (void)toggleAccessoriesDidStopCallBack {
    for (id<IJSRequestAccessoryDelegate> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(requestDidStop:)]) {
            [accessory requestDidStop:self];
        }
    }
}

@end
