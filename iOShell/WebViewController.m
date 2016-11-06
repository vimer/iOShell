//
//  WebViewController.m
//  iOShell
//
//  Created by 疯哥 on 6/17/16.
//  Copyright © 2016 疯哥. All rights reserved.
//

#import "WebViewController.h"
#import "Masonry.h"
#import "Global.h"
#import <Foundation/Foundation.h>

@interface WebViewController () <UIWebViewDelegate>

@property (strong, nonatomic) UIWebView* webView;
@property (strong, nonatomic) UIAlertView* myAlert;

@end

@implementation WebViewController

- (void)viewDidLoad { 
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [self itemWithTarget:self action:@selector(back) image:@"leftBarItem" highImage:nil];
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.webView.scalesPageToFit = NO;
    self.webView.scrollView.bounces = NO;
    self.webView.opaque = NO;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.webView.delegate = self;
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* webLink = [userDefaults stringForKey:@"web_link"];
    log(@"%@", webLink);
    NSURL* url = [[NSURL alloc]initWithString:webLink];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    [self.view addSubview:self.webView];
}
- (void)webViewDidStartLoad:(UIWebView *)webView{
    if (self.myAlert==nil){
        self.myAlert = [[UIAlertView alloc] initWithTitle:nil
                                             message: @"页面正在努力加载中，请稍等..."
                                            delegate: self
                                   cancelButtonTitle: nil
                                   otherButtonTitles: nil];
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityView.frame = CGRectMake(120.f, 48.0f, 38.0f, 38.0f);
        [self.myAlert addSubview:activityView];
        [activityView startAnimating];
        [self.myAlert show];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [self.myAlert dismissWithClickedButtonIndex:0 animated:YES];
}

-(void)back {
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (UIBarButtonItem *)itemWithTarget:(id)target action:(SEL)action image:(NSString *)image highImage:(NSString *)highImage
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    //设置图片
    [btn setBackgroundImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:highImage] forState:UIControlStateHighlighted];
    //设置尺寸
    //btn.frame.size = btn.currentBackgroundImage.size;
    
    CGSize btnSize = btn.currentBackgroundImage.size;
    btn.frame = CGRectMake(btn.frame.origin.x, btn.frame.origin.y, btnSize.width, btnSize.height);
    return [[UIBarButtonItem alloc] initWithCustomView:btn];
}
- (void)viewWillAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:NO animated:YES]; //解决导航栏问题
    //    self.navigationController.navigationBar.frame = CGRectMake(0, 44, self.view.bounds.size.width, 20);
    //    log(@"Navframe Height=%f", self.navigationController.navigationBar.frame.size.height);
    //    log(@"Navframe Height=%f", self.navigationController.navigationBar.frame.origin.y);
}

@end
