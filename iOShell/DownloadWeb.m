//
//  DownloadWeb.m
//  iOShell
//
//  Created by 疯哥 on 7/22/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import "AppDelegate.h"
#import "DownloadWeb.h"
#import "InstallWeb.h"
#import "Global.h"
#include <pthread.h>
#import "AFHTTPSessionManager.h"
#import "BatchDownloadManager.h"
#import "NSFileManager+Directory.h"
#import "DownloadItem.h"
#import "ViewController.h"
#import "loadingModel.h"
#import "Reachability.h"

@interface DownloadWeb () <UIWebViewDelegate>
{
    int fileCount;
    int curFileCount;
}
@property (nonatomic, strong) NSMutableArray* fileList;
@property (nonatomic, strong) NSMutableArray* tempFileList;
@property (nonatomic, assign) BOOL isCheckUpdate;
@property (nonatomic, assign) BatchDownloadManager* batchDownloadManager;
@property (nonatomic, strong) NSNumber* maxLastUpdateTime;
@property (nonatomic, strong) NSMutableArray* arrHttpServer;
@property (nonatomic) Reachability *hostReachability;


@end

@implementation DownloadWeb

-(BatchDownloadManager*)batchDownloadManager {
    if (_batchDownloadManager) _batchDownloadManager = [[BatchDownloadManager alloc] init];
    return _batchDownloadManager;
}

+ (NSString*)archivePath {
    NSString* rundir = [InstallWeb runDir];
    return [rundir stringByAppendingPathComponent:@"archive.data"];
}

- (void) reachabilityChanged:(NSNotification *)note
{
    log(@"网络切换了...");
    log(@"%d", self.fileList.count);
//    Reachability *conn = [Reachability reachabilityForInternetConnection];
//    if ([conn currentReachabilityStatus] != NotReachable && self.fileList.count >= 3) { //有好的网络环境
//        [self downloadItems];
//    }
//    if ([conn currentReachabilityStatus] != NotReachable && self.fileList.count < 3) { //不能上网了
//        logRed(@"拷贝目录");
//        if ([[NSFileManager defaultManager] copyDirAtPath:[self downloadDir] toPath:[self runDir] error:nil]) {
//            [[NSFileManager defaultManager] removeItemAtPath:[self downloadDir] error:nil];
//        }
//        NSString* path = [InstallWeb runDir];
//        path = [path stringByAppendingPathComponent:@"exchange_bank.xml"];
//        NSURL* url = [NSURL fileURLWithPath:path];
//        NSXMLParser*  parser=[[NSXMLParser alloc] initWithContentsOfURL:url];
//        parser.delegate = self;
//        [parser parse];
//        logRed(@"刷新页面");
//        [InstallWeb needToRefresh];//刷新页面
//        
//    }

//    NSLog(@"%d", [conn currentReachabilityStatus] == NotReachable);
}

- (instancetype)init {
    self = [super init];
    self.arrHttpServer = [[NSMutableArray alloc] init];
    if (self) {
        fileCount = 0;
        curFileCount = 0;
        NSArray* fileLists = [NSKeyedUnarchiver unarchiveObjectWithFile:[DownloadWeb archivePath]];
        fileCount = fileLists.count;
        self.maxLastUpdateTime = [[NSNumber alloc] initWithInt:404];
        log(@"%@, %@", [DownloadWeb archivePath], fileLists);
        if ([fileLists isKindOfClass:NSArray.class]) {
            self.fileList = [NSMutableArray arrayWithArray:fileLists];
        }
        self.tempFileList = [[NSMutableArray alloc] init];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
//        self.hostReachability = [Reachability reachabilityWithHostName:@"http://baidu.com"];
//        [self.hostReachability startNotifier];
    }
    return self;
}

- (void)checkAndUpdate {
    logRed(@"checkAndUpdate Start, fileList.count=%d", self.fileList.count);
    if (self.fileList.count > 0) {
        [self downloadItems];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadingInit" object:nil];
    } else { //没有要检查的文件，进行更新
       [self update];
    }
    logRed(@"checkAndUpdate End");
}

- (NSString *)lastUpdateTime {
    log(@"%@", g_lastUpdateTime);
    NSString *time = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdateTime"];
    if (time == nil) {
        return g_lastUpdateTime;
    }
    return time;
}

- (void)setLastUpdateTime:(NSString *)time {
    [[NSUserDefaults standardUserDefaults] setObject:time forKey:@"lastUpdateTime"];
}

- (NSString*)archivePath {
    NSString*rundir = [InstallWeb runDir];
    return [rundir stringByAppendingPathComponent:@"archive.data"];
}

