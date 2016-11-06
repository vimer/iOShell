//
//  AppDelegate.m
//  iOShell
//
//  Created by 疯哥 on 7/21/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import "AppDelegate.h"
#import "InstallWeb.h"
#import "DownloadWeb.h"
#import "Global.h"
#import "XGPush.h"
#import "XGSetting.h"
#import "SoundMgr.h"
#import "MPNotificationView.h"
#import "CMNavBarNotificationView.h"
#import <TencentOpenAPI/TencentOAuth.h>
#import "ViewController.h"
#import "MobClick.h"




#define kLCTestBundleID   @"com.lecloud.sdkTest"

@interface AppDelegate ()

@property (nonatomic, strong) InstallWeb* installWeb;

@property (nonatomic, assign) BOOL didRegisterRemoteNotificatoin;
@property NSString* jumpUrl;
@property (nonatomic, strong) UINavigationController* nav;


@end

@implementation AppDelegate
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

- (id)init{
    if(self = [super init]){
        _scene = WXSceneSession;
        TencentOAuth *_tencentOAuth = [[TencentOAuth alloc] initWithAppId:@"1104808776" andDelegate:self];;
    }
    return self;
}

-(void) changeScene:(NSInteger)scene {
    _scene = scene;
}

-(InstallWeb *)installWeb {
    if (!_installWeb) _installWeb = [[InstallWeb alloc] init];
    return _installWeb;
}

dispatch_queue_t serverThreadQueue = NULL;

+ (dispatch_queue_t)getServerQueue {
    if (!serverThreadQueue) {
        serverThreadQueue = dispatch_queue_create("Queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_context(serverThreadQueue, @"serverThread");
    }
    return serverThreadQueue;
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: kCFURLIsExcludedFromBackupKey error: &error];
    if(!success){
        log(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    } else {
        log(@"Success excluding %@ from backup", [URL lastPathComponent]);
    }
    return success;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //初始化rootViewController
    [WXApi registerApp:@"xxxxx"];
    [XGPush startApp:1234 appKey:@"xxxx"];
    [MobClick startWithAppkey:@"xxxxx" reportPolicy:BATCH  channelId:@""];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString* download = [NSString stringWithFormat:@"%@/download", basePath];
    NSString* run = [NSString stringWithFormat:@"%@/run", basePath];

    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:basePath]];
//        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:download]];
//        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:run]];
    log(@"%@, %@, %@", download, run, basePath);
    
    
    //注销之后需要再次注册前的准备
    void (^successCallback)(void) = ^(void){
        //如果变成需要注册状态
        if(![XGPush isUnRegisterStatus]) {
            //iOS8注册push方法
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= _IPHONE80_
            
            float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
            if (sysVer < 8) {
                [self registerPush];
            } else{
                [self registerPushForIOS8];
            }
#else
            //iOS8之前注册push方法
            //注册Push服务，注册后才能收到推送
            [self registerPush];
#endif
        }
    };
    [XGPush initForReregister:successCallback];
    
    //[XGPush registerPush];  //注册Push服务，注册后才能收到推送
    
    
    //推送反馈(app不在前台运行时，点击推送激活时)
//    [XGPush handleLaunching:launchOptions];
    
    //推送反馈回调版本示例
    void (^successBlock)(void) = ^(void){
        //成功之后的处理
        log(@"[XGPush]handleLaunching's successBlock");
    };
    
    void (^errorBlock)(void) = ^(void){
        //失败之后的处理
        log(@"[XGPush]handleLaunching's errorBlock");
    };
    
    //角标清0
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    //清除所有通知(包含本地通知)
    //[[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    [XGPush handleLaunching:launchOptions successCallback:successBlock errorCallback:errorBlock];
    
    //本地推送示例
    /*
     NSDate *fireDate = [[NSDate new] dateByAddingTimeInterval:10];
     
     NSMutableDictionary *dicUserInfo = [[NSMutableDictionary alloc] init];
     [dicUserInfo setValue:@"myid" forKey:@"clockID"];
     NSDictionary *userInfo = dicUserInfo;
     
     [XGPush localNotification:fireDate alertBody:@"测试本地推送" badge:2 alertAction:@"确定" userInfo:userInfo];
     */
    
