//
//  BatchDownloadManager.m
//  iOShell
//
//  Created by 疯哥 on 7/28/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import "BatchDownloadManager.h"
#import "AFNetworking.h"
#import "Global.h"

@interface BatchDownloadManager ()

@property(nonatomic, strong)AFURLSessionManager* urlSessionManager;
@end

@implementation BatchDownloadManager
+(BatchDownloadManager*)sharedBatchDownloadManager
{
    static BatchDownloadManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(!instance)instance = [self new];
    });
    return instance;
}

-(instancetype)init
{
    logYellow(@"init....");
    if (self = [super init]) {
        self.urlSessionManager = [AFURLSessionManager.alloc initWithSessionConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration];
    }
    return self;
}

- (void)downloadFile:(NSURL *)fileUrl to:(NSURL *)filePath withCompletionHandler:(void (^)(NSURLResponse *res, NSURL *filePath, NSError *error))completionHandler
{
    NSString *fileDir = [filePath.path stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    static int index = 1;
    static int sucIndex = 1;
    static int failIndex = 1;
    
    NSURLSessionDownloadTask *task =[self.urlSessionManager downloadTaskWithRequest:[NSURLRequest requestWithURL:fileUrl] progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response){
        
        return filePath;
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (error == nil) {
            log(@"download suc %d %@ %d",sucIndex++,fileUrl.absoluteString, [self.urlSessionManager tasks].count);
            log(@"%@", error);
            completionHandler(response, filePath, error);
        } else {
            log(@"download fail %d %@",failIndex++,fileUrl.absoluteString);
            completionHandler(response, nil, error);
        }
    }];
    
    task.taskDescription = [filePath absoluteString];
    [task resume];
}

- (BOOL)isAllTaskDone {
    return  [self.urlSessionManager tasks].count == 0;
}

@end