- (void)saveFileList {
    if(self.fileList) {
        [NSKeyedArchiver archiveRootObject:self.fileList toFile:[self archivePath]];
    }
}

- (void)update {
    if (self.isCheckUpdate) return;
    self.isCheckUpdate = YES;
    NSString* updateFielChangeListUrl = nil;
    //这边加上更新时间lastUpdateTime, 首次为0，之后记录最后的时间戳
    if ([self.FileChangedListUrl isKindOfClass:NSString.class] && self.FileChangedListUrl.length > 0) {
        log(@"%@",[self lastUpdateTime]);
        updateFielChangeListUrl = [NSString stringWithFormat:@"%@%@",self.FileChangedListUrl, [self lastUpdateTime]];
        log(@"%@", updateFielChangeListUrl);
    } else {
        self.isCheckUpdate = NO;
        return;
    }
    if (!updateFielChangeListUrl) {
        self.isCheckUpdate = NO;
        return;
    }
    [[[AFHTTPSessionManager alloc] init] GET:updateFielChangeListUrl parameters:nil success:^(NSURLSessionDataTask* task, id responseObject) {
//        dispatch_async([AppDelegate getServerQueue], ^{
            logRed(@"update Start");
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *op = [responseObject objectForKey:@"op"];
                if ([[op objectForKey:@"code"] isEqualToString:@"Y"]) {
                    NSArray *changelist = [responseObject objectForKey:@"changelist"];
//                    changelist = [self removeAllSwfAndJsp:changelist];
                    log(@"ChangeList File Count=%d", changelist.count);
                    //刷新界面
                    if (changelist.count == 0) {
                        [InstallWeb needToRefresh];
                        return;
                    } else {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadingInit" object:nil];
                    }
                    if (!self.fileList) {
                        self.fileList = [NSMutableArray array];
                    }
                    for (NSDictionary* item in changelist) {
//                        log(@"%@", item);
                        NSMutableDictionary* fileItem = [[NSMutableDictionary alloc] initWithCapacity:4];
                        NSString *filepath = [item objectForKey:@"path"];
                        filepath = [filepath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
                        if ([filepath hasPrefix:@"/"]) {
                            filepath = [filepath substringFromIndex:1];
                        }
                        [fileItem setObject:filepath forKey:@"path"];
                        NSString *md5 = [item objectForKey:@"md5"];
                        if (31 == md5.length) {
                            md5 = [@"0" stringByAppendingString:md5];
                        }
                        [fileItem setObject:md5 forKey:@"md5"];
                        [fileItem setObject:[item objectForKey:@"status"] forKey:@"status"];
                        [fileItem setObject:[item objectForKey:@"updatetime"] forKey:@"updatetime"];
                        [fileItem setObject:[item objectForKey:@"filesize"] forKey:@"filesize"];
//                        log(@"%@", fileItem);
                        DownloadItem* downloadItem = [DownloadItem getItemWithDic:fileItem];
                        [self.fileList addObject:downloadItem];
                        [self saveFileList];
                    }
                    fileCount = self.fileList.count;
                    log(@"检查开始下载文件数: %d", self.fileList.count);
                    [self downloadItems];
                }
            }
            logRed(@"update End");
            self.isCheckUpdate = NO;
//        });
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        self.isCheckUpdate = NO;
        logRed(@"%@", error);
        [InstallWeb needToRefresh];//刷新页面
    }];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    //  log(@"%@", self.JiaoYiSuoAndBank);
    //    log(@"->%@", elementName);
    if ([elementName isEqualToString:@"http"]) {  //强制更新
        [self.arrHttpServer addObject:[attributeDict objectForKey:@"ip"]];
        [[NSUserDefaults standardUserDefaults] setObject:self.arrHttpServer forKey:@"host"];
    }
}

- (void)loadFileList
{
    NSArray* fileLists = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archivePath]];
    log(@"loadFileList = %@", [self archivePath]);
    if ([fileLists isKindOfClass:NSArray.class]) {
        self.fileList = [NSMutableArray arrayWithArray:fileLists];
    }
}

- (NSString*)downloadDir
{
    return [InstallWeb downloadDir];
}

- (NSString *)runDir
{
    return [InstallWeb runDir];
}