#if g_test
    [self.installWeb preInstall];     //打开用于测试单独页面，页面需打包在web.zip中
#else
    [self.installWeb downloadConfig:^(NSError *error) {
        log(@"first failure！！！");
        [self.installWeb downloadConfig:^(NSError *error) {
            log(@"second failure！！！");
            [self.installWeb downloadConfig:^(NSError *error) {
                log(@"third failure！！！");
                [self showAlertView];
            }];
        }];
    }];
#endif
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.nav = [[UINavigationController alloc] initWithRootViewController:[[ViewController alloc] init]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor redColor]];
    self.nav.navigationBar.tintColor = [UIColor whiteColor];
    NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName,nil];
    [self.nav.navigationBar setTitleTextAttributes:attributes];
    
    
    self.window.rootViewController = self.nav;
    
    //更改状态栏颜色
    UIView *view=[[UIView alloc] initWithFrame:CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width, 20)];
    view.backgroundColor=[UIColor redColor];
    [self.window.rootViewController.view addSubview:view];
    _headView=view;
    [self.window makeKeyAndVisible];
    
    
    // Override point for customization after application launch.
    
    /*
     *******************************************************************
     *******************************************************************
     SDK-Demo使用前注意:
     */
    /*
     1.BundleID设置提醒
     */
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:kLCTestBundleID])
    {
        NSLog(@"请先设置您的BunldeID");
    }

    NSAssert(![bundleID isEqualToString:kLCTestBundleID], @"请先设置您的BunldeID");
    
    /*
     2.请在LCBaseViewController.h中设置直播、点播、活动播放的ID等相关属性参数
     *******************************************************************
     *******************************************************************
     */
    
    //注册崩溃处理
    NSSetUncaughtExceptionHandler (&CaughtExceptionHandler);
    
    /*
     确保App启动的屏幕方向
     */
    [[UIApplication sharedApplication] setStatusBarOrientation:(UIInterfaceOrientationPortrait) animated:NO];
    
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    RootViewController *mainViewController = [[RootViewController alloc] initWithNibName:@"RootViewController"
//                                                                                  bundle:nil];
//    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
//    navigationController.navigationBarHidden = YES;
//    self.navigationController = navigationController;
//    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];

    
    
    return YES;
}


#pragma mark crash catch

void CaughtExceptionHandler(NSException *exception) {
    
    //应用版本
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSString *version = [mainBundle objectForInfoDictionaryKey:@"internalVersion"];
    
    if(nil == version) {
        
        version = @"";
        
    }
    //设备版本
    //    NSString *deviceModel = [UIDevice currentDevice].platform;
    NSString *deviceModel = @"iPhone";
    //系统版本
    NSString *sysVersion = [UIDevice currentDevice].systemVersion;
    //邮件主题
    NSString *subject = [NSString stringWithFormat:@"[Crash][iOS_SDK4.0][%@][%@][%@]", version, sysVersion, deviceModel];
    
    //邮箱
    NSString *mailAddress = @"houdi@letv.com";
    
    
    
    //调用栈
    NSArray *stackSysbolsArray = [exception callStackSymbols];
    
    //崩溃原因
    NSString *reason = [exception reason];
    
    //崩溃原因
    NSString *name = [exception name];
    
    //邮件正文
    NSString *body = [NSString stringWithFormat:@"<br>----------------------------------------------------<br>当你看到这个页面的时候别慌,简单的描述下刚才的操作,然后邮件我<br><br>----------------------------------------------------<br>崩溃标识:<br><br>%@<br>----------------------------------------------------<br>崩溃原因:<br><br>%@<br>----------------------------------------------------<br>崩溃详情:<br><br>%@<br>",
                      
                      name,
                      
                      reason,
                      
                      [stackSysbolsArray componentsJoinedByString:@"<br>"]];
    
    
    //邮件url
    NSString *urlStr = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@",
                        
                        mailAddress,subject,body];
    
    
    
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    [[UIApplication sharedApplication] openURL:url];
}


- (void)showAlertView {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"您的网络好像有问题." delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    [alertView show];
}

