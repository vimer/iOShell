//
//  DownloadItem.m
//  iOShell
//
//  Created by 疯哥 on 7/28/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import "SoundMgr.h"
#import "AppDelegate.h"
#import "InstallWeb.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SoundMgr ()
@property (nonatomic, strong) NSMutableDictionary *sounds;
@end

@implementation SoundMgr
- (void)playSound:(NSString *)name
{
    if (name.length == 0) return ;
    NSNumber *soundId = [self.sounds objectForKey:name];
    if (soundId == nil) {
        soundId = [self createSysSoundForName:name];
        if (soundId != nil) {
            [self.sounds setObject:soundId forKey:name];
        }
    }
    if (soundId != nil) {
        SystemSoundID sid = (SystemSoundID)[soundId unsignedIntegerValue];
            AudioServicesPlaySystemSound(sid);
        }
//    NSError* err;
//    NSString* path = [[NSBundle mainBundle] pathForResource:@"zhang" ofType:@"m4a"];
//    AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithData:[NSData dataWithContentsOfFile:path] error:&err];
//    NSLog(@"%@", path);
//    player.delegate = self;
//    player.numberOfLoops = 5;
//    player.volume = 0.8;
//    [player prepareToPlay];
//    [player play];
//    if (player.playing==YES){
//        NSLog(@"Playing");
//    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag{
    NSLog(@"....");
}

- (NSNumber *)createSysSoundForName:(NSString *)name {
    NSString *runDir = [InstallWeb runDir];
    runDir = [runDir stringByAppendingString:@"/sounds/"];
    NSString *filePath = [runDir stringByAppendingPathComponent:name];
    
    SystemSoundID sid = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSURL *fileUrl  = [NSURL fileURLWithPath:filePath];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileUrl, &sid);
    }
    if (sid != 0) {
        return [NSNumber numberWithUnsignedInteger:sid];
    } else {
        return nil;
    }
}

+ (void)playDefaulSound
{
    SystemSoundID sid = 0;
    NSURL *fileUrl  = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"helloworld" ofType:@"wav"]];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileUrl, &sid);
    AudioServicesPlaySystemSound(sid);
}
@end
