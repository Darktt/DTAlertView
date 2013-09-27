//
//  DTAlertView.m
//  DTAlertViewDemo
//
//  Created by Darktt on 13/9/17.
//  Copyright (c) 2013 Darktt. All rights reserved.
//

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

// Tags
#define kTitleLableTag          2001
#define kMessageLabelTag        2002
#define kFirstProgressTag       2003
#define kSecondProgressTag      2004
#define kProgressStatusTag      2005
#define kPercentageTag          2006

#define kButtonBGViewTag        2099

@interface DTAlertView () 
{
    id<DTAlertViewDelgate> _delegate;
    
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
    
    // Button Titles
    NSString *_cancelButtonTitle;
    NSInteger _cancelButtonIndex;
    NSString *_positiveButtonTitle;
    
    // Back ground
    UIView *_backgroundView;
    UIToolbar *_blurToolbar;
    
    BOOL _visible;
}

- (UIWindow *)keyWindow;

@end

@implementation DTAlertView

+ (DTInstancetype)alertViewWithTitle:(NSString *)title message:(NSString *)message delegate:(id<DTAlertViewDelgate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle
{
    DTAlertView *alertView = [[DTAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:delegate
                                              cancelButtonTitle:cancelButtonTitle
                                            positiveButtonTitle:positiveButtonTitle];
    
    return DTAutorelease(alertView);
}

- (DTInstancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<DTAlertViewDelgate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle
{
    self = [super init];
    
    if (self == nil) return nil;
    
    _delegate = delegate;
    _clickedBlock = nil;
    
    _title = DTRetain(title);
    _message = DTRetain(message);
    
    _cancelButtonTitle = DTRetain(cancelButtonTitle);
    _positiveButtonTitle = DTRetain(positiveButtonTitle);
    
    _backgroundView = nil;
    _visible = NO;
    
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
    
    _backgroundView = nil;
    _visible = NO;
    
    [self setCancelButtonIndex];

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
#ifdef DEBUG_MODE
    NSLog(@"%s", __func__);
    NSLog(@"subviews %@", self.subviews);
#endif
    if (_blurToolbar != nil) {
        [_blurToolbar setFrame:self.bounds];
    }
    
}

#ifdef ARC_MODE_NOT_USED

- (void)dealloc
{
    if (_clickedBlock != nil) {
        DTBlockRelease(_clickedBlock);
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
    
    if (_blurToolbar != nil) {
        [_blurToolbar release];
        _blurToolbar = nil;
    }
    
    if (_textField != nil) {
        [_textField release];
        _textField = nil;
    }
    
    if (_textChangeBlock != nil) {
        DTBlockRelease(_textChangeBlock);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

#endif

#pragma mark - Property Methods

- (void)setDelegate:(id<DTAlertViewDelgate>)delegate
{
    if (_clickedBlock != nil) {
        
        NSLog(@"%s-%d:Block is set, can't use delegate.", __func__, __LINE__);
        
        return;
    }
    
    _delegate = delegate;
}

- (id<DTAlertViewDelgate>)delegate
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
    return nil;
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

#pragma mark - Instance Methods

#pragma mark Blur Background

- (void)setBlurBackgroundWithColor:(UIColor *)color alpha:(CGFloat)alpha
{
    [self setClipsToBounds:YES];
    
    if (_blurToolbar == nil) {
        // Add alpha into color
        color = [color colorWithAlphaComponent:alpha];
        
        // Set blur use toolBar create it.
        _blurToolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        [_blurToolbar setBarTintColor:color];
        
        [self.layer insertSublayer:_blurToolbar.layer atIndex:0];
    }
}

#pragma mark Set Label Under Progress view

- (void)setProgressStatus:(DTProgressStatus)status
{
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
    // Only set at DTAlertViewModeProgress and DTAlertViewModeDuoProgress
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
    if ([UIToolbar instancesRespondToSelector:@selector(setBarTintColor:)]) {
        [self setBlurBackgroundWithColor:nil alpha:0];
    } else if (self.backgroundColor == nil && _backgroundView == nil) {
        [self setClipsToBounds:YES];
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    
    if (self.layer.cornerRadius == 0.0f) {
        [self.layer setCornerRadius:5.0f];
    }
    
    [self setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
    [self setFrame:CGRectMake(0, 0, 270, 270)];
    
    UIWindow *window = [self keyWindow];
    [self setViews];
    
    [self setCenter:window.center];
    
    [window addSubview:self];
    
    [self.layer addAnimation:[self defaultShowsAnimation] forKey:@"popup"];
    
    [self performSelector:@selector(showsCompletion) withObject:nil afterDelay:0.25];
}

- (void)showsCompletion
{
    _visible = YES;
}

- (void)showWithAnimationBlock:(DTAlertViewAnimationBlock)animationBlock
{
    if ([UIToolbar instancesRespondToSelector:@selector(setBarTintColor:)]) {
        [self setBlurBackgroundWithColor:nil alpha:0];
    } else if (self.backgroundColor == nil && _backgroundView == nil) {
        [self setClipsToBounds:YES];
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    
    if (self.layer.cornerRadius == 0.0f) {
        [self.layer setCornerRadius:5.0f];
    }
    
    [self setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
    
    CGRect selfFrame = self.frame;
    selfFrame.size = CGSizeMake(270, 270);
    
    [self setFrame:selfFrame];
    [self setViews];
    
    UIWindow *window = [self keyWindow];
    [window addSubview:self];
    
    [UIView animateWithDuration:0.3f
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
    if (_delegate != nil && [_delegate respondsToSelector:@selector(alertViewWillDismiss:)]) {
        [_delegate alertViewWillDismiss:self];
    }
    
    [self.layer addAnimation:[self defaultDismissAnimation] forKey:@"popup"];
    
    [self performSelector:@selector(dismissCompletion) withObject:nil afterDelay:0.4f];
}

- (void)dismissCompletion
{
    [self removeFromSuperview];
    
    _visible = NO;
    
    if (_delegate != nil && [_delegate respondsToSelector:@selector(alertViewDidDismiss:)]) {
        [_delegate alertViewDidDismiss:self];
    }
}

- (void)dismissWithAnimationBlock:(DTAlertViewAnimationBlock)animationBlock
{
    __block BOOL isDismiss = NO;
    
    if (_delegate != nil && [_delegate respondsToSelector:@selector(alertViewWillDismiss:)]) {
        [_delegate alertViewWillDismiss:self];
    }
    
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:animationBlock
                     completion:^(BOOL finished) {
                         
        [self removeFromSuperview];
        isDismiss = YES;
        
        _visible = NO;
        
        if (_delegate != nil && [_delegate respondsToSelector:@selector(alertViewDidDismiss:)]) {
            [_delegate alertViewDidDismiss:self];
        }
    }];
}

#pragma mark - Set Views

- (void)setViews
{
    ///MARK: Labels
    
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
        NSInteger times = ceil(messageLabel.frame.size.width / labelMaxWidth);
        [messageLabel setNumberOfLines:times];
        
        CGRect newFrame = messageLabel.frame;
        newFrame.size.width = labelMaxWidth;
        newFrame.size.height *= messageLabel.numberOfLines;
        
        [messageLabel setFrame:newFrame];
    }
    
    [messageLabel setCenter:CGPointMake(CGRectGetMidX(self.bounds), messageLabel.center.y)];
    
    [self addSubview:messageLabel];

#ifdef DEBUG_MODE
    
    [messageLabel setBackgroundColor:[UIColor greenColor]];
    NSLog(@"Message Label Frame: %@", NSStringFromCGRect(messageLabel.frame));
    
#endif
    
    ///MARK: Progress and label under the progress
    
    // Calculator buttons field rect.
    CGRect buttonsField = CGRectZero;
    buttonsField.size = CGSizeMake(self.frame.size.width, 45.0f);
    
    switch (_alertViewMode) {
            
        case DTAlertViewModeNormal:
            buttonsField.origin.y = CGRectGetMaxY(messageLabel.frame) + 20.0f;
            
            if (![self checkButtonTitleExist]) {
                [self resizeViewWithLastRect:buttonsField];
            }
            break;
            
        case DTAlertViewModeProgress:
        {
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
        case DTAlertViewModeTextInput:
        {
            _textField = [[UITextField alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(messageLabel.frame) + 10.0f, 260.0f, 30.0f)];
            [_textField setCenter:CGPointMake(CGRectGetMidX(self.bounds), _textField.center.y)];
            [_textField setBorderStyle:UITextBorderStyleRoundedRect];
            [_textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(textFieldDidBeginEditing:)
                                                         name:UIKeyboardWillShowNotification
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(textFieldDidEndEditing:)
                                                         name:UIKeyboardWillHideNotification
                                                       object:nil];
            
            [self addSubview:_textField];
            
#ifdef DEBUG_MODE
            NSLog(@"Textfield Frame: %@", NSStringFromCGRect(_textField.frame));
#endif
            buttonsField.origin.y = CGRectGetMaxY(_textField.frame) + 20.0f;
            
            if (![self checkButtonTitleExist]) {
                [self resizeViewWithLastRect:_textField.frame];
            }
            
        }
            break;
        default:
            break;
    }
    
#ifdef DEBUG_MODE
    NSLog(@"Button Field: %@", NSStringFromCGRect(buttonsField));
#endif
    
    ///MARK: Buttons
    
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

    if (![self checkButtonTitleExist]) {
        buttonWidth = buttonsField.size.width;
    } else {
        buttonWidth = buttonsField.size.width / 2 - 0.5f;
    }
    
    // Cancel Button
    if (_cancelButtonTitle != nil) {
        UIButton *cancelButton = [self setButtonWithTitle:_cancelButtonTitle];
        [cancelButton setTag:_cancelButtonIndex + 1];
        
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
        [positiveButton setTag:_cancelButtonIndex + 2];
        [positiveButton.titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
        
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

- (UILabel *)setLabelWithTitle:(NSString *)labelText
{
    UILabel *label = [[UILabel alloc] init];
    [label setText:labelText];
    [label setTextColor:[UIColor blackColor]];
    [label setTextAlignment:DTTextAlignmentCenter];
    [label setFont:[UIFont boldSystemFontOfSize:17.0f]];
    
    // Set lines of message text
    NSArray *linesOfTitle = [labelText componentsSeparatedByString:@"\n"];
    [label setNumberOfLines:linesOfTitle.count];
    
    // Set title label position and size
    [label sizeToFit];
    
    if (label.frame.size.width > (self.frame.size.width - 40.0f)) {
        NSInteger times = ceil(label.frame.size.width / (self.frame.size.width - 40.0f));
        [label setNumberOfLines:times];
        
        CGRect newFrame = label.frame;
        newFrame.size.width = self.frame.size.width - 40.0f;
        newFrame.size.height *= label.numberOfLines;
        
        [label setFrame:newFrame];
    }
    
    return DTAutorelease(label);
}

- (UIProgressView *)setProgressViewWithFrame:(CGRect)frame
{
    UIProgressView *progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
//    [progress setProgressTintColor:[UIColor greenColor]];
    [progress setFrame:frame];
    
    return DTAutorelease(progress);
}

- (UIButton *)setButtonWithTitle:(NSString *)buttonTitle
{
    UIColor *buttonColor = [UIColor whiteColor];
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
    
    UIWindow *window = [self keyWindow];
    [self setCenter:window.center];
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

#define transform(x, y, z) [NSValue valueWithCATransform3D:CATransform3DMakeScale(x, y, z)]

- (CAAnimation *)defaultShowsAnimation
{
    NSArray *frameValues = @[transform(0.1f, 0.1f, 0.1f), transform(1.15f, 1.15f, 1.15f), transform(0.9f, 0.9f, 0.9f), transform(1.0f, 1.0f, 1.0f)];
    NSArray *frameTimes = @[@(0.0f), @(0.5f), @(0.9f), @(1.0f)];
    return [self animationWithValues:frameValues times:frameTimes duration:0.4f];
}

- (CAAnimation *)defaultDismissAnimation
{
    NSArray *frameValues = @[transform(1.0f, 1.0f, 1.0f), transform(0.5f, 0.5f, 0.5f), transform(0.0f, 0.0f, 0.0f)];
    NSArray *frameTimes = @[@(0.0f), @(0.3f), @(1.0f)];
    CAKeyframeAnimation *animation = [self animationWithValues:frameValues times:frameTimes duration:0.25f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    
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

#pragma mark - Get Key Window

- (UIWindow *)keyWindow
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    if (window.subviews.count > 0) {
        return window.subviews[0];
    }
    
    return window;
}

#pragma mark - UI Action event
- (void)textFieldDidChangeBlock:(DTAlertViewTextDidChangeBlock)textBlock
{
    _textChangeBlock = DTBlockCopy(textBlock);
}

- (void)textFieldDidBeginEditing:(NSNotification *)notification
{
    ///TODO: Begin edit text field
    NSDictionary *params = (NSDictionary *)notification.userInfo;
    CGRect frame = [[params objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGFloat keyboardOriginY = frame.origin.y;
    CGFloat currentBottomY = CGRectGetMaxY(self.frame);
    
    if (currentBottomY >= keyboardOriginY) {
        // Set self botton higher than keyboard top more
        CGFloat deltaY = currentBottomY - keyboardOriginY;
        [UIView animateWithDuration:0.3f animations:^{
            [self setCenter:CGPointMake(self.center.x, self.center.y - (deltaY + 55.0f))];
        }];
    }
    
}

- (void)textFieldDidEndEditing:(NSNotification *)notification
{
    ///TODO: End of editing
}

- (void)textFieldDidChange:(id)sender
{
    /* Support Block at first priority */
    if (_textChangeBlock != nil) {
        _textChangeBlock(self, _textField.text);
        return;
    }
    /* If block is nil, then set delegate */
    if ([_delegate respondsToSelector:@selector(alertViewTextDidChanged:)]) {
        [_delegate alertViewTextDidChanged:self];
    }
}

@end