- (void)registerPushForIOS8{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= _IPHONE80_
    
    //Types
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    //Actions
    UIMutableUserNotificationAction *acceptAction = [[UIMutableUserNotificationAction alloc] init];
    acceptAction.identifier = @"ACCEPT_IDENTIFIER";
    acceptAction.title = @"Accept";
    
    acceptAction.activationMode = UIUserNotificationActivationModeForeground;
    acceptAction.destructive = NO;
    acceptAction.authenticationRequired = NO;
    
    //Categories
    UIMutableUserNotificationCategory *inviteCategory = [[UIMutableUserNotificationCategory alloc] init];
    inviteCategory.identifier = @"INVITE_CATEGORY";
    [inviteCategory setActions:@[acceptAction] forContext:UIUserNotificationActionContextDefault];
    [inviteCategory setActions:@[acceptAction] forContext:UIUserNotificationActionContextMinimal];
    NSSet *categories = [NSSet setWithObjects:inviteCategory, nil];
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
}

- (void)registerPush{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    //notification是发送推送时传入的字典信息
    [XGPush localNotificationAtFrontEnd:notification userInfoKey:@"clockID" userInfoValue:@"myid"];
    
    //删除推送列表中的这一条
    [XGPush delLocalNotification:notification];
    //[XGPush delLocalNotification:@"clockID" userInfoValue:@"myid"];
    
    //清空推送列表
    //[XGPush clearLocalNotifications];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= _IPHONE80_

//注册UserNotification成功的回调
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
    //用户已经允许接收以下类型的推送
    //UIUserNotificationType allowedTypes = [notificationSettings types];
    
}

//按钮点击事件回调
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler{
    if([identifier isEqualToString:@"ACCEPT_IDENTIFIER"]){
        log(@"ACCEPT_IDENTIFIER is clicked");
    }
    
    completionHandler();
}

#endif


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    //NSString * deviceTokenStr = [XGPush registerDevice:deviceToken];
   
    void (^successBlock)(void) = ^(void){
        //成功之后的处理
        log(@"[XGPush]register successBlock");
    };
    
    void (^errorBlock)(void) = ^(void){
        //失败之后的处理
        log(@"[XGPush]register errorBlock");
    };
    
    //注册设备
    [[XGSetting getInstance] setChannel:@"appstore"];
    [[XGSetting getInstance] setGameServer:@"巨神峰"];
    
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"deviceToken"];
    NSString * deviceTokenStr = [XGPush registerDevice:deviceToken successCallback:successBlock errorCallback:errorBlock];

    //如果不需要回调
//    [XGPush registerDevice:deviceToken];
    
    self.didRegisterRemoteNotificatoin = YES;
    
    //打印获取的deviceToken的字符串
    log(@"deviceTokenStr is %@",deviceTokenStr);
}

//如果deviceToken获取不到会进入此事件
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    self.didRegisterRemoteNotificatoin = YES;
    NSString *str = [NSString stringWithFormat: @"Error: %@",err];
    log(@"%@",str);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    
