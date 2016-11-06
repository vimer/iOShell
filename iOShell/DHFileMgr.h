//
//  DownloadItem.m
//  iOShell
//
//  Created by 疯哥 on 7/28/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface DHFileManager : NSObject

+ (DHFileManager*)sharedDHFileManager;
- (int)createFile:(NSString *)fileName;
- (int)createFileDir:(NSString *)fileName;
- (int)removeFile:(NSString *)fileName;
- (int)isFileExist:(NSString *)fileName;
- (int)writeFileOverWrite:(NSString*)fileName withContent:(NSString*)content;
- (NSString*)readFile:(NSString*)fileName;

@end
