//
//  ViewController.m
//  iOShell
//
//  Created by 疯哥 on 7/21/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import "ViewController.h"
#import "InstallWeb.h"
#import "Global.h"
#import "XGPush.h"
#import "loadingModel.h"
#import "AFHTTPSessionManager.h"
#import "WebViewController.h"
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/QQApiInterfaceObject.h>
#import "AppDelegate.h"
#import "SoundMgr.h"
#import "WXApi.h"
//#import "NewAccountViewController.h"
#import <CommonCrypto/CommonDigest.h>

@interface ViewController () <UIWebViewDelegate>
{
    NSInteger delFinishCount;
    NSInteger addFinishCount;
}

@property (strong, nonatomic) loadingModel* lm;
@property (strong, nonatomic) UILabel* numberProgress;
@property (strong, nonatomic) UIProgressView* progressView;
@property (strong, nonatomic) UIImageView* loadingBG;
@property (nonatomic, strong) NSMutableArray* arrHttpServer;
@property (nonatomic, strong) NSMutableArray* addTags;
@property (nonatomic, strong) NSMutableArray* delTags;

@end

@implementation ViewController

#define TIME 

- (void)viewDidLoad {
    [super viewDidLoad];
    log(@"viewDidLoad");
    
    self.arrHttpServer = [[NSMutableArray alloc] init];
    
    self.mainWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.mainWebView.scalesPageToFit = NO;
    self.mainWebView.scrollView.bounces = NO;
    self.mainWebView.opaque = NO;
    self.mainWebView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.mainWebView.delegate = self;
    [self.view addSubview:self.mainWebView];
   
    self.loadingBG = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wait.png"]];
    self.loadingBG.frame = self.view.frame;
    self.loadingBG.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.loadingBG];
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width-20, self.view.bounds.size.height)];
    self.progressView.center = self.view.center;
    self.progressView.progressViewStyle = UIProgressViewStyleBar;
    self.progressView.trackTintColor = [UIColor whiteColor];
    self.progressView.progressTintColor = [UIColor colorWithRed:249/255.0 green:190/255.0 blue:190/255.0 alpha:1];
    CGAffineTransform transform = CGAffineTransformMakeScale(1, 1);//改变progress高度
    self.progressView.transform = transform;
    [self.progressView setProgress:0 animated:true];
    
    self.numberProgress = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2-25, self.view.bounds.size.height/2+20, 100, 50)];
    self.numberProgress.textColor = [UIColor whiteColor];;
    self.numberProgress.font = [UIFont fontWithName:@"Arial" size:30];
    
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadingInit) name:@"loadingInit" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLoading:) name:@"loading" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWeb) name:@"refresh" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpUrl:) name:@"JumpUrl" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callback:) name:@"callback" object:nil];
    
    
    //打开用于测试单独页面，页面需打包在web.zip中
#if g_test
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:nil];
#endif
    
    
//    self.navigationController.navigationBar.hidden = NO;
//    OpenAccountViewController* open = [[OpenAccountViewController alloc] init];
//    [self.navigationController pushViewController:open animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
//    self.navigationController.navigationBar.frame = CGRectMake(0, 20, self.view.bounds.size.width, 0);
    log(@"Navframe Height=%f", self.navigationController.navigationBar.frame.size.height);
    log(@"Navframe Height=%f", self.navigationController.navigationBar.frame.origin.y);
}

- (void)viewWillAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:YES animated:YES]; //解决导航栏问题
//    self.navigationController.navigationBar.frame = CGRectMake(0, 20, self.view.bounds.size.width, 0);
    log(@"Navframe Height=%f", self.navigationController.navigationBar.frame.size.height);
    log(@"Navframe Height=%f", self.navigationController.navigationBar.frame.origin.y);
}

-(void)loadingInit {
    log(@"loadingInit...");
    self.loadingBG.image = [UIImage imageNamed:@"loading.png"];
//    [self.mainWebView addSubview:self.loadingBG];
    [self.loadingBG addSubview:self.progressView];
    [self.loadingBG addSubview:self.numberProgress];
}