//    log(@"pushed msg:%@", userInfo);
    if ([userInfo isKindOfClass:NSDictionary.class]) {
        log(@"%@", userInfo);
        NSDictionary* aps = userInfo[@"aps"];
        NSString* title = [aps objectForKey:@"alert"];
        NSString* pushType = userInfo[@"pushtype"];
        _jumpUrl = userInfo[@"jumpurl"];
//        [SoundMgr playDefaulSound];
        log(@" %@, %@, %@, %@", aps, pushType, _jumpUrl, title);
        if ([pushType isEqualToString:@"redirecthtml"] || [pushType isEqualToString:@"alarm"] ) {
            
//            log(@"%@, %@", [UIApplication sharedApplication].applicationState, UIApplicationStateActive)
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"JumpUrl" object:nil  userInfo:[NSDictionary dictionaryWithObject:_jumpUrl forKey:@"jumpurl"]];
                } else {
                    UIImage* img = [UIImage imageNamed:@"icon.png"];
//                    [CMNavBarNotificationView notifyWithText:@"温馨提示"
//                                                      detail:title
//                                                       image:img
//                                                    duration:4.0f
//                                               andTouchBlock:^(MPNotificationView *notificationView) {
//                                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"JumpUrl" object:nil  userInfo:[NSDictionary dictionaryWithObject:_jumpUrl forKey:@"jumpurl"]];
//                                               }];
                    
                    [MPNotificationView notifyWithText:@"温馨提示"
                                                detail:title
                                                 image:img
                                              duration:4.0f andTouchBlock:^(MPNotificationView *notificationView) {
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"JumpUrl" object:nil  userInfo:[NSDictionary dictionaryWithObject:_jumpUrl forKey:@"jumpurl"]];
                                              }];
                    
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"公告"
//                                                                    message:@"message"
//                                                                   delegate:self
//                                                          cancelButtonTitle:@"取消"
//                                                          otherButtonTitles:@"查看",nil];
//                    alert.title = @"温馨提示";
//                    alert.message = title;
//                    [alert show];
                    
                }
            });
            // 再进行调用回调函数
            if ([pushType isEqualToString:@"alarm"]) {
                  [[NSNotificationCenter defaultCenter] postNotificationName:@"callback" object:nil userInfo:[NSDictionary dictionaryWithObject:@"" forKey:@"callback"]];
            }
        } else if ([pushType isEqualToString:@"exitapp"]) {
            exit(0);
        }
        
        if ([aps isKindOfClass:NSDictionary.class]) {
#ifdef DEBUG_SWITCH
            NSString*alert = aps[@"alert"];
            if ([alert isKindOfClass:NSString.class] && alert.length > 0) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"测试用，以后关闭" message:alert
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"确定", nil];
                [alertView show];
            }
#endif
        }
    }
    [XGPush handleReceiveNotification:userInfo];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
//    if (self.window.rootViewController  == )
//    if (self.window.rootViewController == self.nav) {
//        log(@"rootView..");
//        self.nav.navigationBar.frame = CGRectMake(0, 20, [[UIScreen mainScreen] bounds].origin.x, 0); 
//    }
    log(@"Navframe Height=%f", self.nav.navigationBar.frame.size.height);
    log(@"Navframe Height=%f", self.nav.navigationBar.frame.origin.y);
    NSLog(@"applicationDidBecomeActive");
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    if (self.didRegisterRemoteNotificatoin) {
        return;
    }
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    log(@"%@", [url scheme]);
    return [WXApi handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    log(@"%@", [url scheme]);
    return [WXApi handleOpenURL:url delegate:self];
}

-(void) onReq:(BaseReq*)req
{
    if([req isKindOfClass:[GetMessageFromWXReq class]])
    {
        // 微信请求App提供内容， 需要app提供内容后使用sendRsp返回
        NSString *strTitle = [NSString stringWithFormat:@"微信请求App提供内容"];
        NSString *strMsg = @"微信请求App提供内容，App要调用sendResp:GetMessageFromWXResp返回给微信";
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alert.tag = 1000;
        [alert show];
    }
    else if([req isKindOfClass:[ShowMessageFromWXReq class]])
    {
        ShowMessageFromWXReq* temp = (ShowMessageFromWXReq*)req;
        WXMediaMessage *msg = temp.message;
        
        //显示微信传过来的内容
        WXAppExtendObject *obj = msg.mediaObject;
        
        NSString *strTitle = [NSString stringWithFormat:@"微信请求App显示内容"];
        NSString *strMsg = [NSString stringWithFormat:@"标题：%@ \n内容：%@ \n附带信息：%@ \n缩略图:%u bytes\n\n", msg.title, msg.description, obj.extInfo, msg.thumbData.length];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    else if([req isKindOfClass:[LaunchFromWXReq class]])
    {
        //从微信启动App
        NSString *strTitle = [NSString stringWithFormat:@"从微信启动"];
        NSString *strMsg = @"这是从微信启动的消息";
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(void) onResp:(BaseResp*)resp
{
//    if([resp isKindOfClass:[SendMessageToWXResp class]])
//    {
//        NSString *strTitle = [NSString stringWithFormat:@"发送媒体消息结果"];
//        NSString *strMsg = [NSString stringWithFormat:@"errcode:%d", resp.errCode];
//        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//        [alert show];
//    }
}

@end
