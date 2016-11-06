//
//  NSString+Data.h
//  AppBase
//
//  Created by jianping on 14-10-11.
//  Copyright (c) 2014年 hujp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Data)

+ (instancetype)stringWithData:(NSData *)data; //NSUTF8StringEncoding

+ (instancetype)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;

+ (instancetype)stringWithBase64Str:(NSString *)base64;

- (NSString *)base64EncodedString;

@end
