//
//  DTViewController.m
//  DTAlertViewDemo
//
//  Created by Darktt on 13/9/17.
//  Copyright (c) 2013 Darktt. All rights reserved.
//

#import "DTViewController.h"

#import "DTAlertView.h"

@interface DTViewController () <UITableViewDataSource, UITableViewDelegate, DTAlertViewDelegate>
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
    [tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    NSString *version = [[UIDevice currentDevice] systemVersion];
    
    if ([version compare:@"7.00" options:NSNumericSearch] != NSOrderedAscending) {
        [tableView setBackgroundColor:[UIColor clearColor]];
    } else {
        [tableView setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:0.2f]];
    }
    
    [self.view addSubview:tableView];
    [tableView release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    demoArray = [[NSArray alloc] initWithArray:@[@"Normal alert view (Default)", @"Normal alert view (Slide UP)", @"Normal alert view (Slide Down)", @"Normal alert view (Slide Left)", @"Normal alert view (Slide Right)", @"Use with Block", @"With text field", @"With secure text field", @"With progress view", @"With duo progress view"]];
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
    return [demoArray count];
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
    [cell.textLabel setTextColor:[UIColor blackColor]];
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
        {
            NSString *thinkDifferent = @"Here's to the crazy ones.\nThe misfits.\nThe rebels.\nThe troublemakers.\nThe round pegs in the square holes.\nThe ones who see things differently.\nThey're not fond of rules\nAnd they have no respect for the status quo.\nYou can praise them, quote them, disagree with them\ndisbelieve them, glorify or vilify them.\nAbout the only thing that you can't do is ignore them.\nBecause they change things.\nThey invent.     They imagine.     They heal.\nThey explore.   They create.        They inspire.\nThey push the human race forward.\nMaybe they have to be crazy.\nHow else can you stare at an empty canvas and see a work of art?\nOr sit in silence and hear a song that's never been written?\nOr gaze at a red planet and see a laboratory on wheels?\nWe make tools for these kinds of people.\nWhile some may see them as the crazy ones, we see genius.\nBecause the people who are crazy enough to think that they can\nchange the world, are the ones who do.";
            
            alertView = [DTAlertView alertViewWithTitle:@"Think Different" message:thinkDifferent delegate:self cancelButtonTitle:@"Cancel" positiveButtonTitle:@[@"OK_1",@"OK_2",@"OK_3"]];
            [alertView show];
            
            [self performSelector:@selector(showOtherAlertView) withObject:nil afterDelay:2];
        }
            break;
            
        case 1:
            alertView = [DTAlertView alertViewWithTitle:@"Demo" message:@"I'm alert view." delegate:self cancelButtonTitle:nil positiveButtonTitle:@[@"OK",@"OK_@",@"OK_2"]];
            [alertView setDismissAnimationWhenButtonClicked:DTAlertViewAnimationSlideTop];
            [alertView showWithAnimation:DTAlertViewAnimationSlideTop];
            break;
            
        case 2:
            alertView = [DTAlertView alertViewWithTitle:@"Demo" message:@"I'm alert view." delegate:self cancelButtonTitle:@"Cancel" positiveButtonTitle:@[@"OK"]];
            [alertView setDismissAnimationWhenButtonClicked:DTAlertViewAnimationSlideBottom];
            [alertView showWithAnimation:DTAlertViewAnimationSlideBottom];
            break;
            
        case 3:
            alertView = [DTAlertView alertViewWithTitle:@"Demo" message:@"I'm alert view." delegate:self cancelButtonTitle:@"Cancel" positiveButtonTitle:nil];
            [alertView setDismissAnimationWhenButtonClicked:DTAlertViewAnimationSlideLeft];
            [alertView showWithAnimation:DTAlertViewAnimationSlideLeft];
            break;
            
        case 4:
            alertView = [DTAlertView alertViewWithTitle:@"Demo" message:@"I'm alert view." delegate:self cancelButtonTitle:nil positiveButtonTitle:@[@"Cancel",@"OK"]];
            [alertView setDismissAnimationWhenButtonClicked:DTAlertViewAnimationSlideRight];
            [alertView showWithAnimation:DTAlertViewAnimationSlideRight];
            break;
            
        case 5:
        {
            DTAlertViewButtonClickedBlock block = ^(DTAlertView *alertView, NSUInteger buttonIndex, NSUInteger cancelButtonIndex){
                NSLog(@"You click button title : %@", alertView.clickedButtonTitle);
                
                if (buttonIndex == cancelButtonIndex) {
                    [alertView setDismissAnimationWhenButtonClicked:DTAlertViewAnimationSlideLeft];
                    
                    return;
                }
                
                [alertView setDismissAnimationWhenButtonClicked:DTAlertViewAnimationSlideRight];
            };
            
            alertView = [DTAlertView alertViewUseBlock:block title:@"Demo" message:@"I'm using block alert view." cancelButtonTitle:@"Cancel" positiveButtonTitle:@[@"OK"]];
            [alertView show];
        }
            break;
            
        case 6:
            alertView = [DTAlertView alertViewWithTitle:@"Demo" message:@"Input some word" delegate:nil cancelButtonTitle:@"Cancel" positiveButtonTitle:@[@"OK"]];
            [alertView setAlertViewMode:DTAlertViewModeTextInput];
            [alertView show];
            break;
            
        case 7:
        {
            alertView = [DTAlertView alertViewWithTitle:@"Please Input Password!!" message:@"Password is \"1234567890\"" delegate:self cancelButtonTitle:@"Cancel" positiveButtonTitle:@[@"OK"]];
            [alertView setAlertViewMode:DTAlertViewModeTextInput];
            [alertView setPositiveButtonEnable:NO];
            
            [alertView setTextFieldDidChangeBlock:^(DTAlertView *_alertView, NSString *text) {
                [_alertView setPositiveButtonEnable:(text.length >= 10)];
            }];
            
            [alertView showForPasswordInputWithAnimation:DTAlertViewAnimationDefault];
            
            // Set text field to secure text mode after show.
            [alertView.textField setSecureTextEntry:YES];
        }
            break;
            
        case 8:
        {
            DTAlertViewButtonClickedBlock block = ^(DTAlertView *_alertView, NSUInteger buttonIndex, NSUInteger cancelButtonIndex){
                if (buttonIndex == cancelButtonIndex) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:self];
                }
            };
            
            progressAlertView = [DTAlertView alertViewUseBlock:block title:@"Loading..." message:@"Prepareing..." cancelButtonTitle:@"Cancel" positiveButtonTitle:nil];
            [progressAlertView show];
            
            [self performSelector:@selector(changePercentage:) withObject:@(0.0f) afterDelay:1.0f];
        }
            break;
            
        case 9:
        {
            DTAlertViewButtonClickedBlock block = ^(DTAlertView *alertView, NSUInteger buttonIndex, NSUInteger cancelButtonIndex){
                if (buttonIndex == cancelButtonIndex) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:self];
                }
            };
            
            progressAlertView = [DTAlertView alertViewUseBlock:block title:@"Downloading..." message:nil cancelButtonTitle:@"Cancel" positiveButtonTitle:nil];
            [progressAlertView setAlertViewMode:DTAlertViewModeDuoProgress];
            
            // Preset progerss status befoure show, when shown alert view will show this setting.
            [progressAlertView setProgressStatus:DTProgressStatusMake(19, 20)];
            
            [progressAlertView show];
            
            [self performSelector:@selector(changePercentage:) withObject:@(0.1f) afterDelay:1.0f];
            [self performSelector:@selector(changeProgressStatus) withObject:nil afterDelay:10.0f];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - DTAlertView Delegate Methods

