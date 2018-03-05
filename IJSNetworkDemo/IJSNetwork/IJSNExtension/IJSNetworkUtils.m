
//
//  IJSNetworkUtils.m
//  IJSNetworkDemo
//
//  Created by 山神 on 2018/3/5.
//  Copyright © 2018年 山神. All rights reserved.
//
#import <CommonCrypto/CommonDigest.h>
#import "IJSNetworkUtils.h"
#import "IJSNetworkConfig.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFURLRequestSerialization.h>
#else
#import "AFURLRequestSerialization.h"
#endif

void IJSNLog(NSString *format, ...)
{
#ifdef DEBUG
    if (![IJSNetworkConfig sharedConfig].debugLogEnabled)
    {
        return;
    }
    va_list argptr;
    va_start(argptr, format);
    NSLogv(format, argptr);
    va_end(argptr);
#endif
}
@implementation IJSNetworkUtils

//判断json的有效性
+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator
{
    if ([json isKindOfClass:[NSDictionary class]] &&
        [jsonValidator isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = json;
        NSDictionary *validator = jsonValidator;
        BOOL result = YES;
        NSEnumerator *enumerator = [validator keyEnumerator]; // 快速枚举对象 获取所有的 key
        NSString *key;
        while ((key = [enumerator nextObject]) != nil)
        {//NSEnumerator的nextObject方法可以遍历每个集合元素，结束返回nil，通过与while结合使用可遍历集合中所有项
            id value = dict[key];
            id format = validator[key];
            if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]])
            {
                result = [self validateJSON:value withValidator:format];  // 递归调用
                if (!result)
                {
                    break;
                }
            }
            else
            {
                if ([value isKindOfClass:format] == NO &&
                    [value isKindOfClass:[NSNull class]] == NO)
                {
                    result = NO;
                    break;
                }
            }
        }
        return result;
    }
    else if ([json isKindOfClass:[NSArray class]] &&
             [jsonValidator isKindOfClass:[NSArray class]])
    {
        NSArray *validatorArray = (NSArray *) jsonValidator;
        if (validatorArray.count > 0)
        {
            NSArray *array = json;
            NSDictionary *validator = jsonValidator[0];
            for (id item in array)
            {
                BOOL result = [self validateJSON:item withValidator:validator];
                if (!result)
                {
                    return NO;
                }
            }
        }
        return YES;
    }
    else if ([json isKindOfClass:jsonValidator])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

+ (void)addDoNotBackupAttribute:(NSString *)path
{
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (error)
    {
        IJSNLog(@"error to set do not backup attribute, error = %@", error);
    }
}

+ (NSString *)md5StringFromString:(NSString *)string
{
    NSParameterAssert(string != nil && [string length] > 0);
    
    const char *value = [string UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG) strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++)
    {
        [outputString appendFormat:@"%02x", outputBuffer[count]];
    }
    
    return outputString;
}

+ (NSString *)appVersionString
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSStringEncoding)stringEncodingWithRequest:(IJSNBaseRequest *)request
{
    // From AFNetworking 2.6.3
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;  // utf8 值为4
    if (request.response.textEncodingName)
    {
        CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef) request.response.textEncodingName);
        if (encoding != kCFStringEncodingInvalidId)
        {
            stringEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
        }
    }
    return stringEncoding;
}

+ (BOOL)validateResumeData:(NSData *)data
{
    // From http://stackoverflow.com/a/22137510/3562486
    if (!data || [data length] < 1)
        return NO;
    
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error)
        return NO;
    
    // Before iOS 9 & Mac OS X 10.11
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED < 101100)
    NSString *localFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    if ([localFilePath length] < 1)
        return NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
#endif
    // After iOS 9 we can not actually detects if the cache file exists. This plist file has a somehow
    // complicated structue. Besides, the plist structure is different between iOS 9 and iOS 10.
    // We can only assume that the plist being successfully parsed means the resume data is valid.
    return YES;
}

@end
