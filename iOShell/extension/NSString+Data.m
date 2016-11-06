//
//  NSString+Data.m
//  AppBase
//
//  Created by jianping on 14-10-11.
//  Copyright (c) 2014年 hujp. All rights reserved.
//

#import "NSString+Data.h"

@implementation NSString (Data)

+ (instancetype)stringWithData:(NSData *)data //NSUTF8StringEncoding
{
    return [self stringWithData:data encoding:NSUTF8StringEncoding];
}

+ (instancetype)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
    return [[NSString alloc] initWithData:data encoding:encoding];
}

+ (instancetype)stringWithBase64Str:(NSString *)base64
{
    return [NSString stringWithData:[[NSData alloc] initWithBase64EncodedString:base64 options:0]];
}

- (NSString *)base64EncodedString
{
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}

@end