- (void)alertView:(DTAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"You click button title : %@", alertView.clickedButtonTitle);
    
    if (alertView.textField != nil) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            [alertView dismiss];
            
            return;
        }
        
        NSLog(@"Inputed Text : %@", alertView.textField.text);
        
        if (![alertView.textField.text isEqualToString:@"1234567890"]) {
            NSLog(@"%@", NSStringFromCGRect(alertView.frame));
            NSLog(@"Password Error !!");
            
            [alertView shakeAlertView];
        } else {
            [alertView dismiss];
        }
        
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark -

- (void)changePercentage:(NSNumber *)percentage
{
    CGFloat _percentage = [percentage floatValue];
    
    if (progressAlertView.alertViewMode != DTAlertViewModeDuoProgress) {
        [progressAlertView setAlertViewMode:DTAlertViewModeProgress];
    }
    
    [progressAlertView setMessage:nil];
    [progressAlertView setPercentage:_percentage];
    
    if (_percentage < 1.0f) {
        [self performSelector:@selector(changePercentage:) withObject:@(_percentage + 0.1f) afterDelay:1.0f];
    } else {
        [progressAlertView dismiss];
    }
}

- (void)changeProgressStatus
{
    [progressAlertView setProgressStatus:DTProgressStatusMake(20, 20)];
    [progressAlertView setPercentage:0.0f];
}

- (void)showOtherAlertView
{
    DTAlertView *alert = [DTAlertView alertViewWithTitle:@"Demo" message:@"I'm secound alert view" delegate:nil cancelButtonTitle:@"OK" positiveButtonTitle:nil];
    [alert setButtonTextColor:[UIColor orangeColor]];
    
    [alert show];
}

#pragma mark - Support Autorotate

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end
