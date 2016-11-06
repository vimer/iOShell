//
//  NSFileManager+Directory.m
//  DHQQ
//
//  Created by jianping on 14/10/23.
//  Copyright (c) 2014年 hujp. All rights reserved.
//

#import "NSFileManager+Directory.h"

@implementation NSFileManager (Directory)

- (BOOL)copyDirAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error
{
    BOOL isDir = NO;
    
    if (![self fileExistsAtPath:srcPath isDirectory:&isDir] || !isDir) {
        return NO;
    };
    
    if (isDir == NO) return NO;
    
    if ([self fileExistsAtPath:dstPath] == NO) {
        if (![self createDirectoryAtPath:dstPath withIntermediateDirectories:NO attributes:nil error:error]) {
            return NO;
        }
    }
    
    NSArray *fileList = [self contentsOfDirectoryAtPath:srcPath error:error];
    
    for (NSString *fileName in fileList) {
        
        NSString *filePath = [srcPath stringByAppendingPathComponent:fileName];
        
        BOOL isSubDir = NO;
        if ([self fileExistsAtPath:filePath isDirectory:&isSubDir]) {
            if (isSubDir) {
                if (![self copyDirAtPath:filePath toPath:[dstPath stringByAppendingPathComponent:fileName] error:error]) {
                    return NO;
                }
            } else {
                [self removeItemAtPath:[dstPath stringByAppendingPathComponent:fileName] error:nil];
                
                if (![self copyItemAtPath:filePath toPath:[dstPath stringByAppendingPathComponent:fileName] error:error]) {
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

@end