- (void)downloadItems {
    static int callTime = 0;
    static int continueCallTime = 0;
    static int deleteCallTime = 0;
    static int addUpateCallTime = 0;
    if (!self.fileList || 0 == self.fileList.count) {
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (DownloadItem *item in self.fileList) {
//        log(@"for call time:%d", ++callTime);
        NSString* runDir = [self runDir];
        NSString* downloadDir = [self downloadDir];
        NSString* status = item.status;
        NSString* filePath = item.path;
        NSString* localFilePath = [runDir stringByAppendingPathComponent:filePath];
        if ([status isEqualToString:@"DELETE"] || [status isEqualToString:@"delete"]) {
            deleteCallTime++;
            if ([fileManager fileExistsAtPath:localFilePath]) {
                [fileManager removeItemAtPath:localFilePath error:nil];
            }
            NSNumber*deleted = item.deleted;
            deleted = @1;
            item.deleted = deleted;
            item.downloaded = @1;
            item.failedCount = 0;
            [self addItemToTempListAndCheck:item];
            curFileCount ++;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loading" object:nil userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%.2lf", ((double)(curFileCount)/(fileCount))] forKey:@"loading"]];
            
        } else if ([status isEqualToString:@"ADD"] || [status isEqualToString:@"UPDATE"]) {
            if ([fileManager fileExistsAtPath:localFilePath]) {
                //存在于运行目录
                if (item.md5.length < 32) {
                    item.md5 = [@"00" stringByAppendingString:item.md5];
                }
                if ([[DownloadItem fileMD5:localFilePath] isEqualToString:item.md5]) {
                    continueCallTime++;
                    item.downloadSuccess = @1;
                    item.downloaded = @1;
                    item.failedCount = 0;
                    [self addItemToTempListAndCheck:item];
                    curFileCount ++;
                    continue;
                    //存在于下载目录
                } else if ([fileManager fileExistsAtPath:[downloadDir stringByAppendingPathComponent:filePath]]) {
                    continueCallTime++;
                    item.downloadSuccess = @1;
                    item.downloaded = @1;
                    item.failedCount = 0;
                    curFileCount ++;
                    [self addItemToTempListAndCheck:item];
                    continue;
                } else {
                    //go to download
                    addUpateCallTime++;
                    [self downloadItemNetPath:[self getTheDownloadPath:item]
                          withDestinationPath: [downloadDir stringByAppendingPathComponent:filePath]
                                     withItem:item];
                }
            } else {
                //goto download
                [self downloadItemNetPath:[self getTheDownloadPath:item]
                      withDestinationPath: [downloadDir stringByAppendingPathComponent:filePath]
                                 withItem:item];
                addUpateCallTime++;
            }
        }
    }
    log(@"addCallTimes = %d, continueCallTime=%d, deleteCallTime=%d", addUpateCallTime, continueCallTime, deleteCallTime);
    addUpateCallTime = 0;
    continueCallTime = 0;
    deleteCallTime = 0;
}

- (NSString*)getTheDownloadPath:(DownloadItem*)item {
    
    NSString *urlString = nil;
    if ([self.FileUpdateUrl isKindOfClass:NSString.class ] && self.FileUpdateUrl.length > 0) {
        urlString = [NSString stringWithFormat:@"%@%@", self.FileUpdateUrl, item.path];
    } else {
        return nil;
    }
    
    if (!urlString) {
        return nil;
    }
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return urlString;
}

static int sucIndex = 1;
static int failIndex = 1;
- (void)downloadItemNetPath:(NSString*)urlString withDestinationPath:(NSString*)desPath withItem:(DownloadItem*)item
{
//    log(@"downloadItemNetPath");
    [[BatchDownloadManager sharedBatchDownloadManager] downloadFile:[NSURL URLWithString:urlString] to:[NSURL fileURLWithPath:desPath]withCompletionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error) {
            if (item.md5.length < 32) {
                item.md5 = [@"00" stringByAppendingString:item.md5];
                  logYellow(@"%@,%@,%@", filePath.path,[DownloadItem fileMD5:filePath.path], item.md5);
            }
            if ([[DownloadItem fileMD5:filePath.path] isEqualToString:item.md5]) {
                log(@"download to:%d %@", sucIndex++, urlString);
                log(@"download to local: %@", filePath.path)
                item.downloadSuccess = @1;
                item.downloaded = @1;
                item.failedCount = @0;
                curFileCount ++;
                [self addItemToTempListAndCheck:item];
                
            } else {
                NSInteger failedCount = [item.failedCount integerValue];
                failedCount++;
                item.failedCount = [NSNumber numberWithInteger:failedCount];
                item.downloaded = @1;
                [self addItemToTempListAndCheck:item];
            }
        } else {
            if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
                if (((NSHTTPURLResponse*)response).statusCode != 200) {
                    log(@"fail to download %d %@", failIndex++, response.URL.absoluteString);
                }
            }
            NSInteger failedCount = [item.failedCount integerValue];
            failedCount++;
            item.failedCount = [NSNumber numberWithInteger:failedCount];
            item.downloaded = @1;
            item.failed = @1;
            [self addItemToTempListAndCheck:item];
        }
    }];
}

