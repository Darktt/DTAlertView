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

#pragma mark - Implement DTBackgroundView Class

@interface DTBackgroundView : UIView
{
    UIWindow *alertWindow;
    UIView *keyView;
}

+ (DTInstancetype)currentBackground;

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

- (id)init
{
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self == nil) return nil;
    
    [self setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.5f]];
    
    alertWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [alertWindow setWindowLevel:UIWindowLevelAlert];
    [alertWindow setBackgroundColor:[UIColor clearColor]];
    [alertWindow addSubview:self];
    [alertWindow makeKeyAndVisible];
    
    return self;
}

- (void)setHidden:(BOOL)hidden
{
    if (self.subviews.count > 0) {
        hidden = NO;
    }
    
    [super setHidden:hidden];
    
    [alertWindow setHidden:hidden];
    
    if (hidden) {
        [alertWindow resignKeyWindow];
    } else {
        [alertWindow makeKeyWindow];
    }
}

@end

#pragma mark - Implement DTAlertView Class

@interface DTAlertView ()
{
    id<DTAlertViewDelegate> _delegate;
    
    DTAlertViewButtonClickedBlock _clickedBlock;
    DTAlertViewTextDidChangeBlock _textChangeBlock;
    NSString *_title;
    NSString *_message;
    DTAlertViewMode _alertViewMode;
    
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
    
    // Back ground
    UIView *_backgroundView;
    UIToolbar *_blurToolbar;
    
    BOOL _visible;
    BOOL _keyboardIsShown;
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
    
    _keyboardIsShown = NO;
    
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
    
    _delegate = nil;
    _clickedBlock = DTBlockCopy(block);
    
    _title = DTRetain(title);
    _message = DTRetain(message);
    
    _alertViewMode = DTAlertViewModeNormal;
    
    _cancelButtonTitle = DTRetain(cancelButtonTitle);
    _positiveButtonTitle = DTRetain(positiveButtonTitle);
    _positiveButtonEnable = YES;
    
