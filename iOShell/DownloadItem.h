//
//  DownloadItem.h
//  iOShell
//
//  Created by 疯哥 on 7/28/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadItem : NSObject<NSCoding>
@property(nonatomic,strong)NSString* path;
@property(nonatomic,strong)NSString* md5;
@property(nonatomic,strong)NSString* status;

@property(nonatomic,strong)NSNumber* updateTime;
@property(nonatomic,strong)NSNumber* fileSize;
@property(nonatomic, assign)NSNumber* deleted;
@property(nonatomic, assign)NSNumber* downloaded;
@property(nonatomic, assign)NSNumber* downloadSuccess;
@property(nonatomic, assign)NSNumber* failedCount;
@property(nonatomic, assign)NSNumber* failed;

+(DownloadItem*)getItemWithDic:(NSDictionary*) dic;

+ (NSString*)fileMD5:(NSString*) path;
+ (int)getFileSizeWithPath:(NSString*) path;

@end