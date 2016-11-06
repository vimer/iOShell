//
//  DownloadItem.m
//  iOShell
//
//  Created by 疯哥 on 7/28/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import "CPPDataManager.h"
#import "OpenUDID.h"
#import "SoundMgr.h"
#import "AppDelegate.h"
#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "DHFileMgr.h"
#import "InstallWeb.h"

@implementation CPPDataManager

+(CPPDataManager*)sharedCPPDataManager {
    static CPPDataManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(!instance)instance = self.new;
    });
    return instance;
}

- (NSString*)getDeviceId {
    return [OpenUDID value];
}

- (void)playSound:(NSString*)soundName {
    [[[SoundMgr alloc] init] playSound:soundName];
}

//- (void)playDefaulSound {
//    [[[SoundMgr alloc] init] playDefaulSound];
//}
//
//1 landscape 2 potrait
- (void)switchDirection:(int)flag {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        ViewController*viewController = (ViewController*)app.window.rootViewController;
        [viewController switchDirection:flag];
        
    });
}

- (NSString*)readFileWithPath:(NSString*)filePath {
    return [[DHFileManager sharedDHFileManager]readFile:filePath];
}

- (int)writeFileWithPath:(NSString*)filePath withContent:(NSString*)content {
    int flag = [[DHFileManager sharedDHFileManager] writeFileOverWrite:filePath withContent:content];
    return flag;
}

- (BOOL)isTheFileExistLocal:(NSString*)fileName {
    BOOL res =  [self searchInLocalDirectory:fileName];
    return res;
}

- (NSString*)getTheFileExistLocal:(NSString*)fileName {
    NSString*localDocOrCachePath = [self searchInLocalDirectory:fileName];
    if (localDocOrCachePath) {
        return localDocOrCachePath;
    }
    return nil;
}

- (NSArray*)getAllSubPathsInServerBase {
    NSString* runDir = [InstallWeb runDir];
    NSArray* paths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:runDir error:nil];
    if (paths) {
        return paths;
    } else {
        return nil;
    }
}

- (NSString*)searchInLocalApp:(NSString*)fileName {
    NSString* res = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileName rangeOfString:@"."].location == NSNotFound) {
        
    } else {
        NSArray*fileNameAndExt = [fileName componentsSeparatedByString:@"."];
        NSString*file = fileNameAndExt[0];
        NSString*fileTyep = fileNameAndExt[1];
        NSString*path = [[NSBundle mainBundle] pathForResource:file ofType:fileTyep];
        if ([fileManager fileExistsAtPath:path]) {
            res = path;
        } else {
            path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileName];
            if ([fileManager fileExistsAtPath:path]) {
                res = path;
            }
        }
    }
    if (!res) {
        NSString*runDir = [InstallWeb runDir];
        NSString*path = [runDir stringByAppendingPathComponent:fileName];
        if ([self isFileExist:path]) {
            res = path;
        }
    }
    return res;
}

- (NSString*)searchInLocalDirectory:(NSString*)fileName {
    NSString* runDir = [InstallWeb runDir];
    NSString* res =  [self searchRecursiveInDir:runDir withFileName:fileName];
    if (res) {
        return res;
    } else {
        return nil;
    }
}

- (NSString*)searchRecursiveInDir:(NSString*)dir withFileName:(NSString*)fileName {
    NSString* res =  nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* path = [dir stringByAppendingPathComponent:fileName];
    if ([fileManager fileExistsAtPath:path]) {
        res = path;
        return res;
    } else {
        NSArray*paths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:dir error:nil];
        for (NSString* p in paths) {
            if ([p hasSuffix:fileName]) {
                res = [NSString stringWithFormat:@"%@/%@", dir, p];
                break;
            }
        }
    }
    return res;
}

@end
