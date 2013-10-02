//
//  DTViewController.m
//  DTAlertViewDemo
//
//  Created by Darktt on 13/9/17.
//  Copyright (c) 2013 Darktt. All rights reserved.
//

#import "DTViewController.h"

#import "DTAlertView.h"

@interface DTViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
{
    NSArray *demoArray;
    DTAlertView *progressAlertView;
}

@end

@implementation DTViewController

+ (instancetype)viewComtroller
{
    DTViewController *viewController = [[[DTViewController alloc] init] autorelease];
    
    return viewController;
}

- (instancetype)init
{
    self = [super init];
    if (self == nil) return nil;
    
    [self setTitle:@"DTAlertView Demo"];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UIImage *bgImage = [UIImage imageNamed:@"rainbow.jpg"];
    
    UIImageView *bgView = [[UIImageView alloc] initWithImage:bgImage];
    [bgView setFrame:self.view.bounds];
    [bgView setContentMode:UIViewContentModeScaleToFill];
    [bgView setUserInteractionEnabled:YES];
    
    [self setView:bgView];
    [bgView release];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [tableView setDataSource:self];
    [tableView setDelegate:self];
    [tableView setBackgroundColor:[UIColor clearColor]];
    
    [self.view addSubview:tableView];
    [tableView release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    demoArray = [[NSArray alloc] initWithArray:@[@"Normal alert view", @"Alert view with text field", @"Alert view with secure text field", @"Alert view with progress view", @"Alert view with duo progress view"]];
}

- (void)dealloc
{
    [demoArray release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView DataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return demoArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    }
    
    [cell setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:0.2f]];
    
    [cell.textLabel setText:demoArray[indexPath.row]];
    [cell.textLabel setFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark UITableView Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DTAlertView *alertView = nil;
    
    switch (indexPath.row) {
        case 0:
            alertView = [DTAlertView alertViewWithTitle:@"Demo" message:@"This is normal alert view." delegate:nil cancelButtonTitle:@"Cancel" positiveButtonTitle:@"OK"];
            [alertView show];
            break;
            
        case 1:
            alertView = [DTAlertView alertViewWithTitle:@"Demo" message:@"This is alert view\nwith text field." delegate:nil cancelButtonTitle:@"Cancel" positiveButtonTitle:@"OK"];
            [alertView setAlertViewMode:DTAlertViewModeTextInput];
            [alertView show];
            break;
            
        case 2:
            alertView = [DTAlertView alertViewWithTitle:@"Demo" message:@"This is alert view\nwith secure text field." delegate:nil cancelButtonTitle:@"Cancel" positiveButtonTitle:@"OK"];
            [alertView setAlertViewMode:DTAlertViewModeTextInput];
            [alertView setPositiveButtonEnable:NO];
            [alertView setTextFieldDidChangeBlock:^(DTAlertView *_alertView, NSString *text) {
                [_alertView setPositiveButtonEnable:(text.length >= 10)];
            }];
            
            [alertView show];
            
            [alertView.textField setSecureTextEntry:YES];
            break;
            
        case 3:
        {
            DTAlertViewButtonClickedBlock block = ^(DTAlertView *_alertView, NSUInteger buttonIndex, NSUInteger cancelButtonIndex){
                if (buttonIndex == cancelButtonIndex) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:self];
                }
            };
            
            progressAlertView = [DTAlertView alertViewUseBlock:block title:@"Demo" message:@"This is alert view\nwith progress view." cancelButtonTitle:@"Cancel" positiveButtonTitle:nil];
            [progressAlertView setAlertViewMode:DTAlertViewModeProgress];
            [progressAlertView setPercentage:0];
            [progressAlertView show];
            
            [self performSelector:@selector(changePercentage:) withObject:@(0.1f) afterDelay:1.0f];
        }
            break;
            
        case 4:
        {
            DTAlertViewButtonClickedBlock block = ^(DTAlertView *alertView, NSUInteger buttonIndex, NSUInteger cancelButtonIndex){
                if (buttonIndex == cancelButtonIndex) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:self];
                }
            };
            
            progressAlertView = [DTAlertView alertViewUseBlock:block title:@"Demo" message:@"This is alert view\nwith duo progress view." cancelButtonTitle:@"Cancel" positiveButtonTitle:nil];
            [progressAlertView setAlertViewMode:DTAlertViewModeDuoProgress];
            [progressAlertView setProgressStatus:DTProgressStatusMake(0, 20)];
            
            [progressAlertView show];
            
            [self performSelector:@selector(changePercentage:) withObject:@(0.1f) afterDelay:1.0f];
            [self performSelector:@selector(changeProgressStatus) withObject:nil afterDelay:10.0f];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark -

- (void)changePercentage:(NSNumber *)percentage
{
    CGFloat _percentage = [percentage floatValue];
    
    [progressAlertView setPercentage:_percentage];
    
    if (_percentage < 1.0f) {
        [self performSelector:@selector(changePercentage:) withObject:@(_percentage + 0.1f) afterDelay:1.0f];
    } else {
        [progressAlertView dismiss];
    }
}

- (void)changeProgressStatus
{
    [progressAlertView setProgressStatus:DTProgressStatusMake(1, 20)];
    [progressAlertView setPercentage:0.0f];
}

@end
