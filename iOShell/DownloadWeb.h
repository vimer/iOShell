//
//  DownloadWeb.h
//  iOShell
//
//  Created by 疯哥 on 7/22/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadWeb : NSObject

@property (nonatomic, strong) NSString* FileChangedListUrl;
@property (nonatomic, strong) NSString* FileUpdateUrl;

- (void)initCheckAndUpdateWithChangeFileListUrl:(NSString*)FileChangedlistUrl
                            withDownloadFileUrl:(NSString*)FileUpdateUrl;
- (void)checkAndCopyFileToRunDir;

@end