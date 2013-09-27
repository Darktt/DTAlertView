//
//  DTAlertView.h
//  DTAlertViewDemo
//
//  Created by Darktt on 13/9/17.
//  Copyright (c) 2013 Darktt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTProgressStatus.h"

#if __has_feature(objc_instancetype)
#define DTInstancetype instancetype
#else
#define DTInstancetype id
#endif

@class DTAlertView;
@protocol DTAlertViewDelgate;

// enumerations
typedef NS_ENUM(NSInteger, DTAlertViewMode) {
    DTAlertViewModeNormal = 0,
    DTAlertViewModeProgress,
    DTAlertViewModeDuoProgress,
    DTAlertViewModeTextInput
    };

#if __has_feature(blocks)

// Blocks
typedef void (^DTAlertViewButtonClickedBlock) (DTAlertView *alertView, NSUInteger buttonIndex, NSUInteger cancelButtonIndex);
typedef void (^DTAlertViewAnimationBlock) (void);
typedef void (^DTAlertViewTextDidChangeBlock)(DTAlertView *alertView, NSString *text);

#endif

@interface DTAlertView : UIView

// Default settings
@property (nonatomic, assign) id<DTAlertViewDelgate> delegate;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, assign) DTAlertViewMode alertViewMode; // Default is DTAlertViewModeNormal.
@property (nonatomic, readonly) NSInteger cancelButtonIndex; // Default is -1 if cancel button title not set or 0.
@property (nonatomic, readonly, getter = isVisible) BOOL visible; // Check alert view is visible.
@property (nonatomic, readonly) NSString *clickedButtonTitle; // Defalt is nil, when alert view clicked, value is the clicked button title.

// Views
@property (assign) CGFloat cornerRadius; // Defauls value 0.0, when showed is 25.0 if value not changed.
@property (nonatomic, retain) UIView *backgroundView; // Default is nil.
@property (nonatomic, readonly) UITextField *textField; // Default is nil. Only can be set when DTAlertViewMode is DTAlertViewModeTextInput

// Initial for class method with delegate.
+ (DTInstancetype)alertViewWithTitle:(NSString *)title message:(NSString *)message delegate:(id<DTAlertViewDelgate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

// Initial method with delegate.
- (DTInstancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<DTAlertViewDelgate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

#if __has_feature(blocks)

// Initial for class method with block.
+ (DTInstancetype)alertViewUseBlock:(DTAlertViewButtonClickedBlock)block title:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

// Initial method with block.
- (DTInstancetype)initWithBlock:(DTAlertViewButtonClickedBlock)block title:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

#endif

// Set iOS7 style blur background color
- (void)setBlurBackgroundWithColor:(UIColor *)color alpha:(CGFloat)alpha NS_AVAILABLE_IOS(7_0);

/* 
 Adjust the current progress status at DTAlertViewModeDuoProgress mode,
 first (top) progress view's progress will adjust by this receiver at DTAlertViewModeDuoProgress mode.
 */
- (void)setProgressStatus:(DTProgressStatus)status;

/*
 Adjust the current percentage at DTAlertViewModeNormal and DTAlertViewModeDuoProgress mode.
 Percentage show under porgress view at DTAlertViewModeNormal or under second (bottom) progress view at DTAlertViewModeDuoProgress.
 Progress view's (upper this percentage) progress will adjust by this receiver.
 
 This value represented a floating-point value between 0.0 and 1.0, inclusive, 
 where 1.0 indicates the completion of the task. The default value is 0.0. 
 Values less than 0.0 and greater than 1.0 are pinned to those limits.
 */
- (void)setPercentage:(CGFloat)percentage;

/* 
 * Shows *
 */
// Shows popup alert with default animation.
- (void)show;

#if __has_feature(blocks)

// Popup alert with custom animation.
- (void)showWithAnimationBlock:(DTAlertViewAnimationBlock)animationBlock;

#endif

/* 
 * Dismiss *
 */
// Hide alert with default animation.
- (void)dismiss;

#if __has_feature(blocks)

// Hide alert with custom animation.
- (void)dismissWithAnimationBlock:(DTAlertViewAnimationBlock)animationBlock;

// Notify when text in textfield is changed
- (void)textFieldDidChangeBlock:(DTAlertViewTextDidChangeBlock)textBlock;

#endif


@end

@protocol DTAlertViewDelgate <NSObject>

// This method responds what button clicked in alett view.
- (void)alertView:(DTAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@optional

// Alert view will dismiss.
- (void)alertViewWillDismiss:(DTAlertView *)alertView;

// Alert view did dismiss.
- (void)alertViewDidDismiss:(DTAlertView *)alertView;

// Text in AlertView did change.
- (void)alertViewTextDidChanged:(DTAlertView *)alertView;

@end
