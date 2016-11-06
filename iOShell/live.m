//
//  live.m
//  iOShell
//
//  Created by 疯哥 on 6/16/16.
//  Copyright © 2016 疯哥. All rights reserved.
//
#import "Live.h"
#import "Masonry.h"
#import <Foundation/Foundation.h>



@implementation Live

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [self itemWithTarget:self action:@selector(back) image:@"leftBarItem" highImage:nil];
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