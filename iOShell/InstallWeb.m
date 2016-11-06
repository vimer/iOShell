//
//  InstallWeb.m
//  iOShell
//
//  Created by 疯哥 on 7/21/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import "InstallWeb.h"
#import "Global.h"
#import "ZipArchive.h"
#import "DownloadWeb.h"
#import "AppDelegate.h"
#import "AFHTTPSessionManager.h"
#import "BatchDownloadManager.h"
#import "DownloadItem.h"

@interface InstallWeb()

@property (nonatomic, strong) DownloadWeb* downloadWeb;
@property (nonatomic, strong) NSURL *versionUrl;
@property (nonatomic, assign) BOOL isCheckVersion;
//@property(nonatomic, strong) NSMutableDictionary* startConfig;

@end

@implementation InstallWeb

-(DownloadWeb*)downloadWeb {
    if (!_downloadWeb) _downloadWeb = [[DownloadWeb alloc] init];
    return _downloadWeb;
}

static NSString* zipFileName = @"web";

/**
 *  Web下载目录
 *
 *  @return 路径
 */
+ (NSString *)downloadDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths.firstObject stringByAppendingPathComponent:@"download"];
}

/**
 *  Web运行目录
 *
 *  @return 路径
 */
+ (NSString *)runDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths.firstObject stringByAppendingPathComponent:@"run"];
}

/**
 *  获取预安装的zip目录
 *
 *  @return 路径
 */
+ (NSString *)zipDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths.firstObject stringByAppendingPathComponent:@"zip"];
}

/**
 *  预安装Web, 解压到runDir目录
 */
- (void)preInstall {
    logRed(@"preInstall Start");
//    如果已经安装过，就不进行安装 | 这里注释是为了防止在苹果审核的时候出现异常，替换掉原来的config.xml，但是如果注释就会把本地的替换过去（所以测试要注意）
//    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"preInstalled"]) {
//        logYellow(@"检测到未安装");
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"preInstalled"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    } else {
//        logYellow(@"已经检测到已经安装");
//        return ;
//    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:[InstallWeb zipDir]]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[InstallWeb zipDir] withIntermediateDirectories:YES attributes:nil error:nil];
        
    }
    NSString* zipPath = [[NSBundle mainBundle] pathForResource:zipFileName ofType:@"zip"];
    log(@"%@", zipPath);
    ZipArchive* za = [[ZipArchive alloc] init];
    if ([za UnzipOpenFile:zipPath]) {
        [za UnzipFileTo:[InstallWeb runDir] overWrite: YES];
        [za UnzipCloseFile];
    }
    logRed(@"preInstall End");
}

- (void)downloadConfig:(void (^)(NSError *error))failure {
//    NSFileManager* fileManager = [NSFileManager defaultManager];
//    NSString* configPath = [[InstallWeb runDir] stringByAppendingPathComponent:@"config.xml"];
//    if (![fileManager fileExistsAtPath:configPath]) { //若不存在，进行下载
    
        //强制下载到run目录
    NSString* path = [InstallWeb runDir];
    path = [path stringByAppendingPathComponent:@"config.xml"];
    NSURL* url = [NSURL fileURLWithPath:path];
    log(@"config_path=%@，url=%@", path, url);
    [[BatchDownloadManager sharedBatchDownloadManager] downloadFile:[NSURL URLWithString:g_configUrl] to:[NSURL fileURLWithPath:[[InstallWeb runDir] stringByAppendingPathComponent:@"config.xml"]] withCompletionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            if (!error) {
                NSXMLParser*  parser=[[NSXMLParser alloc] initWithContentsOfURL:url];
                parser.delegate = self;
                [parser parse];
            } else {
                if (failure) {
                    failure(@"download config.xml failed!");
                }
//                NSXMLParser*  parser=[[NSXMLParser alloc] initWithContentsOfURL:url];
//                parser.delegate = self;
//                [parser parse];
            }
        }];
//    } else {
//        log(@"存在");
//        NSString* path = [InstallWeb runDir];
//        path = [path stringByAppendingPathComponent:@"config.xml"];
//        NSURL* url = [NSURL fileURLWithPath:path];
//        log(@"config_path=%@，url=%@", path, url);
//        NSXMLParser*  parser=[[NSXMLParser alloc] initWithContentsOfURL:url];
//        parser.delegate = self;
//        [parser parse];
//    }
}

/**
 *  读取Config.xml信息
 */
+ (void)readPresetConfig {
    logRed(@"readConfig Start");
    NSString* path = [InstallWeb runDir];
    path = [path stringByAppendingPathComponent:@"config.xml"];
    NSURL* url = [NSURL fileURLWithPath:path];
    log(@"config_path=%@，url=%@", path, url);
    NSXMLParser*  parser=[[NSXMLParser alloc] initWithContentsOfURL:url];
    parser.delegate = self;
    [parser parse];
    logRed(@"readConfig End");
}

/**
 *  刷新界面
 */
