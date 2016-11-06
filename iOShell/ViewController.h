//
//  ViewController.h
//  iOShell
//
//  Created by 疯哥 on 7/21/15.
//  Copyright (c) 2015 疯哥. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UIGestureRecognizerDelegate,UIImagePickerControllerDelegate>

@property (strong, nonatomic) UIWebView* mainWebView;
@property (strong, nonatomic) UILabel* loadLabel;
@property (strong, nonatomic) NSString* loading;

- (void)switchDirection:(int)flag;

@end

