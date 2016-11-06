//
//  BatchDownloadManager.h
//  iOShell
//
//  Created by 疯哥 on 7/28/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ASIHTTPRequest;

@interface BatchDownloadManager : NSObject
+(BatchDownloadManager*)sharedBatchDownloadManager;

- (void)downloadFile:(NSURL *)fileUrl to:(NSURL *)filePath withCompletionHandler:(void (^)(NSURLResponse *res, NSURL *filePath, NSError *error))completionHandler;
- (BOOL)isAllTaskDone;

@end
