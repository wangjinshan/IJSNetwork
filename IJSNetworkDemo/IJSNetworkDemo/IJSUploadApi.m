//
//  IJSUploadApi.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/6.
//  Copyright © 2018年 山神. All rights reserved.
//

#import "IJSUploadApi.h"
#import "AFNetworking.h"

@implementation IJSUploadApi
{
    UIImage *_image;
}

- (id)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self)
    {
        _image = image;
    }
    return self;
}

- (IJSRequestMethod)requestMethod
{
    return IJSRequestMethodPOST;
}

- (NSString *)requestUrl {
    return @"/iphone/image/upload";
}

- (AFConstructingBlock)constructingBodyBlock
{
    return ^(id<AFMultipartFormData> formData) {
        NSData *data = UIImageJPEGRepresentation(_image, 0.9);
        NSString *name = @"image";
        NSString *formKey = @"image";
        NSString *type = @"image/jpeg";
        [formData appendPartWithFileData:data name:formKey fileName:name mimeType:type];
    };
}

- (id)jsonValidator
{
    return @{ @"imageId": [NSString class] };
}

- (NSString *)responseImageId
{
    NSDictionary *dict = self.responseJSONObject;
    return dict[@"imageId"];
}
@end



