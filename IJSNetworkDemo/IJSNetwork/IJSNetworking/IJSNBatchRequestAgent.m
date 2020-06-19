
//
//  IJSNBatchRequestAgent.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNBatchRequestAgent.h"
#import "IJSNBatchRequest.h"


@interface IJSNBatchRequestAgent ()

@property (strong, nonatomic) NSMutableArray<IJSNBatchRequest *> *requestArray;

@end


@implementation IJSNBatchRequestAgent

+ (IJSNBatchRequestAgent *)sharedAgent {
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
        _requestArray = [NSMutableArray array];
    }
    return self;
}

- (void)addBatchRequest:(IJSNBatchRequest *)request {
    @synchronized(self) {
        [_requestArray addObject:request];
    }
}

- (void)removeBatchRequest:(IJSNBatchRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}
@end
