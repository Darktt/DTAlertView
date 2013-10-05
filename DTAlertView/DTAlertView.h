//
//  DTAlertView.h
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

#import <Foundation/Foundation.h>
#import "DTProgressStatus.h"

#if __has_feature(objc_instancetype)
#define DTInstancetype instancetype
#else
#define DTInstancetype id
#endif

@class DTAlertView;
@protocol DTAlertViewDelegate;

// enumerations
typedef NS_ENUM(NSInteger, DTAlertViewMode) {
    DTAlertViewModeNormal = 0,
    DTAlertViewModeTextInput,
    DTAlertViewModeProgress,
    DTAlertViewModeDuoProgress,
    };

#if __has_feature(blocks)

// Blocks
typedef void (^DTAlertViewButtonClickedBlock) (DTAlertView *alertView, NSUInteger buttonIndex, NSUInteger cancelButtonIndex);
typedef void (^DTAlertViewAnimationBlock) (void);
typedef void (^DTAlertViewTextDidChangeBlock)(DTAlertView *alertView, NSString *text);

#endif

@interface DTAlertView : UIView

// Default settings
@property (nonatomic, assign) id<DTAlertViewDelegate> delegate;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, assign) DTAlertViewMode alertViewMode; // Default is DTAlertViewModeNormal.
@property (nonatomic, readonly) NSInteger cancelButtonIndex; // Default is -1 if cancel button title not set or 0.
@property (nonatomic, readonly, getter = isVisible) BOOL visible; // Check alert view is visible.
@property (nonatomic, readonly) NSString *clickedButtonTitle; // Defalt is nil, when alert view clicked, value is the clicked button title.

// View settings
@property (assign) CGFloat cornerRadius; // Defauls value 0.0, when shown is 25.0 if value not changed.
@property (nonatomic, retain) UIView *backgroundView; // Default is nil.

/* Default is nil on not shown. inital it at shown.
 Only can get it when DTAlertViewMode is DTAlertViewModeTextInput. */
@property (nonatomic, readonly) UITextField *textField;

/* 
    Set all pregress bar tint color, default is nil.
    Only can be set it when DTAlertViewMode is DTAlertViewModeProgress and DTAlertViewModeDuoProgress.
 */
@property (nonatomic, retain) UIColor *progressBarColor;

// Initial for class method with delegate.
+ (DTInstancetype)alertViewWithTitle:(NSString *)title message:(NSString *)message delegate:(id<DTAlertViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

// Initial method with delegate.
- (DTInstancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<DTAlertViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

#if __has_feature(blocks)

// Initial for class method with block.
+ (DTInstancetype)alertViewUseBlock:(DTAlertViewButtonClickedBlock)block title:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

// Initial method with block.
- (DTInstancetype)initWithBlock:(DTAlertViewButtonClickedBlock)block title:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

#endif

// Set iOS7 style blur background color
- (void)setBlurBackgroundWithColor:(UIColor *)color alpha:(CGFloat)alpha NS_AVAILABLE_IOS(7_0);

// Set positive button enable or disable. Default is Enable.
- (void)setPositiveButtonEnable:(BOOL)enable;

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

#if __has_feature(blocks)

// Set block to notify when text in textfield is changed.
- (void)setTextFieldDidChangeBlock:(DTAlertViewTextDidChangeBlock)textBlock;

#endif

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

#endif

@end

@protocol DTAlertViewDelegate  <NSObject>

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
