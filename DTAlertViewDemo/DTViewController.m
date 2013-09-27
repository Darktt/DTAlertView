//
//  DTViewController.m
//  DTAlertViewDemo
//
//  Created by Darktt on 13/9/17.
//  Copyright (c) 2013 Darktt. All rights reserved.
//

#import "DTViewController.h"

#import "DTAlertView.h"

@interface DTViewController () <UIAlertViewDelegate>

@end

@implementation DTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
//    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    UIImageView *bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fish.jpg"]];
    [bgView setFrame:self.view.bounds];
    [bgView setContentMode:UIViewContentModeScaleAspectFill];
    [bgView setUserInteractionEnabled:YES];
    
    [self setView:bgView];
    [bgView release];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Show UIAlertView" forState:UIControlStateNormal];
    [button setTintColor:[UIColor blackColor]];
    [button setBackgroundColor:[UIColor whiteColor]];
    [button setFrame:CGRectMake(10, 30, 150, 37)];
    [button addTarget:self action:@selector(showUIAlertView:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button2 setTitle:@"Show DTAlertView" forState:UIControlStateNormal];
    [button2 setTintColor:[UIColor blackColor]];
    [button2 setBackgroundColor:[UIColor whiteColor]];
    [button2 setFrame:CGRectMake(CGRectGetMaxX(button.frame) + 5, 30, 150, 37)];
    [button2 addTarget:self action:@selector(showDTAlertView:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button2];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showUIAlertView:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Title 1234567890" message:@"123456789012345678901234567890123456789012345678901234567890" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    
    [alert show];
    
    [alert performSelector:@selector(setMessage:) withObject:@"" afterDelay:2];
    
    [alert release];
}

- (IBAction)showDTAlertView:(id)sender
{
    DTAlertView *alert = [DTAlertView alertViewUseBlock:nil title:@"Title 1234567890" message:@"123456789012345678901234567890123456789012345678901234567890" cancelButtonTitle:@"Cancel" positiveButtonTitle:@"OK"];
//    [alert setAlertViewMode:DTAlertViewModeProgress];
    [alert setAlertViewMode:DTAlertViewModeDuoProgress];
    
    [alert setProgressStatus:DTProgressStatusMake(1, 10)];
    
    [alert show];
    
    [self performSelector:@selector(resetAlertView:) withObject:alert afterDelay:1];
    
//    [alert setFrame:CGRectMake(0, 0, 300, 300)];
//    [alert setCenter:CGPointMake(self.view.center.x, self.view.frame.size.height + (alert.frame.size.height / 2))];
//    [alert showWithAnimationBlock:^{
//        [alert setCenter:self.view.center];
//    }];
    
    [alert performSelector:@selector(dismiss) withObject:nil afterDelay:5];
}

- (void)resetAlertView:(DTAlertView *)alert
{
//    [alert setMessage:@""];
    [alert setProgressStatus:DTProgressStatusMake(2, 10)];
    [alert setPercentage:0.8f];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"Size :%@", NSStringFromCGRect(alertView.frame));
    NSLog(@"%@", [(UILabel *)(alertView.subviews.lastObject) font]);
}

@end