+ (NSString *)urlDecodedWithString:(NSString *)string
{
    if (!string) {
        return nil;
    }
    CFStringRef decodedCFString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                          (__bridge CFStringRef) string,
                                                                                          CFSTR(""),
                                                                                          kCFStringEncodingUTF8);
    
    NSString *decodedString = [[NSString alloc] initWithString:(__bridge_transfer NSString*) decodedCFString];
    return (!decodedString) ? @"" : [decodedString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if (err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    //
    return self.mainWebView;
}

+ (NSString *) md5:(NSString *)str
{
    const char * pointer = [str UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(pointer, (CC_LONG)strlen(pointer), md5Buffer);
    
    NSMutableString *string = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [string appendFormat:@"%02x",md5Buffer[i]];
    
    return string;
}

- (void)handleSendResult:(QQApiSendResultCode)sendResult
{
    switch (sendResult)
    {
        case EQQAPIAPPNOTREGISTED:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"App未注册" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
           
            
            break;
        }
        case EQQAPIMESSAGECONTENTINVALID:
        case EQQAPIMESSAGECONTENTNULL:
        case EQQAPIMESSAGETYPEINVALID:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"发送参数错误" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
          
            
            break;
        }
        case EQQAPIQQNOTINSTALLED:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"未安装手Q" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
          
            
            break;
        }
        case EQQAPIQQNOTSUPPORTAPI:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"API接口不支持" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
          
            
            break;
        }
        case EQQAPISENDFAILD:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"发送失败" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
          
            
            break;
        }
        case EQQAPIVERSIONNEEDUPDATE:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"当前QQ版本太低，需要更新" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            break;
        }
        default:
        {
            break;
        }
    }
}

+ (NSString *)urlEncodedWithString:(NSString *)string {
    if (!string) {
        return nil;
    }
    CFStringRef encodedCFString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                          (__bridge CFStringRef) string,
                                                                          nil,
                                                                          CFSTR("?!@#$^&%*+,:;='\"`<>()[]{}/\\| "),
                                                                          kCFStringEncodingUTF8);
    NSString *encodedString = [[NSString alloc] initWithString:(__bridge_transfer NSString*) encodedCFString];
    
    if(!encodedString)
        encodedString = @"";
    
    return encodedString;
}

//调用相册及相机部分
- (void)saveImage:(UIImage *)currentImage withName:(NSString *)imageName {
    NSData *imageData = UIImageJPEGRepresentation(currentImage, 0.5);
    // 获取沙盒目录
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:imageName];
    // 将图片写入文件
    [imageData writeToFile:fullPath atomically:NO];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^{}];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];

    [self saveImage:image withName:@"camera.png"];
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"camera.png"];
    UIImage *savedImage = [[UIImage alloc] initWithContentsOfFile:fullPath];
    NSData* dataCardFront = UIImageJPEGRepresentation(savedImage, 0.1f);
    NSString* encodedImage = [dataCardFront base64Encoding];
    encodedImage = [ViewController urlEncodedWithString:encodedImage];
    NSString* callbackName = [[NSUserDefaults standardUserDefaults] objectForKey:@"takPhoto_callbackname"];
    log(@"%@", callbackName);
    NSString* callbackFun = [NSString stringWithFormat:@"%@('{\"r\":\"1\",\"path\":\"图片存储的路径\",\"con\":\"%@\"}')",callbackName, encodedImage];
//    log(@"%@", callbackFun);
    [self.mainWebView stringByEvaluatingJavaScriptFromString:callbackFun];
//    log(@"%@", encodedImage);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:^{
        log(@"取消");
    }];
}

- (void)setTag:(int)index callbackName:(NSString*)callbackName {
    if ([_addTags count] == 0) {
        return ;
    }
    [XGPush setTag:_addTags[index] successCallback:^(void) {
        NSString* callbackParam = [NSString stringWithFormat:@"'{\"type\":\"add\",\"tagName\":\"%@\"}'", _addTags[index]];
        NSString* callbackFun = [NSString stringWithFormat:@"%@(%@)", callbackName, callbackParam];
        log(@"%@", callbackFun);
        [self.mainWebView stringByEvaluatingJavaScriptFromString:callbackFun];
        logYellow(@"%@,设置成功", _addTags[index]);
        if (index+1 >= [_addTags count]) {
            return ;
        } else {
            [self setTag:index+1 callbackName:callbackName];
        }
    } errorCallback:^(void) {
        logRed(@"设置失败");
    }];
}

