//
//  InstallWeb.h
//  iOShell
//
//  Created by 疯哥 on 7/21/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InstallWeb : NSObject

+ (NSString *)downloadDir;
+ (NSString *)runDir;
+ (void)readPresetConfig;
+ (void)needToRefresh;
- (void)downloadConfig:(void (^)(NSError *error))failure;
- (void)preInstall;

@end