
//
//  IJSNBatchRequest+RequestAccessory.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNBatchRequest+RequestAccessory.h"
#import "IJSNBaseRequest.h"


@implementation IJSNBatchRequest (RequestAccessory)

- (void)toggleAccessoriesWillStartCallBack {
    for (id<IJSRequestAccessoryDelegate> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(requestWillStart:)]) {
            [accessory requestWillStart:self];
        }
    }
}

- (void)toggleAccessoriesWillStopCallBack {
    for (id<IJSRequestAccessoryDelegate> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(requestWillStop:)]) {
            [accessory requestWillStop:self];
        }
    }
}

- (void)toggleAccessoriesDidStopCallBack {
    for (id<IJSRequestAccessoryDelegate> accessory in self.requestAccessories) {
        if ([accessory respondsToSelector:@selector(requestDidStop:)]) {
            [accessory requestDidStop:self];
        }
    }
}
@end
