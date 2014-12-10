//
//  DTAlertView.m
//
// Copyright (c) 2013 Darktt
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "DTAlertView.h"
#import <tgmath.h>
#import <QuartzCore/QuartzCore.h>

//#define DEBUG_MODE

#if __has_feature(objc_arc)

#define ARC_MODE_USED
#define DTAutorelease( expression )     expression
#define DTRelease( expression )
#define DTRetain( expression )          expression
#define DTBlockCopy( expression )       expression
#define DTBlockRelease( expression )    expression

#else

#define ARC_MODE_NOT_USED
#define DTAutorelease( expression )     [expression autorelease]
#define DTRelease( expression )         [expression release]
#define DTRetain( expression )          [expression retain]
#define DTBlockCopy( expression )       Block_copy( expression )
#define DTBlockRelease( expression )    Block_release( expression )

#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000

#define DTTextAlignmentCenter   NSTextAlignmentCenter

#else

#define DTTextAlignmentCenter   UITextAlignmentCenter

#endif

// Macros
#define kDefaultBGColor [UIColor blackColor]
#define kDefaultAutoResizeMask UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin

// Tags
#define kAlertBackgroundTag     1000

#define kTitleLableTag          2001
#define kMessageLabelTag        2002
#define kFirstProgressTag       2003
#define kSecondProgressTag      2004
#define kProgressStatusTag      2005
#define kPercentageTag          2006

#define kButtonBGViewTag        2099

// Animation Keys
static NSString *kAnimationShow = @"Popup";
static NSString *kAnimationDismiss = @"Dismiss";
static NSString *kAnimationShake = @"Shake";

// Message Limit Height
CGFloat const kMessageLabelLimitHight = 400.0f;

#pragma mark - Implement DTBackgroundView Class

@interface DTBackgroundView : UIView
{
    UIWindow *_previousKeyWindow;
    UIWindow *_alertWindow;
    NSMutableArray *_alertViews;
}

+ (DTInstancetype)currentBackground;
- (NSArray *)allAlertView;

@end

static DTBackgroundView *singletion = nil;

@implementation DTBackgroundView

+ (DTInstancetype)currentBackground
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletion = [DTBackgroundView new];
    });
    
    return singletion;
}

- (CGRect)iOS7StyleScreenBounds {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSComparisonResult result = [systemVersion compare:@"8.0" options:NSNumericSearch];
    
    UIApplication *application = [UIApplication sharedApplication];
    UIInterfaceOrientation orientation = application.statusBarOrientation;
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    
    if (result != NSOrderedDescending && isLandscape) {
        bounds.size = CGSizeMake(CGRectGetHeight(bounds), CGRectGetWidth(bounds));
    }
    
    return bounds;
}

- (DTInstancetype)init
{
    CGRect screenRect = [self iOS7StyleScreenBounds];
    
    self = [super initWithFrame:screenRect];
    if (self == nil) return nil;
    
    [self setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.5f]];
    
    _previousKeyWindow = DTRetain([[UIApplication sharedApplication] keyWindow]);
    [_previousKeyWindow resignKeyWindow];
    
    _alertWindow = [[UIWindow alloc] initWithFrame:screenRect];
    [_alertWindow setWindowLevel:UIWindowLevelAlert];
    [_alertWindow setBackgroundColor:[UIColor clearColor]];
    [_alertWindow addSubview:self];
    [_alertWindow makeKeyAndVisible];
    [_alertWindow setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    _alertViews = [NSMutableArray new];
    
    [self setHidden:YES];
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGRect screenRect = [self iOS7StyleScreenBounds];
    
    if (CGRectEqualToRect(self.frame, screenRect)) {
        return;
    }
    
    [_alertWindow setFrame:screenRect];
    [self setFrame:screenRect];
    
    [_alertViews enumerateObjectsUsingBlock:^(UIView *alertView, NSUInteger idx, BOOL *stop) {
        CGPoint backgroundCenter = CGPointMake(CGRectGetMidX(screenRect), CGRectGetMidY(screenRect));
        
        [alertView setCenter:backgroundCenter];
    }];
}

- (NSArray *)allAlertView
{
    return _alertViews;
}

- (void)setAlpha:(CGFloat)alpha
{
    if ([_alertViews count] > 0) {
        alpha = 1.0f;
    }
    
    [super setAlpha:alpha];
}

- (void)setHidden:(BOOL)hidden
{
    if ([_alertViews count] > 0) {
        hidden = NO;
    }
    
    [super setHidden:hidden];
    
    [_alertWindow setHidden:hidden];
    
    if (hidden) {
        [_alertWindow resignKeyWindow];
        [_previousKeyWindow makeKeyAndVisible];
    } else {
        [_previousKeyWindow resignKeyWindow];
        [_alertWindow makeKeyAndVisible];
    }
    
    [self setAlpha:1.0f];
}

- (void)addSubview:(UIView *)view
{
    [super addSubview:view];
    
    DTAlertView *alertView = _alertViews.lastObject;
    [alertView setHidden:YES];
    
    if ([view isKindOfClass:[DTAlertView class]]) {
        [_alertViews addObject:view];
    }
    
    [self setNeedsDisplay];
}

- (void)willRemoveSubview:(UIView *)subview
{
    [super willRemoveSubview:subview];
    
    if ([subview isKindOfClass:[DTAlertView class]]) {
        [_alertViews removeObject:subview];
    }
    
    DTAlertView *alertView = _alertViews.lastObject;
    [alertView setHidden:NO];
}

@end

#pragma mark - Implement DTAlertView Class

const static CGFloat kMotionEffectExtent = 15.0f;

@interface DTAlertView ()
{
    id<DTAlertViewDelegate> _delegate;
    
    DTAlertViewButtonClickedBlock _clickedBlock;
    DTAlertViewTextDidChangeBlock _textChangeBlock;
    NSString *_title;
    NSString *_message;
    DTAlertViewMode _alertViewMode;
    DTAlertViewAnimation _animationWhenDismiss;
    
    // Progress label
    DTProgressStatus _status;
    CGFloat _percentage;
    
    // Textfiled
    UITextField *_textField;
    
    // Progress Color
    UIColor *_progressTintColor;
    
    // Button Titles
    NSString *_cancelButtonTitle;
    NSInteger _cancelButtonIndex;
    NSString *_positiveButtonTitle;
    BOOL _positiveButtonEnable;
    NSString *_clickedButtonTitle;
    
    // Button Color
    UIColor *_buttonTextColor;
    
    // Back Ground
    UIView *_backgroundView;
    UIToolbar *_blurToolbar;
    
    BOOL _visible;
    BOOL _keyboardIsShown;
    
    BOOL _showForInputPassword;
}

@end

@implementation DTAlertView

