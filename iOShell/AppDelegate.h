//
//  AppDelegate.h
//  iOShell
//
//  Created by 疯哥 on 7/21/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WXApi.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    enum WXScene _scene;
}

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) UIView *headView;

+ (dispatch_queue_t)getServerQueue;

@end

