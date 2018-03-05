//
//  IJSRegisterAPI.h
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSNCacheRequest.h"

@interface IJSRegisterAPI : IJSNCacheRequest


- (id)initWithUsername:(NSString *)username password:(NSString *)password;

- (NSString *)userId;














@end
