

//
//  IJSNChainRequestAgent.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNChainRequestAgent.h"
#import "IJSNChainRequest.h"


@interface IJSNChainRequestAgent ()

@property (strong, nonatomic) NSMutableArray<IJSNChainRequest *> *requestArray;

@end


@implementation IJSNChainRequestAgent

+ (IJSNChainRequestAgent *)sharedAgent {
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

- (void)addChainRequest:(IJSNChainRequest *)request {
    @synchronized(self) {
        [_requestArray addObject:request];
    }
}

- (void)removeChainRequest:(IJSNChainRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}

@end
