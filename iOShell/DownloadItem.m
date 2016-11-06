//
//  DownloadItem.m
//  iOShell
//
//  Created by 疯哥 on 7/28/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import "DownloadItem.h"
#import <CommonCrypto/CommonDigest.h>

CFStringRef FileMD5HashCreateWithPath2(CFStringRef filePath,
                                      size_t chunkSizeForReadingData);

@implementation DownloadItem

- (instancetype)initWithDataDic:(NSDictionary*)dic
{
    if (self = [super init])
    {
        self.path = [self getStrValue:@"path" withData:dic];
        self.md5 = [self getStrValue:@"md5" withData:dic];
        self.status = [self getStrValue:@"status" withData:dic];
        
        self.updateTime = [self getNumValue:@"updatetime" withData:dic];
        self.fileSize = [self getNumValue:@"filesize" withData:dic];
        self.deleted = @0;
        self.downloaded = @0;
        self.downloadSuccess = @0;
        self.failedCount = @0;
        self.failed = @0;
    }
    return self;
}

+(DownloadItem*)getItemWithDic:(NSDictionary*)dic
{
    return [[self alloc] initWithDataDic:dic];
}

- (NSString*)getStrValue:(NSString*)key withData:(NSDictionary*)dic
{
    id value = dic[key];
    if ([value isKindOfClass:NSString.class]) {
        NSString*val = value;
        if (val.length > 0) {
            return val;
        }
        return @"";
    }
    return @"";
}

- (NSNumber*)getNumValue:(NSString*)key withData:(NSDictionary*)dic
{
    id value = dic[key];
    if ([value isKindOfClass:NSNumber.class]) {
        NSNumber*val = value;
        if ([val integerValue] > 0) return val;
    }
    return @0;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.path = [aDecoder decodeObjectForKey:@"path"];
        self.md5 = [aDecoder decodeObjectForKey:@"md5"];
        self.status = [aDecoder decodeObjectForKey:@"status"];
        self.updateTime = [aDecoder decodeObjectForKey:@"updateTime"];
        self.fileSize = [aDecoder decodeObjectForKey:@"fileSize"];
        self.deleted = [aDecoder decodeObjectForKey:@"deleted"];
        self.downloaded = [aDecoder decodeObjectForKey:@"downloaded"];
        self.downloadSuccess = [aDecoder decodeObjectForKey:@"downloadSuccess"];
        self.failedCount = [aDecoder decodeObjectForKey:@"failedCount"];
        self.failedCount = [aDecoder decodeObjectForKey:@"failed"];
    }
    return self;
}

- (void)dealloc
{}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.path forKey:@"path"];
    [aCoder encodeObject:self.md5 forKey:@"md5"];
    [aCoder encodeObject:self.status forKey:@"status"];
    [aCoder encodeObject:self.updateTime forKey:@"updateTime"];
    [aCoder encodeObject:self.fileSize forKey:@"fileSize"];
    [aCoder encodeObject:self.deleted forKey:@"deleted"];
    [aCoder encodeObject:self.downloaded forKey:@"downloaded"];
    [aCoder encodeObject:self.downloadSuccess forKey:@"downloadSuccess"];
    [aCoder encodeObject:self.failedCount forKey:@"failedCount"];
    [aCoder encodeObject:self.failedCount forKey:@"failed"];
}

+ (int)getFileSizeWithPath:(NSString*)path
{
    NSFileManager*fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:path])return NO;
    
    NSError*error = nil;
    NSDictionary* dictFile = [fileManager attributesOfItemAtPath:path error:&error];
    if (error) {
        return NO;
    }
    unsigned long long fileSize = [dictFile fileSize];
    if ((1024*1024)>(fileSize)&&(fileSize)>1024) {
        return (int)(fileSize/1024);
    }
    return 0;
}

+ (NSString*)fileMD5:(NSString*)path
{
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath2((__bridge CFStringRef)path, 32);
}

CFStringRef FileMD5HashCreateWithPath2(CFStringRef filePath,
                                      size_t chunkSizeForReadingData) {
    
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,
                                       (const char *)hash,
                                       kCFStringEncodingUTF8);
done:
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

@end