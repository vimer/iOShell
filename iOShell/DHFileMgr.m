//
//  DownloadItem.m
//  iOShell
//
//  Created by 疯哥 on 7/28/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import "DHFileMgr.h"

@implementation DHFileManager

+(DHFileManager*)sharedDHFileManager {
    static DHFileManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[self alloc] init];
        }
    });
    return instance;
}

-(NSString *)getFilePath:(NSString*)fileName {
    if ([fileName isKindOfClass:NSString.class] && fileName.length > 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if ([paths count] > 0) {
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *resPath = [documentsDirectory stringByAppendingPathComponent:fileName];
            return resPath;
        }
        
    } else {
        return nil;
    }
    return nil;
}

//创建文件 0 fail 1 suc
-(int)createFile:(NSString *)fileName {
    BOOL flag = NO;
    NSString*path = fileName;
    NSFileManager*manager = [NSFileManager defaultManager];
    flag = [manager fileExistsAtPath:path];
    if (flag) {
        return 1;
    } else {
        flag = [manager createFileAtPath:path contents:[@"" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    return flag?1:0;
}

//创建文件夹
-(int)createFileDir:(NSString *)filePath {
    BOOL flag = NO;
    NSString*path = filePath;
    NSFileManager*manager = [NSFileManager defaultManager];
    flag = [manager fileExistsAtPath:path];
    if (flag) {
        return 0;
    } else {
        NSError*err = nil;
        flag = [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
    }
    return flag ? 0 : 1;
}

//删除文件，文件夹,文件不存在返0，删除失败返回0，删除成功返回1
-(int)removeFile:(NSString *)fileName {
    BOOL flag = NO;
    NSString*path = fileName;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        flag = [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    }
    return flag ? 1 : 0;
}

//判断文件是否存在 1存在 0不存在
-(int)isFileExist:(NSString *)fileName {
    NSString*path = fileName;
    return [[NSFileManager defaultManager] fileExistsAtPath:path]?1:0;
}

//写文件覆盖
- (int)writeFileOverWrite:(NSString*)fileName withContent:(NSString*)content {
    BOOL flag = NO;
    NSString*path = fileName;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        flag = [content writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    } else {
        NSString*parentDir = [path stringByDeletingLastPathComponent];
        if (![[NSFileManager defaultManager] fileExistsAtPath:parentDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:parentDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        flag = [content writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    return flag ? 1 : 0;
}

//读取文件
- (NSString*)readFile:(NSString*)fileName {
    NSString*path = fileName;
    NSString*content = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError*err = nil;
        content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    }
    return content;
}
@end
