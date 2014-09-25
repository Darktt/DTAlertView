//
//  DTTestViewController.m
//  DTAlertViewDemo
//
//  Created by EdenLi on 2014/9/24.
//  Copyright (c) 2014年 Darktt. All rights reserved.
//

#import "DTTestViewController.h"

@interface DTTestViewController ()

@property (retain, nonatomic) UIPresentationController *presentationController;

@end

@implementation DTTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    CGFloat reduceWidth = (CGRectGetWidth(screenRect) - 200.0f ) / 2.0f;
    CGFloat reduceHeight = (CGRectGetHeight(screenRect) - 200.0f ) / 2.0f;
    CGRect viewRect = CGRectInset(screenRect, reduceWidth, reduceHeight);
    
    [self.view setFrame:viewRect];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.presentationController = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    // Block
}

@end