+ (void)needToRefresh {
//    logRed(@"Need to refresh web Start");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:nil];
//    logRed(@"Need to refresh web End");
}

/**
 *  解析config.xml
 */
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"IOS"]) {  //强制更新
        log(@"parse IOS update Start");
        NSString* AppUpdateURL = [attributeDict objectForKey:@"AppUpdate"];
        NSString* configVersion = [attributeDict objectForKey:@"Version"];
//        NSString* WantUpdate = [attributeDict objectForKey:@"WantUpdate"];
        log(@"%@", configVersion)
        [self checkIfNeedToUpdateAppstore:configVersion withAppStoreUrl:AppUpdateURL wantUpdate:nil];
        log(@"parse IOS update End");
        
    } else if ([elementName isEqualToString:@"HTTP"]) {
        logRed(@"parser HTTTP Start");
        NSString* FileUpdateURL = [attributeDict objectForKey:@"FileUpdate"];
        NSString* FileChangedlistURL = [attributeDict objectForKey:@"FileChanged"];
        [[NSUserDefaults standardUserDefaults] setObject:[attributeDict objectForKey:@"key"] forKey:@"createKey"];
        NSLog(@"FileUpdateURL=%@, FileChangedlistURL=%@, Key=%@", FileUpdateURL, FileChangedlistURL, [attributeDict objectForKey:@"key"]);
        [self.downloadWeb initCheckAndUpdateWithChangeFileListUrl:FileChangedlistURL withDownloadFileUrl:FileUpdateURL];
        logRed(@"parser HTTP End");
    }
}

- (void)showAlertView {
    log(@"version...");
    if (self.versionUrl) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"有新版本请立刻升级获得更多功能" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[UIApplication sharedApplication] openURL:self.versionUrl];
}

- (void)checkIfNeedToUpdateAppstore:(NSString*)configVersion withAppStoreUrl:(NSString*)url wantUpdate:(NSString*)wantUpdate {
    BOOL needToUpdate = NO;
    if (!configVersion) {
        needToUpdate = YES;
    }
    NSString* currentversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    float numCurrentVersion = [currentversion floatValue];
    float numConfigVersion = [configVersion floatValue];
    log(@"%@, %f, %f", currentversion, numCurrentVersion, numConfigVersion);
    //如果当前版本大于线上版本config.xml就不更新
    if (numCurrentVersion < numConfigVersion) {
        needToUpdate = YES;
    }
    if (needToUpdate) { 
        logRed(@"强制升级.");
        self.versionUrl = [NSURL URLWithString:url];
        [self showAlertView];
    }
}

- (void)checkNewVersionWithUrl:(NSString*)updateUrl withUpdateFileUrl:(NSString*)fileUrl {
    if (self.versionUrl) {
        [self showAlertView];
        return ;
    }
    
    if (self.isCheckVersion) return;
    self.isCheckVersion = YES;
    NSString *appUpdateTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdateTime"];
    if (appUpdateTime == nil) {
        appUpdateTime = @"0";
    }
    //appname ios_update是用来自升级用的
    NSString*urlToUpdate = [NSString stringWithFormat:@"%@%@",updateUrl,appUpdateTime];
    [[[AFHTTPSessionManager alloc] init] GET:urlToUpdate  parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *op = [responseObject objectForKey:@"op"];
            if ([[op objectForKey:@"code"] isEqualToString:@"Y"]) {
                
                NSArray *changelist = [responseObject objectForKey:@"changelist"];
                NSDictionary *item = changelist.firstObject;
                NSString *appLastUpdateTime = [item objectForKey:@"updatetime"];
                NSString *filepath = [item objectForKey:@"path"];
                filepath = [filepath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
                if ([filepath hasPrefix:@"/"]) {
                    filepath = [filepath substringFromIndex:1];
                }
                //自定义升级，服务器下发appstore下发的url，然后跳转过去到appstore进行更新
                NSString *urlString = [NSString stringWithFormat:@"%@%@",fileUrl,filepath];
                if (([filepath isKindOfClass:NSString.class ] && filepath.length > 0) && urlString.length > 0) {
                    AFHTTPSessionManager *httpSession = [[AFHTTPSessionManager alloc] init];
                    httpSession.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
                    [httpSession GET:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                        if (appLastUpdateTime != nil) {
                            [[NSUserDefaults standardUserDefaults] setObject:appLastUpdateTime forKey:@"lastUpdateTime"];
                        }
                        NSString *newVersonUrl = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                        newVersonUrl = [newVersonUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        self.versionUrl = [NSURL URLWithString:newVersonUrl];
                        self.isCheckVersion = NO;
                        [self showAlertView];
                        
                    } failure:^(NSURLSessionDataTask *task, NSError *error) {
                        self.isCheckVersion = NO;
                    }];
                } else {
                    self.isCheckVersion = NO;
                }
            } else {
                self.isCheckVersion = NO;
            }
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        self.isCheckVersion = NO;
    }];
}


@end