    _backgroundView = nil;
    _visible = NO;
    _progressTintColor = [[UIColor alloc] initWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
    
    _keyboardIsShown = NO;
    
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
}

- (DTAlertViewMode)alertViewMode
{
    return _alertViewMode;
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
        
        DTRetain(_backgroundView);
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

- (void)setProgressBarColor:(UIColor *)progressBarColor
{
    // Only set at DTAlertViewModeProgress and DTAlertViewModeDuoProgress
    if (_alertViewMode != DTAlertViewModeProgress && _alertViewMode != DTAlertViewModeDuoProgress) {
        return;
    }
    
    if (_progressTintColor != nil) {
        [_progressTintColor release];
    }
    
    _progressTintColor = DTRetain(progressBarColor);
    
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
    if (_blurToolbar == nil) {
        // Add alpha into color
        color = [color colorWithAlphaComponent:alpha];
        
        // Set blur use toolBar create it.
        _blurToolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        [_blurToolbar setBarTintColor:color];
        
        [self.layer insertSublayer:_blurToolbar.layer atIndex:0];
    }
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
    [self setClipsToBounds:YES];
    
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
    [backgroundView setAlpha:1.0f];
    [backgroundView setHidden:NO];
    
    [self setCenter:backgroundView.center];
    [backgroundView addSubview:self];
    
    CAAnimation *showsAnimation = [self defaultShowsAnimation];
    [self.layer addAnimation:showsAnimation forKey:@"popup"];
    
    [self performSelector:@selector(showsCompletion) withObject:nil afterDelay:showsAnimation.duration];
    
    // Receive notification for handle rotate issue
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotationHandle:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)showsCompletion
{
    _visible = YES;
}

- (void)showWithAnimationBlock:(DTAlertViewAnimationBlock)animationBlock
{
    [self setClipsToBounds:YES];
    
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
    
    CGRect selfFrame = self.frame;
    selfFrame.size = CGSizeMake(270, 270);
    
    [self setFrame:selfFrame];
    [self setViews];
    
    // Rotate self befoure show.
    CGFloat angle = [self angleForCurrentOrientation];
    [self setTransform:CGAffineTransformMakeRotation(angle)];
    
    // Background of alert view
    DTBackgroundView *backgroundView = [DTBackgroundView currentBackground];
    [backgroundView setHidden:NO];
    
//    [self setCenter:backgroundView.center];
    [backgroundView addSubview:self];
    
    // Receive notification for handle rotate issue
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotationHandle:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    [UIView animateWithDuration:10.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:animationBlock
                     completion:^(BOOL finished) {
                         
        _visible = YES;
    }];
}

#pragma mark Dismiss Alert View Method

- (void)dismiss
{
    // Remove notification for rotate
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    if (_delegate != nil && [_delegate respondsToSelector:@selector(alertViewWillDismiss:)]) {
        [_delegate alertViewWillDismiss:self];
    }
    
    if (_keyboardIsShown) {
        [_textField resignFirstResponder];
        
        // Remove notification
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    }
    
    CAAnimation *dismissAnimation = [self defaultDismissAnimation];
    
    [self.layer removeAllAnimations];
    [self.layer addAnimation:dismissAnimation forKey:@"dismiss"];
    
    [self performSelector:@selector(dismissCompletion) withObject:nil afterDelay:dismissAnimation.duration];
}

- (void)dismissCompletion
{
    // Dismiss self
    [self removeFromSuperview];
    
    [UIView animateWithDuration:0.2 animations:^{
        [[DTBackgroundView currentBackground] setAlpha:0.0f];
    } completion:^(BOOL finished) {
        [[DTBackgroundView currentBackground] setHidden:YES];
    }];
    
    // Remove dismiss animation
    [self.layer removeAllAnimations];
    
    _visible = NO;
    
    if (_delegate != nil && [_delegate respondsToSelector:@selector(alertViewDidDismiss:)]) {
        [_delegate alertViewDidDismiss:self];
    }
}

- (void)dismissWithAnimationBlock:(DTAlertViewAnimationBlock)animationBlock
{
    // Remove notification for rotate
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    if (_delegate != nil && [_delegate respondsToSelector:@selector(alertViewWillDismiss:)]) {
        [_delegate alertViewWillDismiss:self];
    }
    
    if (_keyboardIsShown) {
        [_textField resignFirstResponder];
        
        // Remove notification
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    }
    
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:animationBlock
                     completion:^(BOOL finished) {
                         
        // Dismiss self
        [self removeFromSuperview];
        [[DTBackgroundView currentBackground] setHidden:YES];

        _visible = NO;

        if (_delegate != nil && [_delegate respondsToSelector:@selector(alertViewDidDismiss:)]) {
         [_delegate alertViewDidDismiss:self];
        }
    }];
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
    
    // Title
    UILabel *titleLabel = [[UILabel alloc] init];
    [titleLabel setText:_title];
    [titleLabel setTextColor:[UIColor blackColor]];
    [titleLabel setTextAlignment:DTTextAlignmentCenter];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [titleLabel setTag:kTitleLableTag];
    
    // Set lines of message text.
    NSArray *linesOfTitle = [_title componentsSeparatedByString:@"\n"];
    [titleLabel setNumberOfLines:linesOfTitle.count];
    
    // Set title label position and size.
    [titleLabel sizeToFit];
    
    // When title length too long, calculator new frame.
    CGFloat labelMaxWidth = self.frame.size.width - 10.0f;
    
    if (titleLabel.frame.size.width > labelMaxWidth) {
        NSInteger times = ceil(titleLabel.frame.size.width / labelMaxWidth);
        [titleLabel setNumberOfLines:times];
        
        CGRect newFrame = titleLabel.frame;
        newFrame.size.width = labelMaxWidth;
        newFrame.size.height *= titleLabel.numberOfLines;
        
        [titleLabel setFrame:newFrame];
    }
    
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
    NSArray *linesOfMessage = [_message componentsSeparatedByString:@"\n"];
    [messageLabel setNumberOfLines:linesOfMessage.count];
    
    // Set message label position and size.
    CGRect messageRect = CGRectZero;
    messageRect.origin.y = CGRectGetMaxY(titleLabel.frame) + 5.0f;
    
    [messageLabel setFrame:messageRect];
    [messageLabel sizeToFit];
    
    // When message length too long, calculator new frame.
    if (messageLabel.frame.size.width > labelMaxWidth) {
        NSInteger multiple = ceil(messageLabel.frame.size.width / labelMaxWidth);
        
        // multiple add current number of line, If it great of 1.
        multiple += (messageLabel.numberOfLines == 1) ? 0 : messageLabel.numberOfLines;
        
        CGRect newFrame = messageLabel.frame;
        newFrame.size.width = labelMaxWidth;
        
        // new height = old height * ( multiple / current number of line )
        newFrame.size.height *= (multiple / messageLabel.numberOfLines);
        
        [messageLabel setNumberOfLines:multiple];
        [messageLabel setFrame:newFrame];
    }
    
    [messageLabel setCenter:CGPointMake(CGRectGetMidX(self.bounds), messageLabel.center.y)];
    
    [self addSubview:messageLabel];

#ifdef DEBUG_MODE
    
    [messageLabel setBackgroundColor:[UIColor greenColor]];
    NSLog(@"Message Label Frame: %@", NSStringFromCGRect(messageLabel.frame));
    NSLog(@"Message Max Y Positiopn: %.1f", CGRectGetMaxY(messageLabel.frame));
    
#endif
    
    // Calculator buttons field rectangle.
    CGRect buttonsField = CGRectZero;
    buttonsField.size = CGSizeMake(self.frame.size.width, 45.0f);
    
    switch (_alertViewMode) {
            
        case DTAlertViewModeNormal:
            buttonsField.origin.y = CGRectGetMaxY(messageLabel.frame) + 20.0f;
            
            if (![self checkButtonTitleExist]) {
                [self resizeViewWithLastRect:buttonsField];
            }
            break;
            
        case DTAlertViewModeTextInput:
        {
            //MARK: TextField
            _textField = [[UITextField alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(messageLabel.frame) + 10.0f, 260.0f, 30.0f)];
            [_textField setBorderStyle:UITextBorderStyleRoundedRect];
            [_textField addTarget:self action:@selector(textFieldDidBegin:) forControlEvents:UIControlEventEditingDidBegin];
            [_textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            [_textField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEndOnExit];
            
            [_textField setCenter:CGPointMake(CGRectGetMidX(self.bounds), _textField.center.y)];
            
            if ([_textField respondsToSelector:@selector(setTintColor:)]) {
                [_textField setTintColor:[UIColor blueColor]];
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
            UIProgressView *firstProgress = [self setProgressViewWithFrame:CGRectMake(0, CGRectGetMaxY(messageLabel.frame) + 10.0f, 260.0f, 2.0f)];
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
            UIProgressView *firstProgress = [self setProgressViewWithFrame:CGRectMake(0, CGRectGetMaxY(messageLabel.frame) + 10.0f, labelMaxWidth, 2.0f)];
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
    
    // Release Label
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
    
    UIColor *buttonTitleColor = [UIColor colorWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundColor:buttonColor];
    [button setTitle:buttonTitle forState:UIControlStateNormal];
    [button setTitleColor:buttonTitleColor forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [button setClipsToBounds:YES];
    
    return button;
}

- (BOOL)checkButtonTitleExist
{
    return (_cancelButtonTitle != nil || _positiveButtonTitle != nil);
}

- (void)resizeViewWithLastRect:(CGRect)lastRect
{
    CGRect selfFrame = self.frame;
    selfFrame.size.height = CGRectGetMaxY(lastRect);
    
    [self setFrame:selfFrame];
    
    DTBackgroundView *backgroundView = [DTBackgroundView currentBackground];
    [self setCenter:backgroundView.center];
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

#pragma mark - Button Action

- (IBAction)buttonClicked:(UIButton *)sender
{
    [self dismiss];
    _clickedButtonTitle = DTRetain([sender titleForState:UIControlStateNormal]);
    
    if (_clickedBlock != nil) {
        _clickedBlock(self, sender.tag - 1, _cancelButtonIndex);
        
        return;
    }
    
    if ([_delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [_delegate alertView:self clickedButtonAtIndex:sender.tag - 1];
        
        return;
    }
}

#pragma mark - TextField Action

- (IBAction)textFieldDidBegin:(id)sender
{
    // Receive notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidBeginEditing:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
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

- (IBAction)textFieldDidEndEditing:(NSNotification *)notification
{
    _keyboardIsShown = NO;
    
    [UIView animateWithDuration:0.25f animations:^{
        // Move current view to center
        UIView *backGround = [self superview];
        [self setCenter:backGround.center];
    } completion:^(BOOL finished) {
        // Remove notification
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    }];
}

#pragma mark - KeyBoard Notification Mesthods

- (CGPoint)calculateNewCenterWithKeyOffset:(CGFloat)keyboardOffset
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
    
    if (currentBottom >= keyboardOffset) {
        // Set self botton higher than keyboard top more.
        CGFloat delta = currentBottom - keyboardOffset + 45.0f;
        
        if (orientation == UIInterfaceOrientationPortrait) {
            center.y -= delta;
        }
        
        if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            center.y += delta;
        }
        
        if (orientation == UIInterfaceOrientationLandscapeRight) {
            center.x += delta;
        }
        
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            center.x -= delta;
        }
    }
    
    return center;
}

- (void)textFieldDidBeginEditing:(NSNotification *)notification
{
    _keyboardIsShown = YES;
    
    UIApplication *application = [UIApplication sharedApplication];
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(application.statusBarOrientation);
    
    NSDictionary *params = (NSDictionary *)notification.userInfo;
    
    CGRect frame = [[params objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [params[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    UIScreen *screen = [UIScreen mainScreen];
    // Keyboard offset value is screen height reduce keyboard height at portrait, when landscape value is keyboard width.
    CGFloat keyboardOffset = isPortrait ? CGRectGetHeight(screen.bounds) - CGRectGetHeight(frame) : CGRectGetWidth(screen.bounds) - CGRectGetWidth(frame);
    CGPoint newCenter = [self calculateNewCenterWithKeyOffset:keyboardOffset];
    
    [UIView animateWithDuration:duration animations:^{
        [self setCenter:newCenter];
    }];
}

#pragma mark - Set Cancel Button Index

- (void)setCancelButtonIndex
{
    if (_cancelButtonTitle == nil) {
        _cancelButtonIndex = -1;
        
        return;
    }
    
    _cancelButtonIndex = 0;
}

#pragma mark - Default Animation

#define transform(scale) [NSValue valueWithCATransform3D:[self transform3DScale:scale]]

- (CATransform3D)transform3DScale:(CGFloat)scale
{
    // Add scale on current transform.
    CATransform3D currentTransfrom = CATransform3DScale(self.layer.transform, scale, scale, 1.0f);
    
    return currentTransfrom;
}

- (CAAnimation *)defaultShowsAnimation
{
    NSArray *frameValues = @[transform(0.1f), transform(1.15f), transform(0.9f), transform(1.0f)];
    NSArray *frameTimes = @[@(0.0f), @(0.5f), @(0.9f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.4f];
}

- (CAAnimation *)defaultDismissAnimation
{
    NSArray *frameValues = @[transform(1.0f), transform(0.5f), transform(0.1f)];
    NSArray *frameTimes = @[@(0.0f), @(0.5f), @(1.0f)];
    
    CAKeyframeAnimation *animation = [self animationWithValues:frameValues times:frameTimes duration:0.25f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [animation setFillMode:kCAFillModeRemoved];
    
    return animation;
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

#pragma mark - Rotation Handler

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

- (void)rotationHandle:(NSNotification *)sender
{
    CGFloat angle = [self angleForCurrentOrientation];
    
    // Use the system rotation duration.
    CGFloat duration = [[UIApplication sharedApplication] statusBarOrientationAnimationDuration];
    
    // Egregious hax. iPad lies about its rotation duration.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        duration = 0.4f;
    }
    
    [self.layer removeAllAnimations];
    [self.layer setTransform:CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f)];
}

@end