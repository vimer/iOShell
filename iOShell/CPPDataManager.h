//
//  DownloadItem.m
//  iOShell
//
//  Created by 疯哥 on 7/28/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CPPDataManager : NSObject
+(CPPDataManager*)sharedCPPDataManager;

- (CLLocationCoordinate2D)getLocation;
- (NSString*)getDeviceId;
- (int)isFileExist:(NSString*)filePath;
- (NSString*)readFileWithPath:(NSString*)filePath;
- (int)writeFileWithPath:(NSString*)filePath withContent:(NSString*)content;
- (int)createFileWithPath:(NSString*)filePath;
- (int)removeFile:(NSString*)filePath;
- (void)switchDirection:(int)flag;

- (BOOL)isTheFileExistLocal:(NSString*)fileName;
- (NSString*)getTheFileExistLocal:(NSString*)fileName;
- (NSArray*)getAllSubPathsInServerBase;

@end