+ (DTInstancetype)alertViewWithTitle:(NSString *)title message:(NSString *)message delegate:(id<DTAlertViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle
{
    DTAlertView *alertView = [[DTAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:delegate
                                              cancelButtonTitle:cancelButtonTitle
                                            positiveButtonTitle:positiveButtonTitle];
    
    return DTAutorelease(alertView);
}

- (DTInstancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<DTAlertViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle
{
    self = [super init];
    
    if (self == nil) return nil;
    [self setAutoresizesSubviews:YES];
    [self setMotionEffect];
    
    _delegate = delegate;
    _clickedBlock = nil;
    
    _title = DTRetain(title);
    _message = DTRetain(message);
    
    _cancelButtonTitle = DTRetain(cancelButtonTitle);
    _positiveButtonTitle = DTRetain(positiveButtonTitle);
    _positiveButtonEnable = YES;
    
    _backgroundView = nil;
    _visible = NO;
    _progressTintColor = [[UIColor alloc] initWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
    _buttonTextColor = [[UIColor alloc] initWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
    
    _keyboardIsShown = NO;
    
    _showForInputPassword = NO;
    
    [self setCancelButtonIndex];
    
    return self;
}

+ (DTInstancetype)alertViewUseBlock:(DTAlertViewButtonClickedBlock)block
                              title:(NSString *)title
                            message:(NSString *)message
                  cancelButtonTitle:(NSString *)cancelButtonTitle
                positiveButtonTitle:(NSString *)positiveButtonTitle
{
    DTAlertView *alertView = [[DTAlertView alloc] initWithBlock:block
                                                          title:title
                                                        message:message
                                              cancelButtonTitle:cancelButtonTitle
                                            positiveButtonTitle:positiveButtonTitle];
    
    return DTAutorelease(alertView);
}

- (DTInstancetype)initWithBlock:(DTAlertViewButtonClickedBlock)block
                          title:(NSString *)title
                        message:(NSString *)message
              cancelButtonTitle:(NSString *)cancelButtonTitle
            positiveButtonTitle:(NSString *)positiveButtonTitle
{
    self = [super init];
    
    if (self == nil) return nil;
    [self setMotionEffect];
    
    _delegate = nil;
    _clickedBlock = DTBlockCopy(block);
    
    _title = DTRetain(title);
    _message = DTRetain(message);
    
    _alertViewMode = DTAlertViewModeNormal;
    _animationWhenDismiss = DTAlertViewAnimationDefault;
    
    _cancelButtonTitle = DTRetain(cancelButtonTitle);
    _positiveButtonTitle = DTRetain(positiveButtonTitle);
    _positiveButtonEnable = YES;
    
    _backgroundView = nil;
    _visible = NO;
    _progressTintColor = [[UIColor alloc] initWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
    _buttonTextColor = [[UIColor alloc] initWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
    
    _keyboardIsShown = NO;
    
    _showForInputPassword = NO;
    
    [self setCancelButtonIndex];

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_blurToolbar != nil) {
        [_blurToolbar setFrame:self.bounds];
    }
    
}

#ifdef ARC_MODE_NOT_USED

- (void)dealloc
{
    if (_clickedBlock != nil) {
        Block_release(_clickedBlock);
    }
    
    if (_title != nil) {
        [_title release];
        _title = nil;
    }
    
    if (_message != nil) {
        [_message release];
        _message = nil;
    }
    
    if (_cancelButtonTitle != nil) {
        [_cancelButtonTitle release];
        _cancelButtonTitle = nil;
    }
    
    if (_buttonTextColor != nil) {
        [_buttonTextColor release];
        _buttonTextColor = nil;
    }
    
    if (_positiveButtonTitle != nil) {
        [_positiveButtonTitle release];
        _positiveButtonTitle = nil;
    }
    
    if (_clickedButtonTitle != nil) {
        [_clickedButtonTitle release];
        _clickedButtonTitle = nil;
    }
    
    if (_blurToolbar != nil) {
        [_blurToolbar release];
        _blurToolbar = nil;
    }
    
    if (_textField != nil) {
        [_textField release];
        _textField = nil;
    }
    
    if (_progressTintColor != nil) {
        [_progressTintColor release];
        _progressTintColor = nil;
    }
    
    if (_textChangeBlock != nil) {
        Block_release(_textChangeBlock);
    }
    
    [super dealloc];
}

#endif

#pragma mark - Property Methods

- (void)setDelegate:(id<DTAlertViewDelegate>)delegate
{
    if (_clickedBlock != nil) {
        
        NSLog(@"%s-%d:Block is set, can't use delegate.", __func__, __LINE__);
        
        return;
    }
    
    _delegate = delegate;
}

- (id<DTAlertViewDelegate>)delegate
{
    return _delegate;
}

- (void)setTitle:(NSString *)title
{
    if ([_title isEqualToString:title]) {
        return;
    }
    
    if (_title != nil) {
        DTRelease(_title);
    }
    
    _title = DTRetain(title);
    
    if (_visible) {
        [self renewLayout];
    }
}

- (NSString *)title
{
    return _title;
}

- (void)setMessage:(NSString *)message
{
    if ([_message isEqualToString:message]) {
        return;
    }
    
    if (_message != nil) {
        DTRelease(_message);
    }
    
    _message = DTRetain(message);
    
    if (_visible) {
        [self renewLayout];
    }
}

- (NSString *)message
{
    return _message;
}

- (void)setAlertViewMode:(DTAlertViewMode)alertViewMode
{
    _alertViewMode = alertViewMode;
    
    if (_visible) {
        [self renewLayout];
    }
}

- (DTAlertViewMode)alertViewMode
{
    return _alertViewMode;
}

- (void)setDismissAnimationWhenButtonClicked:(DTAlertViewAnimation)dismissAnimationWhenButtonClicked
{
    _animationWhenDismiss = dismissAnimationWhenButtonClicked;
}

- (DTAlertViewAnimation)dismissAnimationWhenButtonClicked
{
    return _animationWhenDismiss;
}

- (NSInteger)cancelButtonIndex
{
    return _cancelButtonIndex;
}

- (BOOL)isVisible
{
    return _visible;
}

- (NSString *)clickedButtonTitle
{
    return _clickedButtonTitle;
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    [self.layer setCornerRadius:cornerRadius];
}

- (CGFloat)cornerRadius
{
    return self.layer.cornerRadius;
}

- (void)setBackgroundView:(UIView *)backgroundView
{
    if (backgroundView == nil) {
        [self setBackgroundColor:kDefaultBGColor];
        
        DTRelease(_backgroundView);
        _backgroundView = nil;
        
        return;
    }
    
    if ([_backgroundView isEqual:backgroundView]) {
        return;
    }
    
    if (_backgroundView != nil) {
        DTRelease(_backgroundView);
    }
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    _backgroundView = DTRetain(backgroundView);
    [_backgroundView setFrame:self.bounds];
    
    [self insertSubview:_backgroundView atIndex:0];
}

- (UIView *)backgroundView
{
    
    return _backgroundView;
}

- (UITextField *)textField
{
    return _textField;
}

- (void)setButtonTextColor:(UIColor *)buttonTextColor
{
    if (_buttonTextColor != nil) {
        DTRelease(_buttonTextColor);
    }
    
    if (buttonTextColor != nil) {
        _buttonTextColor = DTRetain(buttonTextColor);
    } else {
        _buttonTextColor = [[UIColor alloc] initWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
    }
    
    if (_visible && [self checkButtonTitleExist]) {
        if (_cancelButtonTitle != nil) {
            UIButton *cancelButton = (UIButton *)[self viewWithTag:_cancelButtonIndex + 1];
            [cancelButton setTitleColor:_buttonTextColor forState:UIControlStateNormal];
        }
        
        if (_positiveButtonTitle != nil) {
            UIButton *positiveButton = (UIButton *)[self viewWithTag:_cancelButtonIndex + 2];
            [positiveButton setTitleColor:_buttonTextColor forState:UIControlStateNormal];
        }
    }
}

- (UIColor *)buttonTextColor
{
    return _buttonTextColor;
}

- (void)setProgressBarColor:(UIColor *)progressBarColor
{
    // Only set at DTAlertViewModeProgress and DTAlertViewModeDuoProgress
    if (_alertViewMode != DTAlertViewModeProgress && _alertViewMode != DTAlertViewModeDuoProgress) {
        return;
    }
    
    if (_progressTintColor != nil) {
        DTRelease(_progressTintColor);
    }
    
    if (progressBarColor != nil) {
        _progressTintColor = DTRetain(progressBarColor);
    } else {
        _progressTintColor = [[UIColor alloc] initWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
    }
    
    if (_visible && (_alertViewMode == DTAlertViewModeProgress || _alertViewMode == DTAlertViewModeDuoProgress)) {
        UIProgressView *firstProgress = (UIProgressView *)[self viewWithTag:kFirstProgressTag];
        [firstProgress setProgressTintColor:_progressTintColor];
        
        UIProgressView *secondProgress = (UIProgressView *)[self viewWithTag:kSecondProgressTag];
        if (secondProgress != nil) {
            [secondProgress setProgressTintColor:_progressTintColor];
        }
    }
}

- (UIColor *)progressBarColor
{
    return _progressTintColor;
}

#pragma mark - Instance Methods

#pragma mark Blur Background

- (void)setBlurBackgroundWithColor:(UIColor *)color alpha:(CGFloat)alpha
{
    if (_blurToolbar != nil) {
        return;
    }
    
    // Add alpha into color
    color = [color colorWithAlphaComponent:alpha];
    
    // Set blur use toolBar create it.
    _blurToolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
    [_blurToolbar setBarTintColor:color];
    
    [self.layer insertSublayer:_blurToolbar.layer atIndex:0];
}

#pragma mark Set Positive Button enable

- (void)setPositiveButtonEnable:(BOOL)enable
{
    _positiveButtonEnable = enable;
    
    if (_visible) {
        UIButton *positiveButton = (UIButton *)[self viewWithTag:_cancelButtonIndex + 2];
        [positiveButton setEnabled:enable];
    }
}

#pragma mark Set Label Under Progress view

- (void)setProgressStatus:(DTProgressStatus)status
{
    // Only set value at DTAlertViewModeDuoProgress
    if (_alertViewMode != DTAlertViewModeDuoProgress) {
        return;
    }
    
    _status = status;
    
    if (_visible) {
        CGFloat progress = (CGFloat)status.current/(CGFloat)status.total;
        
        UIProgressView *firstProgress = (UIProgressView *)[self viewWithTag:kFirstProgressTag];
        [firstProgress setProgress:progress];
        
        UILabel *statusLabel = (UILabel *)[self viewWithTag:kProgressStatusTag];
        [statusLabel setText:NSStringFromDTProgressStatus(status)];
        [statusLabel sizeToFit];
        [statusLabel setCenter:CGPointMake(CGRectGetMidX(self.bounds), statusLabel.center.y)];
    }
}

- (void)setPercentage:(CGFloat)percentage
{
    // Only set value at DTAlertViewModeProgress and DTAlertViewModeDuoProgress
    if (_alertViewMode != DTAlertViewModeProgress && _alertViewMode != DTAlertViewModeDuoProgress) {
        return;
    }
    
    // Set minimum limit
    if (percentage < 0.0f) {
        _percentage = 0.0f;
    }
    
    // Set maximum limit
    if (percentage > 1.0f) {
        _percentage = 1.0f;
    }
    
    _percentage = percentage;
    
    if (_visible) {
        if (_alertViewMode == DTAlertViewModeProgress) {
            UIProgressView *firstProgress = (UIProgressView *)[self viewWithTag:kFirstProgressTag];
            [firstProgress setProgress:percentage];
        }
        
        if (_alertViewMode == DTAlertViewModeDuoProgress) {
            UIProgressView *secondProgress = (UIProgressView *)[self viewWithTag:kSecondProgressTag];
            [secondProgress setProgress:percentage];
        }
        
        UILabel *percentageLabel = (UILabel *)[self viewWithTag:kPercentageTag];
        [percentageLabel setText:[NSString stringWithFormat:@"%.0f%%", percentage * 100]];
        [percentageLabel sizeToFit];
        [percentageLabel setCenter:CGPointMake(CGRectGetMidX(self.bounds), percentageLabel.center.y)];
    }
}

#pragma mark Show Alert View Methods

- (void)show
{
    [self showWithAnimation:DTAlertViewAnimationDefault];
}

- (void)showForPasswordInputWithAnimation:(DTAlertViewAnimation)animation;
{
    _showForInputPassword = YES;
    
    [self showWithAnimation:animation];
}

- (void)showWithAnimation:(DTAlertViewAnimation)animation
{
#ifndef DEBUG_MODE
    
    [self setClipsToBounds:YES];
    
#endif
    
    // If background color or background view not set, will set to default scenario.
    if (self.backgroundColor == nil && _backgroundView == nil) {
        
        if ([UIToolbar instancesRespondToSelector:@selector(setBarTintColor:)]) {
            [self setBlurBackgroundWithColor:nil alpha:0];
        } else {
            [self setBackgroundColor:[UIColor whiteColor]];
        }
    }
    
    if (self.layer.cornerRadius == 0.0f) {
        [self.layer setCornerRadius:5.0f];
    }
    
    [self setFrame:CGRectMake(0, 0, 270, 270)];
    [self setViews];
    
    // Rotate self befoure show.
    CGFloat angle = [self angleForCurrentOrientation];
    [self setTransform:CGAffineTransformMakeRotation(angle)];
    
    // Background of alert view
    DTBackgroundView *backgroundView = [DTBackgroundView currentBackground];
    [backgroundView setHidden:NO];
    
    [self setCenter:backgroundView.center];
    [backgroundView addSubview:self];
    
    CAAnimation *showsAnimation = nil;
    
    switch (animation) {
        case DTAlertViewAnimationDefault:
            showsAnimation = [self defaultShowsAnimation];
            break;
            
        case DTAlertViewAnimationSlideTop:
            showsAnimation = [self sildeInBottomAnimation];
            break;
            
        case DTAlertViewAnimationSlideBottom:
            showsAnimation = [self sildeInTopAnimation];
            break;
            
        case DTAlertViewAnimationSlideLeft:
            // Slide in from right of screen.
            showsAnimation = [self sildeInRightAnimation];
            break;
            
        case DTAlertViewAnimationSlideRight:
            // Slide in from left of screen.
            showsAnimation = [self sildeInLeftAnimation];
            break;
            
        default:
            NSLog(@"DTAlertViewAnimation style error!!");
            break;
    }
    
    [self.layer addAnimation:showsAnimation forKey:kAnimationShow];
    
    [self performSelector:@selector(showsCompletion) withObject:nil afterDelay:0.1f];
}

- (void)showsCompletion
{
    _visible = YES;
    
    [self.layer removeAnimationForKey:kAnimationShow];
    
    // Trigger keyboard to show
    if (_textField != nil) {
        [_textField becomeFirstResponder];
    }
    
    // Regist notification for handle rotate issue
    [self registRotationHandleNotification];
}

#pragma mark Dismiss Alert View Method

+ (BOOL)dismissAllAlertView
{
    NSArray *alertViews = [[DTBackgroundView currentBackground] allAlertView];
    
    if ([alertViews count] == 0) {
        return NO;
    }
    
    [alertViews enumerateObjectsUsingBlock:^(DTAlertView *alertView, NSUInteger idx, BOOL *stop) {
        [alertView dismiss];
    }];
    
    return YES;
}

+ (BOOL)dismissAlertViewViaTitle:(NSString *)title
{
    NSArray *alertViews = [[DTBackgroundView currentBackground] allAlertView];
    
    if ([alertViews count] == 0) {
        return NO;
    }
    
    __block BOOL isCorrespond = NO;
    
    [alertViews enumerateObjectsUsingBlock:^(DTAlertView *alertView, NSUInteger idx, BOOL *stop) {
        if ([alertView.title isEqualToString:title]) {
            [alertView dismiss];
            
            isCorrespond = YES;
        }
    }];
    
    return isCorrespond;
}

+ (BOOL)dismissAlertViewViaMessage:(NSString *)message
{
    NSArray *alertViews = [[DTBackgroundView currentBackground] allAlertView];
    
    if ([alertViews count] == 0) {
        return NO;
    }
    
    __block BOOL isCorrespond = NO;
    
    [alertViews enumerateObjectsUsingBlock:^(DTAlertView *alertView, NSUInteger idx, BOOL *stop) {
        if ([alertView.message isEqualToString:message]) {
            [alertView dismiss];
            
            isCorrespond = YES;
        }
    }];
    
    return isCorrespond;
}

- (void)dismiss
{
    [self dismissWithAnimation:DTAlertViewAnimationDefault];
}

- (void)dismissWithAnimation:(DTAlertViewAnimation)animation
{
    // Remove notification for rotate
    [self removeRotationHandleNotification];

    if (_delegate != nil && [_delegate respondsToSelector:@selector(alertViewWillDismiss:)]) {
        [_delegate alertViewWillDismiss:self];
    }
    
    if (_keyboardIsShown) {
        [_textField resignFirstResponder];
        
        // Remove notification
        [self removeKeyboarHandleNotification];
    }
    
    CAAnimation *dismissAnimation = nil;
    
    switch (animation) {
        case DTAlertViewAnimationDefault:
            dismissAnimation = [self defaultDismissAnimation];
            break;
            
        case DTAlertViewAnimationSlideTop:
            dismissAnimation = [self sildeOutTopAnimation];
            break;
            
        case DTAlertViewAnimationSlideBottom:
            dismissAnimation = [self sildeOutBottomAnimation];
            break;
            
        case DTAlertViewAnimationSlideLeft:
            // Slide out to left of screen.
            dismissAnimation = [self sildeOutLeftAnimation];
            break;
            
        case DTAlertViewAnimationSlideRight:
            // Slide out to right of screen.
            dismissAnimation = [self sildeOutRightAnimation];
            break;
            
        default:
            NSLog(@"DTAlertViewAnimation style error!!");
            break;
    }
    
    [self.layer addAnimation:dismissAnimation forKey:kAnimationDismiss];
    
    [self performSelector:@selector(dismissCompletion) withObject:nil afterDelay:dismissAnimation.duration];
}

- (void)dismissCompletion
{
    // Dismiss self
    [self removeFromSuperview];
    
    // Remove dismiss animation
    [self.layer removeAnimationForKey:kAnimationDismiss];
    
    [UIView animateWithDuration:0.2f animations:^{
        [[DTBackgroundView currentBackground] setAlpha:0.0f];
    } completion:^(BOOL finished) {
        [[DTBackgroundView currentBackground] setHidden:YES];
    }];
    
    _visible = NO;
    
    if (_delegate != nil && [_delegate respondsToSelector:@selector(alertViewDidDismiss:)]) {
        [_delegate alertViewDidDismiss:self];
    }
}

#pragma mark Shake AlertView Method

- (void)shakeAlertView
{
    CAAnimation *shakeAnimation = [self shakeAnimation];
    
    [self.layer removeAnimationForKey:kAnimationShake];
    [self.layer addAnimation:shakeAnimation forKey:kAnimationShake];
}

#pragma mark Set TextField Did Cahnge Block

- (void)setTextFieldDidChangeBlock:(DTAlertViewTextDidChangeBlock)textBlock
{
    _textChangeBlock = DTBlockCopy(textBlock);
}

#pragma mark - Set Views

- (void)setViews
{
    //MARK: Labels
    
    // Label default value.
    CGFloat labelMaxWidth = CGRectGetWidth(self.frame) - 10.0f;
    CGRect labelDefaultRect = CGRectMake(0, 0, labelMaxWidth, labelMaxWidth);
    
    // Title
    UILabel *titleLabel = [[UILabel alloc] init];
    [titleLabel setText:_title];
    [titleLabel setTextColor:[UIColor blackColor]];
    [titleLabel setTextAlignment:DTTextAlignmentCenter];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [titleLabel setTag:kTitleLableTag];
    
    // Set lines of title text.
    [titleLabel setNumberOfLines:0];
    
    // Set title label position and size.
    [titleLabel setFrame:labelDefaultRect];
    [titleLabel sizeToFit];
    
    [titleLabel setCenter:CGPointMake(CGRectGetMidX(self.bounds), titleLabel.center.y + 20.0f)];
    
    [self addSubview:titleLabel];
    
#ifdef DEBUG_MODE
    
    [titleLabel setBackgroundColor:[UIColor yellowColor]];
    NSLog(@"Title Label Frame: %@", NSStringFromCGRect(titleLabel.frame));
    
#endif
    
    // Message
    UILabel *messageLabel = [[UILabel alloc] init];
    [messageLabel setText:_message];
    [messageLabel setTextColor:[UIColor blackColor]];
    [messageLabel setTextAlignment:DTTextAlignmentCenter];
    [messageLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [messageLabel setTag:kMessageLabelTag];
    
    // Set lines of message text.
    [messageLabel setNumberOfLines:0];
    
    // Set message label position and size.
    CGRect messageRect = CGRectZero;
    messageRect.origin.y = CGRectGetMaxY(titleLabel.frame) + 5.0f;
    messageRect.size = labelDefaultRect.size;
    
    [messageLabel setFrame:messageRect];
    [messageLabel sizeToFit];
    [messageLabel setCenter:CGPointMake(CGRectGetMidX(self.bounds), messageLabel.center.y)];
    
    CGFloat messageMaxYPosition = 0.0f;
    
    if (CGRectGetHeight(messageLabel.frame) > kMessageLabelLimitHight) {
        
        messageMaxYPosition = [self setupScrollViewToContentMessage:messageLabel];
        
    } else {
        
        [self addSubview:messageLabel];
        
        messageMaxYPosition = CGRectGetMaxY(messageLabel.frame);
    }

#ifdef DEBUG_MODE
    
    [messageLabel setBackgroundColor:[UIColor greenColor]];
    NSLog(@"Message Label Frame: %@", NSStringFromCGRect(messageLabel.frame));
    NSLog(@"Message Max Y Positiopn: %.1f", messageMaxYPosition);
    
#endif
    
    // Calculator buttons field rectangle.
    CGRect buttonsField = CGRectZero;
    buttonsField.size = CGSizeMake(self.frame.size.width, 45.0f);
    
    switch (_alertViewMode) {
            
        case DTAlertViewModeNormal:
            buttonsField.origin.y = messageMaxYPosition + 20.0f;
            
            if (![self checkButtonTitleExist]) {
                [self resizeViewWithLastRect:buttonsField];
            }
            break;
            
        case DTAlertViewModeTextInput:
        {
            //MARK: TextField
            _textField = [[UITextField alloc] initWithFrame:CGRectMake(0, messageMaxYPosition + 10.0f, 260.0f, 30.0f)];
            [_textField setBorderStyle:UITextBorderStyleRoundedRect];
            [_textField addTarget:self action:@selector(textFieldDidBegin:) forControlEvents:UIControlEventEditingDidBegin];
            [_textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            [_textField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEndOnExit];
            
            [_textField setCenter:CGPointMake(CGRectGetMidX(self.bounds), _textField.center.y)];
            
            if ([_textField respondsToSelector:@selector(setTintColor:)]) {
                [_textField setTintColor:[UIColor colorWithRed:0 green:122.0f/255.0f blue:1 alpha:1]];
            }
            
            [self addSubview:_textField];
            
#ifdef DEBUG_MODE
            NSLog(@"TextField Frame: %@", NSStringFromCGRect(_textField.frame));
#endif
            buttonsField.origin.y = CGRectGetMaxY(_textField.frame) + 20.0f;
            
            if (![self checkButtonTitleExist]) {
                [self resizeViewWithLastRect:_textField.frame];
            }
            
        }
            break;
            
        case DTAlertViewModeProgress:
        {
            //MARK: Progress and label under the progress
            
            // Progress View
            UIProgressView *firstProgress = [self setProgressViewWithFrame:CGRectMake(0, messageMaxYPosition + 10.0f, 260.0f, 2.0f)];
            [firstProgress setTag:kFirstProgressTag];
            [firstProgress setProgress:_percentage];
            [firstProgress setCenter:CGPointMake(CGRectGetMidX(self.bounds), firstProgress.center.y)];
            
            [self addSubview:firstProgress];
            
#ifdef DEBUG_MODE
            NSLog(@"Progress View Frame: %@", NSStringFromCGRect(firstProgress.frame));
#endif
            // Label
            UILabel *percentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(firstProgress.frame) + 5.0f, 100.0f, 50)];
            [percentageLabel setText:[NSString stringWithFormat:@"%.0f%%", _percentage * 100]];
            [percentageLabel setTextColor:[UIColor blackColor]];
            [percentageLabel setTag:kPercentageTag];
            
            [percentageLabel sizeToFit];
            [percentageLabel setCenter:CGPointMake(CGRectGetMidX(self.bounds), percentageLabel.center.y)];
            
            [self addSubview:percentageLabel];
            
#ifdef DEBUG_MODE
            NSLog(@"Progress Label Frame: %@", NSStringFromCGRect(percentageLabel.frame));
#endif
            
            DTRelease(percentageLabel);
            
            buttonsField.origin.y = CGRectGetMaxY(percentageLabel.frame) + 20.0f;
            
            if (![self checkButtonTitleExist]) {
                [self resizeViewWithLastRect:percentageLabel.frame];
            }
        }
            break;
            
        case DTAlertViewModeDuoProgress:
        {
            CGFloat progress = (CGFloat)_status.current/(CGFloat)_status.total;
            
            // 1st Progress View
            UIProgressView *firstProgress = [self setProgressViewWithFrame:CGRectMake(0, messageMaxYPosition + 10.0f, labelMaxWidth, 2.0f)];
            [firstProgress setProgress:progress];
            [firstProgress setTag:kFirstProgressTag];
            [firstProgress setCenter:CGPointMake(CGRectGetMidX(self.bounds), firstProgress.center.y)];
            
            [self addSubview:firstProgress];
            
#ifdef DEBUG_MODE
            NSLog(@"First Progress View Frame: %@", NSStringFromCGRect(firstProgress.frame));
#endif
            // Status Label
            UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(firstProgress.frame) + 5.0f, 100.0f, 50)];
            [statusLabel setText:NSStringFromDTProgressStatus(_status)];
            [statusLabel setTextColor:[UIColor blackColor]];
            [statusLabel setTag:kProgressStatusTag];
            
            [statusLabel sizeToFit];
            [statusLabel setCenter:CGPointMake(CGRectGetMidX(self.bounds), statusLabel.center.y)];
            
            [self addSubview:statusLabel];
            
#ifdef DEBUG_MODE
            NSLog(@"Status Label Frame: %@", NSStringFromCGRect(statusLabel.frame));
#endif
            
            DTRelease(statusLabel);
            
            // 2nd Progress View
            UIProgressView *secondProgress = [self setProgressViewWithFrame:CGRectMake(0, CGRectGetMaxY(statusLabel.frame) + 10.0f, labelMaxWidth, 2.0f)];
            [secondProgress setTag:kSecondProgressTag];
            [secondProgress setCenter:CGPointMake(CGRectGetMidX(self.bounds), secondProgress.center.y)];
            
            [self addSubview:secondProgress];
            
#ifdef DEBUG_MODE
            NSLog(@"Second Progress View Frame: %@", NSStringFromCGRect(secondProgress.frame));
#endif
            // Percent Label
            UILabel *percentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(secondProgress.frame) + 5.0f, 100.0f, 50)];
            [percentageLabel setText:[NSString stringWithFormat:@"%.0f%%", _percentage * 100]];
            [percentageLabel setTextColor:[UIColor blackColor]];
            [percentageLabel setTag:kPercentageTag];
            
            [percentageLabel sizeToFit];
            [percentageLabel setCenter:CGPointMake(CGRectGetMidX(self.bounds), percentageLabel.center.y)];
            
            [self addSubview:percentageLabel];
            
#ifdef DEBUG_MODE
            NSLog(@"Progress Label Frame: %@", NSStringFromCGRect(percentageLabel.frame));
#endif
            
            DTRelease(percentageLabel);
            
            buttonsField.origin.y = CGRectGetMaxY(percentageLabel.frame) + 20.0f;
            
            if (![self checkButtonTitleExist]) {
                [self resizeViewWithLastRect:percentageLabel.frame];
            }
        }
            break;
            
        default:
            break;
    }
    
    //Release Label
    DTRelease(titleLabel);
    DTRelease(messageLabel);
    
#ifdef DEBUG_MODE
    NSLog(@"Button Field: %@", NSStringFromCGRect(buttonsField));
#endif
    
    //MARK: Buttons
    
    // When all button title not set, ignore this setting.
    if (![self checkButtonTitleExist]) {
        return;
    }
    
    UIView *buttonBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(buttonsField), CGRectGetMinY(buttonsField) - 1.0f, CGRectGetWidth(buttonsField), CGRectGetHeight(buttonsField) + 1.0f)];
    [buttonBackgroundView setBackgroundColor:[UIColor colorWithWhite:0.5f alpha:0.8f]];
    [buttonBackgroundView setTag:kButtonBGViewTag];
    
    [self addSubview:buttonBackgroundView];
    DTRelease(buttonBackgroundView);
    
    CGFloat buttonWidth;
    
    if (_cancelButtonTitle != nil && _positiveButtonTitle != nil) {
        buttonWidth = buttonsField.size.width / 2 - 0.5f;
    } else {
        buttonWidth = buttonsField.size.width;
    }
    
    // Cancel Button
    if (_cancelButtonTitle != nil) {
        UIButton *cancelButton = [self setButtonWithTitle:_cancelButtonTitle];
        [cancelButton setTag:_cancelButtonIndex + 1];
        [cancelButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect cancelButtonFrame = buttonsField;
        cancelButtonFrame.size.width = buttonWidth;
        
        [cancelButton setFrame:cancelButtonFrame];
        [self addSubview:cancelButton];
        
#ifdef DEBUG_MODE
        NSLog(@"Cancel Button Frame: %@", NSStringFromCGRect(cancelButtonFrame));
#endif
    }
    
    // Positive Button
    if (_positiveButtonTitle != nil) {
        UIButton *positiveButton = [self setButtonWithTitle:_positiveButtonTitle];
        [positiveButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        [positiveButton setTag:_cancelButtonIndex + 2];
        [positiveButton.titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
        [positiveButton setEnabled:_positiveButtonEnable];
        [positiveButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect positiveButtonFrame = buttonsField;
        positiveButtonFrame.size.width = buttonWidth;
        
        if (_cancelButtonTitle != nil) {
            positiveButtonFrame.origin.x = buttonWidth + 1.0f;
        }
        
        [positiveButton setFrame:positiveButtonFrame];
        [self addSubview:positiveButton];
        
#ifdef DEBUG_MODE
        NSLog(@"Positive Button Frame: %@", NSStringFromCGRect(positiveButtonFrame));
#endif
    }
    
    [self resizeViewWithLastRect:buttonsField];
}

- (CGFloat)setupScrollViewToContentMessage:(UILabel *)messageLabel
{
    // Prepare scroll view rect
    CGFloat labelWidth = CGRectGetWidth(messageLabel.frame);
    CGRect scrollViewRect = CGRectMake(0, 0, labelWidth, labelWidth);
    scrollViewRect.origin = messageLabel.frame.origin;
    
    // Adjust message postition to (0, 0)
    CGRect messageLabelRect = messageLabel.frame;
    messageLabelRect.origin = CGPointZero;
    
    [messageLabel setFrame:messageLabelRect];
    
    // Setup scroll view
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:scrollViewRect];
    [scrollView setContentSize:messageLabel.frame.size];
    
    [scrollView addSubview:messageLabel];
    
    [self addSubview:scrollView];
    
    return CGRectGetMaxY(scrollView.frame);
}

#pragma mark Default Views Setting

- (UIProgressView *)setProgressViewWithFrame:(CGRect)frame
{
    UIProgressView *progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [progress setFrame:frame];
    [progress setProgressTintColor:_progressTintColor];
    
    return DTAutorelease(progress);
}

- (UIButton *)setButtonWithTitle:(NSString *)buttonTitle
{
    UIColor *buttonColor = self.backgroundColor;
    
    if (buttonColor == nil) {
        buttonColor = [UIColor whiteColor];
    }
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundColor:buttonColor];
    [button setTitle:buttonTitle forState:UIControlStateNormal];
    [button setTitleColor:_buttonTextColor forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [button setClipsToBounds:YES];
    
    return button;
}

- (BOOL)checkButtonTitleExist
{
    return (_cancelButtonTitle != nil || _positiveButtonTitle != nil);
}

#pragma mark Layout Handle

- (void)resizeViewWithLastRect:(CGRect)lastRect
{
    CGRect selfFrame = self.frame;
    selfFrame.size.height = CGRectGetMaxY(lastRect);
    
    [self setFrame:selfFrame];
}

- (void)renewLayout
{
    UILabel *titleLabel = (UILabel *)[self viewWithTag:kTitleLableTag];
    [titleLabel removeFromSuperview];
    titleLabel = nil;
    
    UILabel *messageLabel = (UILabel *)[self viewWithTag:kMessageLabelTag];
    [messageLabel removeFromSuperview];
    messageLabel = nil;
    
    if (_alertViewMode == DTAlertViewModeProgress || _alertViewMode == DTAlertViewModeDuoProgress) {
        UIProgressView *firstProgress = (UIProgressView *)[self viewWithTag:kFirstProgressTag];
        [firstProgress removeFromSuperview];
        firstProgress = nil;
        
        UILabel *percentageLabel = (UILabel *)[self viewWithTag:kPercentageTag];
        [percentageLabel removeFromSuperview];
        percentageLabel = nil;
        
        UILabel *statusLabel = (UILabel *)[self viewWithTag:kProgressStatusTag];
        if (statusLabel != nil) {
            [statusLabel removeFromSuperview];
            statusLabel = nil;
        }
        
        UIProgressView *secondProgress = (UIProgressView *)[self viewWithTag:kSecondProgressTag];
        if (secondProgress != nil) {
            [secondProgress removeFromSuperview];
            secondProgress = nil;
        }
    }
    
    if (_alertViewMode == DTAlertViewModeTextInput) {
        [_textField removeFromSuperview];
        DTRelease(_textField);
        _textField = nil;
    }
    
    if ([self checkButtonTitleExist]) {
        UIView *buttonBackgroundView = [self viewWithTag:kButtonBGViewTag];
        [buttonBackgroundView removeFromSuperview];
        buttonBackgroundView = nil;
    }
    
    if (_cancelButtonTitle != nil) {
        UIButton *cancelButton = (UIButton *)[self viewWithTag:_cancelButtonIndex + 1];
        [cancelButton removeFromSuperview];
        cancelButton = nil;
    }
    
    if (_positiveButtonTitle != nil) {
        UIButton *positiveButton = (UIButton *)[self viewWithTag:_cancelButtonIndex + 2];
        [positiveButton removeFromSuperview];
        positiveButton = nil;
    }
    
    [self setViews];
}

#pragma mark Set Cancel Button Index

- (void)setCancelButtonIndex
{
    if (_cancelButtonTitle == nil) {
        _cancelButtonIndex = -1;
        
        return;
    }
    
    _cancelButtonIndex = 0;
}

#pragma mark - Button Action

- (IBAction)buttonClicked:(UIButton *)sender
{
    [sender setEnabled:NO];
    
    // When using showForInputPassword: Method, delay 0.35 second to enable it.
    if ((sender.tag - 1) != _cancelButtonIndex && _showForInputPassword) {
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35f * NSEC_PER_SEC));
        
        dispatch_after(delayTime, dispatch_get_main_queue(), ^(void){
           [sender setEnabled:_showForInputPassword];
        });
    }

    if (_clickedButtonTitle != nil) {
        DTRelease(_clickedButtonTitle);
    }
    
    _clickedButtonTitle = DTRetain([sender titleForState:UIControlStateNormal]);
    
    if (_clickedBlock != nil) {
        _clickedBlock(self, sender.tag - 1, _cancelButtonIndex);
        
        // Ignore the deleage setting.
        _delegate = nil;
    }
    
    if ([_delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [_delegate alertView:self clickedButtonAtIndex:sender.tag - 1];
        
        // Ignore the block setting.
        _clickedBlock = nil;
    }
    
    if (!_showForInputPassword) {
        [self dismissWithAnimation:_animationWhenDismiss];
    }
}

#pragma mark - TextField Action

- (IBAction)textFieldDidBegin:(id)sender
{
    // Remove keyboard notification first
    [self removeKeyboarHandleNotification];
    
    // Then regist notification
    [self registKeyboardHandleNotification];
}

- (IBAction)textFieldDidChange:(id)sender
{
    /* Support Block at first priority */
    if (_textChangeBlock != nil) {
        _textChangeBlock(self, _textField.text);
        return;
    }
    
    /* If block is nil, then responds to delegate */
    if ([_delegate respondsToSelector:@selector(alertViewTextDidChanged:)]) {
        [_delegate alertViewTextDidChanged:self];
    }
}

- (IBAction)textFieldDidEndEditing:(id)sender
{
    [_textField resignFirstResponder];
    
    // Remove notification
    [self removeKeyboarHandleNotification];
}

#pragma mark - Handle Notification

- (void)registRotationHandleNotification
{
#ifdef DEBUG_MODE
    
    NSLog(@"** Regist rotation notification **");
    
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotationHandle:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)removeRotationHandleNotification
{
#ifdef DEBUG_MODE
    
    NSLog(@"** Remove rotation notification **");
    
#endif
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)registKeyboardHandleNotification
{
#ifdef DEBUG_MODE
    
    NSLog(@"** Regist keyboard notification **");
    
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeKeyboarHandleNotification
{
#ifdef DEBUG_MODE
    
    NSLog(@"** Remove keyboard notification **");
    
#endif
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark KeyBoard Notification Methods

- (IBAction)keyboardWillShow:(NSNotification *)notification
{
    _keyboardIsShown = YES;
}

- (IBAction)keyboardWillChangeFrame:(NSNotification *)notification
{
    NSDictionary *parameter = (NSDictionary *)notification.userInfo;
    
    [self setNewCenterWhenKeyboardApearWithKeyboardParameter:parameter];
}

- (IBAction)keyboardWillHide:(NSNotification *)notification
{
    _keyboardIsShown = NO;
    
    NSDictionary *parameter = (NSDictionary *)notification.userInfo;
    NSNumber *keyboardHideDuration = (NSNumber *)parameter[UIKeyboardAnimationDurationUserInfoKey];
    
    [UIView animateWithDuration:[keyboardHideDuration doubleValue] animations:^{
        // Move current view to center
        UIView *backGround = [self superview];
        [self setCenter:backGround.center];
    }];
}

- (void)setNewCenterWhenKeyboardApearWithKeyboardParameter:(NSDictionary *)parameter
{
    UIApplication *application = [UIApplication sharedApplication];
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(application.statusBarOrientation);
    
    CGRect frame = [[parameter objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [parameter[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
#ifdef DEBUG_MODE
    // Keyboard Frame: {{0, 315}, {320, 253}}
    // Keyboard Frame: {{0, 127}, {568, 193}} (iOS 8)
    // Keyboard Frame: {{158, 0}, {162, 568}} (iOS 7)
    NSLog(@"Keyboard Frame: %@", NSStringFromCGRect(frame));
    
#endif
    
    UIScreen *screen = [UIScreen mainScreen];
    
    // Fixed auto change width and height on iOS8 issue.
    CGFloat screenHeightOnLandcape = (CGRectGetWidth(screen.bounds) < CGRectGetHeight(screen.bounds)) ? CGRectGetWidth(screen.bounds) : CGRectGetHeight(screen.bounds) ;
    CGFloat keyboardHeightOnLandcape = (CGRectGetWidth(frame) < CGRectGetHeight(frame)) ? CGRectGetWidth(frame) : CGRectGetHeight(frame);
    
    // Keyboard offset value is screen height reduce keyboard height at portrait, when landscape value is keyboard width.
    CGFloat keyboardOffset = isPortrait ? CGRectGetHeight(screen.bounds) - CGRectGetHeight(frame) : screenHeightOnLandcape - keyboardHeightOnLandcape;
    CGPoint newCenter = [self calculateNewCenterWithKeyboardOffset:keyboardOffset];
    
    [UIView animateWithDuration:duration animations:^{
        [self setCenter:newCenter];
    }];
}

- (CGPoint)calculateNewCenterWithKeyboardOffset:(CGFloat)keyboardOffset
{
    UIApplication *application = [UIApplication sharedApplication];
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(application.statusBarOrientation);
    UIInterfaceOrientation orientation = application.statusBarOrientation;
    
    CGFloat currentBottom = isPortrait ? CGRectGetMaxY(self.frame) : CGRectGetMaxX(self.frame);
    DTBackgroundView *backgroundView = [DTBackgroundView currentBackground];
    CGPoint center = CGPointMake(CGRectGetMidX(backgroundView.bounds), CGRectGetMidY(backgroundView.bounds));
    
    if (!CGPointEqualToPoint(self.center, center)) {
        // currentBottom add the device screen center reduce current alert view center offset value.
        currentBottom += isPortrait ? center.y - self.center.y : center.x - self.center.x;
    }
    
#ifdef DEBUG_MODE
    
    NSLog(@"Current Bottom: %.2f", currentBottom);
    NSLog(@"Keyboard Bottom: %.2f", keyboardOffset);
    
#endif
    
    if (currentBottom >= keyboardOffset) {
        // Set self botton higher than keyboard top more.
        CGFloat delta = currentBottom - keyboardOffset + 45.0f;
        
        // Portrait
        if (orientation == UIInterfaceOrientationPortrait) {
            center.y -= delta;
        }
        
        // Upside Down
        if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            center.y += delta;
        }
        
        /* Reduce the interval between keyboard and alert view on landscape view */
        
        // Right Landscape
        if (orientation == UIInterfaceOrientationLandscapeRight) {
            center.x += delta - 25.0f;
        }
        
        // Left Landscape
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            center.x -= delta - 25.0f;
        }
    }
    
#ifdef DEBUG_MODE
    
    UIScreen *screen = [UIScreen mainScreen];
    CGPoint screenCenter = (isPortrait) ? CGPointMake(CGRectGetMidX(screen.bounds), CGRectGetMidY(screen.bounds)) : CGPointMake(CGRectGetMidY(screen.bounds), CGRectGetMidX(screen.bounds)) ;
    
    NSLog(@"Screen Center: %@", NSStringFromCGPoint(screenCenter));
    NSLog(@"New Center: %@", NSStringFromCGPoint(center));
    
#endif
    
    return center;
}

#pragma mark Rotation Notification Methods

- (CGFloat)angleForCurrentOrientation {
    
	// Calculate a rotation transform that matches the current interface orientation.
	CGFloat angle = 0.0f;
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
	if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        angle = M_PI;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        angle = -M_PI_2;
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        angle = M_PI_2;
    }
    
	return angle;
}

- (void)didRotationHandle:(NSNotification *)sender
{
    CGFloat angle = [self angleForCurrentOrientation];
    
    [self.layer removeAnimationForKey:kAnimationShake];
    [self.layer setTransform:CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f)];
}

#pragma mark - Motion Effect Setting

- (void)setMotionEffect
{
    if (![self respondsToSelector:@selector(setMotionEffects:)]) {
        return;
    }
    
    UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                                         type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    [xAxis setMinimumRelativeValue:@(-kMotionEffectExtent)];
    [xAxis setMaximumRelativeValue:@(kMotionEffectExtent)];
    
    UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                                         type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    [yAxis setMinimumRelativeValue:@(-kMotionEffectExtent)];
    [yAxis setMaximumRelativeValue:@(kMotionEffectExtent)];
    
    UIMotionEffectGroup *motionEffect = [UIMotionEffectGroup new];
    [motionEffect setMotionEffects:@[xAxis, yAxis]];
    
    DTRelease(xAxis);
    DTRelease(yAxis);
    
    [self addMotionEffect:motionEffect];
    
    DTRelease(motionEffect);
}

#pragma mark - Default Animation

#define transformScale(scale) [NSValue valueWithCATransform3D:[self transform3DScale:scale]]

- (CATransform3D)transform3DScale:(CGFloat)scale
{
    // Add scale on current transform.
    CATransform3D currentTransfrom = CATransform3DScale(self.layer.transform, scale, scale, 1.0f);
    
    return currentTransfrom;
}

#define transformTranslateX(translate) [NSValue valueWithCATransform3D:[self transform3DTranslateX:translate]]
#define transformTranslateY(translate) [NSValue valueWithCATransform3D:[self transform3DTranslateY:translate]]

- (CATransform3D)transform3DTranslateX:(CGFloat)translate
{
    // Add scale on current transform.
    CATransform3D currentTransfrom = CATransform3DTranslate(self.layer.transform, translate, 1.0f, 1.0f);
    
    return currentTransfrom;
}

- (CATransform3D)transform3DTranslateY:(CGFloat)translate
{
    // Add scale on current transform.
    CATransform3D currentTransfrom = CATransform3DTranslate(self.layer.transform, 1.0f, translate, 1.0f);
    
    return currentTransfrom;
}

- (CAKeyframeAnimation *)animationWithValues:(NSArray*)values times:(NSArray*)times duration:(CGFloat)duration {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    [animation setValues:values];
    [animation setKeyTimes:times];
    [animation setFillMode:kCAFillModeForwards];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [animation setRemovedOnCompletion:NO];
    [animation setDuration:duration];
    
    return animation;
}

- (CGFloat)getMoveLengthForHeight
{
    CGFloat moveLength;
    
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        moveLength = CGRectGetMidY([[DTBackgroundView currentBackground] bounds]) + CGRectGetMidY(self.bounds);
    } else {
        moveLength = CGRectGetMidX([[DTBackgroundView currentBackground] bounds]) + CGRectGetMidY(self.bounds);
    }
    
    return moveLength;
}

- (CGFloat)getMoveLengthForWidth
{
    CGFloat moveLength;
    
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        moveLength = CGRectGetMidX([[DTBackgroundView currentBackground] bounds]) + CGRectGetMidX(self.bounds);
    } else {
        moveLength = CGRectGetMidY([[DTBackgroundView currentBackground] bounds]) + CGRectGetMidX(self.bounds);
    }
    
    return moveLength;
}

#pragma mark Show Animations

- (CAAnimation *)defaultShowsAnimation
{
    NSArray *frameValues = @[transformScale(0.1f), transformScale(1.15f), transformScale(0.9f), transformScale(1.0f)];
    NSArray *frameTimes = @[@(0.0f), @(0.5f), @(0.9f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.2f];
}

- (CAAnimation *)sildeInTopAnimation
{
    NSArray *frameValues = @[transformTranslateY(-300.0f), transformTranslateY(0.0f)];
    NSArray *frameTimes = @[@(0.0f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.2f];
}

- (CAAnimation *)sildeInBottomAnimation
{
    NSArray *frameValues = @[transformTranslateY(300.0f), transformTranslateY(0.0f)];
    NSArray *frameTimes = @[@(0.0f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.2f];
}

- (CAAnimation *)sildeInLeftAnimation
{
    NSArray *frameValues = @[transformTranslateX(-300.0f), transformTranslateX(0.0f)];
    NSArray *frameTimes = @[@(0.0f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.2f];
}

- (CAAnimation *)sildeInRightAnimation
{
    NSArray *frameValues = @[transformTranslateX(300.0f), transformTranslateX(0.0f)];
    NSArray *frameTimes = @[@(0.0f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.2f];
}

#pragma mark Dismiss Animations

- (CAAnimation *)defaultDismissAnimation
{
    NSArray *frameValues = @[transformScale(1.0f), transformScale(0.95f), transformScale(0.5f)];
    NSArray *frameTimes = @[@(0.0f), @(0.5f), @(1.0f)];
    
    CAKeyframeAnimation *animation = [self animationWithValues:frameValues times:frameTimes duration:0.2f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    
    return animation;
}

- (CAAnimation *)sildeOutTopAnimation
{
    CGFloat moveLength = [self getMoveLengthForHeight];
    
    NSArray *frameValues = @[transformTranslateY(0.0f), transformTranslateY(-moveLength)];
    NSArray *frameTimes = @[@(0.0f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.2f];
}

- (CAAnimation *)sildeOutBottomAnimation
{
    CGFloat moveLength = [self getMoveLengthForHeight];
    
    NSArray *frameValues = @[transformTranslateY(0.0f), transformTranslateY(moveLength)];
    NSArray *frameTimes = @[@(0.0f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.2f];
}

- (CAAnimation *)sildeOutLeftAnimation
{
    CGFloat moveLength = [self getMoveLengthForWidth];
    
    NSArray *frameValues = @[transformTranslateX(0.0f), transformTranslateX(-moveLength)];
    NSArray *frameTimes = @[@(0.0f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.2f];
}

- (CAAnimation *)sildeOutRightAnimation
{
    CGFloat moveLength = [self getMoveLengthForWidth];
    
    NSArray *frameValues = @[transformTranslateX(0.0f), transformTranslateX(moveLength)];
    NSArray *frameTimes = @[@(0.0f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.2f];
}

#pragma mark Shake Animations

- (CAAnimation *)shakeAnimation
{
    NSArray *frameValues = @[transformTranslateX(10.0f), transformTranslateX(-10.0f), transformTranslateX(6.0f), transformTranslateX(-6.0f),transformTranslateX(3.0f), transformTranslateX(-3.0f), transformTranslateX(0.0f)];
    NSArray *frameTimes = @[@(0.14f), @(0.28f), @(0.42f), @(0.57f), @(0.71f), @(0.85f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.5f];
}

@end