- (void)delTag:(int)index callbackName:(NSString*)callbackName {
    if ([_delTags count] == 0) {
        return ;
    }
    [XGPush delTag:_delTags[index] successCallback:^(void) {
        NSString* callbackParam = [NSString stringWithFormat:@"'{\"type\":\"del\",\"tagName\":\"%@\"}'", _delTags[index]];
        NSString* callbackFun = [NSString stringWithFormat:@"%@(%@)", callbackName, callbackParam];
        log(@"%@", callbackFun);
        [self.mainWebView stringByEvaluatingJavaScriptFromString:callbackFun];
        logYellow(@"%@,删除成功", _delTags[index]);
        if (index+1 >= [_delTags count]) {
            return ;
        } else {
            [self delTag:index+1 callbackName:callbackName];
        }
    } errorCallback:^(void) {
        logRed(@"删除失败");
    }];
}

- (UIImage *)thumbImageWithImage:(UIImage *)scImg limitSize:(CGSize)limitSize {
    if (scImg.size.width <= limitSize.width && scImg.size.height <= limitSize.height) {
        return scImg;
    }
    CGSize thumbSize;
    if (scImg.size.width / scImg.size.height > limitSize.width / limitSize.height) {
        thumbSize.width = limitSize.width;
        thumbSize.height = limitSize.width / scImg.size.width * scImg.size.height;
    }
    else {
        thumbSize.height = limitSize.height;
        thumbSize.width = limitSize.height / scImg.size.height * scImg.size.width;
    }
    UIGraphicsBeginImageContext(thumbSize);
    [scImg drawInRect:(CGRect){CGPointZero,thumbSize}];
    UIImage *thumbImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumbImg;
}

+(void)restart {
//    exit(0);
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.loadingBG.alpha = 0;
    self.progressView.alpha = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/**
 *  刷新Web
 */
- (void)refreshWeb {
    NSString* runDir = [InstallWeb runDir];
    NSURL* url = [NSURL fileURLWithPath:[runDir stringByAppendingPathComponent:@"index.html"]];
    if ([[self.mainWebView.request.URL absoluteString] isEqualToString:url.absoluteString]) {
        return;
    }
    [self.mainWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)refreshLoading:(id)sender {
    NSString* loading = [[sender userInfo] objectForKey:@"loading"];
    double dLoading = [loading doubleValue];
    int iLoading = dLoading*100;
    log(@"%@, %lf", loading, dLoading);
    self.numberProgress.text = [NSString stringWithFormat:@"%d%@",iLoading, @"%"];
    self.progressView.progress = dLoading;
}

- (void)jumpUrl:(id)sender {
    NSString* jumpurl = [[sender userInfo] objectForKey:@"jumpurl"];
    NSString* runDir = [InstallWeb runDir];
    jumpurl = [NSString stringWithFormat:@"%@/%@", runDir, jumpurl];
    NSURL* url = [NSURL URLWithString:jumpurl];
    if ([[self.mainWebView.request.URL absoluteString] isEqualToString:url.absoluteString]) {
        return;
    }
//    log(@"%@", url);
    [self.mainWebView loadRequest:[NSURLRequest requestWithURL:url]];
//    log(@"jumpUrl....");
}

- (void)callback:(id)sender {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* callbackName = [userDefaults stringForKey:@"alarm_callbackname"];
    NSString* callbackFun = [NSString stringWithFormat:@"%@()", callbackName];
    log(@"%@", callbackFun);
    [self.mainWebView stringByEvaluatingJavaScriptFromString:callbackFun];
}

- (void)switchDirection:(int)flag {
    if (flag == 1) {
        self.mainWebView.transform = CGAffineTransformMakeRotation(M_PI_2);
        CGRect frame = self.mainWebView.frame;
        frame = CGRectMake(0, 0, frame.size.height, frame.size.width);
        self.mainWebView.frame = frame;
        
    } else {
        self.mainWebView.transform = CGAffineTransformIdentity;
        CGRect frame = self.mainWebView.frame;
        frame = CGRectMake(0, 0, frame.size.height, frame.size.width);
        self.mainWebView.frame = frame;
    }
}

@end
