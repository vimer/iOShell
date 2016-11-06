//
//  NSFileManager+Directory.h
//  DHQQ
//
//  Created by jianping on 14/10/23.
//  Copyright (c) 2014年 hujp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Directory)
- (BOOL)copyDirAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error;
@end