- (BOOL)allDownloaded {
    for (DownloadItem*item in self.tempFileList) {
        if ([item.downloaded integerValue] == 0) return NO;
    }
    return YES;
}

- (void)addItemToTempListAndCheck:(DownloadItem*)item {
    
    if ([self.maxLastUpdateTime compare:item.updateTime] == NSOrderedAscending) {
        self.maxLastUpdateTime = item.updateTime;
    }
    if (item.downloadSuccess == @1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loading" object:nil userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%.2lf", ((double)(curFileCount)/(fileCount))] forKey:@"loading"]];
    }
    [self.tempFileList addObject:item];
    
    logRed(@"%d, %d, %d, %d", self.tempFileList.count, self.fileList.count, curFileCount, fileCount);
    if (self.tempFileList.count == self.fileList.count && [self allDownloaded]) { //所有的已经下载完，但可能没下载成功的
        NSMutableArray* array = [NSMutableArray array];
        for (DownloadItem* item in self.tempFileList) {
           // log(@"%d", [item.failedCount integerValue]);
            NSInteger failCount = [item.failedCount integerValue];
            if (failCount > 0) {
                logYellow(@"%@,%@", item.path, item.updateTime);
                [array addObject:item];
            }
        }
        self.fileList = [NSMutableArray arrayWithArray:array]; //这里是没下载成功的
        [self saveFileList];
        log(@"double download check:%d", self.fileList.count);
        if (!self.fileList || self.fileList.count < 2) {  //允许至多2个下载失败
            NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmm";
            [formatter stringFromDate:[NSDate date]];
            logRed(@"%@", [formatter stringFromDate:[NSDate date]]);
            [self setLastUpdateTime:self.maxLastUpdateTime];
            
            log(@"Download all finish!");
            logRed(@"拷贝目录");
            if ([[NSFileManager defaultManager] copyDirAtPath:[self downloadDir] toPath:[self runDir] error:nil]) {
                [[NSFileManager defaultManager] removeItemAtPath:[self downloadDir] error:nil];
            }
            NSString* path = [InstallWeb runDir];
            path = [path stringByAppendingPathComponent:@"exchange_bank.xml"];
            NSURL* url = [NSURL fileURLWithPath:path];
            NSXMLParser*  parser=[[NSXMLParser alloc] initWithContentsOfURL:url];
            parser.delegate = self;
            [parser parse];
            logRed(@"刷新页面");
            [InstallWeb needToRefresh];//刷新页面
        } else {
            [self.tempFileList removeAllObjects];
            [self downloadItems];
        }
        log(@"%d", self.fileList.count);
      
       
       
    }
}

//swf jsp文件都不去下载
- (NSArray*)removeAllSwfAndJsp:(NSArray*)array {
    NSMutableArray*arrayTemp = [NSMutableArray array];
    for (int i = 0 ; i < array.count; i++) {
        NSDictionary*item = [array objectAtIndex:i];
        NSString*path = item[@"path"];
        if (path && [path rangeOfString:@"swf"].location == NSNotFound &&
            [path rangeOfString:@"jsp"].location == NSNotFound) {
            [arrayTemp addObject:item];
        }
    }
    return [NSArray arrayWithArray:arrayTemp];
}


- (void)initCheckAndUpdateWithChangeFileListUrl:(NSString*)FileChangedListUrl
                        withDownloadFileUrl:(NSString*)FileUpdateUrl {
    
    logRed(@"initCheckAndUpdateWithChangeFileListUrl Start");
    self.FileChangedListUrl  = FileChangedListUrl;
    self.FileUpdateUrl = FileUpdateUrl;
    
    [self checkAndUpdate];
    logRed(@"initCheckAndUpdateWithChangeFileListUrl End");
}


/**
 * 把下载的文件拷贝到run目录
 */
- (void)checkAndCopyFileToRunDir {
    logRed(@"checkAndCopyFileToRunDir, pthread=%d...%@ Start", pthread_self(), self.fileList);
    
    if (!self.fileList || 0 == self.fileList) {
        
    }
    
    logRed(@"checkAndCopyFileToRunDir ...%@ End", self.fileList);
}

@end


