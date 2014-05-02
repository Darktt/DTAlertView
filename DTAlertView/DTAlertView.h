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
/** The mode of display to user. */
typedef NS_ENUM(NSInteger, DTAlertViewMode) {
    /** Normal alert view, it's dafult mode. */
    DTAlertViewModeNormal = 0,
    
    /** Alert view with UITextField. */
    DTAlertViewModeTextInput,
    
    /** Alert view with Single UIProgressView. */
    DTAlertViewModeProgress,
    
    /** Alert view with Two UIProgressView. */
    DTAlertViewModeDuoProgress,
    };

/** Type of show or dismiss animations. */
typedef NS_ENUM(NSInteger, DTAlertViewAnimation) {
    /** Default animation. */
    DTAlertViewAnimationDefault = 0,
    
    /** The alert view slide to top side. */
    DTAlertViewAnimationSlideTop,
    
    /** The alert view slide to bottom side. */
    DTAlertViewAnimationSlideBottom,
    
    /** The alert view slide to left side. */
    DTAlertViewAnimationSlideLeft,
    
    /** The alert view slide to right side. */
    DTAlertViewAnimationSlideRight,
};

#if __has_feature(blocks)

// Blocks
typedef void (^DTAlertViewButtonClickedBlock) (DTAlertView *alertView, NSUInteger buttonIndex, NSUInteger cancelButtonIndex);
typedef void (^DTAlertViewTextDidChangeBlock) (DTAlertView *alertView, NSString *text);

#endif

/// Custom alert view solved the ios UIAlertView can't addSubview problem at iOS7.
@interface DTAlertView : UIView

// Default settings
/**
 * The receiver's delegate, If DTAlertViewButtonClickedBlock is setted, it will ignore the receiver value.
 *
 * @brief The DTAlertView delegate.
 *
 * @see DTAlertViewDelegate
 */
@property (nonatomic, assign) id<DTAlertViewDelegate> delegate;

/** @brief The alert view title. appears in the title bar. */
@property (nonatomic, retain) NSString *title;

/** @brief The alert view message, descriptive text more datails than title. */
@property (nonatomic, retain) NSString *message;

/** Default is DTAlertViewModeNormal.
 *
 * @brief The alert mode display to th user.
 *
 * @see DTAlertViewMode
 */
@property (nonatomic, assign) DTAlertViewMode alertViewMode;

/** Default is DTAlertViewAnimationDefault. 
 *
 * @brief The dismiss animetion, when button clicked.
 *
 * @see DTAlertViewAnimation
 */
@property (nonatomic, assign) DTAlertViewAnimation dismissAnimationWhenButtonClicked;

/** Default is -1 if cancelButtonTitle not set or 0.
 * @brief The button index of cancel button.
 *
 * @see alertViewWithTitle:message:delegate:cancelButtonTitle:positiveButtonTitle:
 * @see alertViewUseBlock:title:message:cancelButtonTitle:positiveButtonTitle:
 * @see initWithTitle:message:delegate:cancelButtonTitle:positiveButtonTitle:
 * @see initWithBlock:title:message:cancelButtonTitle:positiveButtonTitle:
 */
@property (nonatomic, readonly) NSInteger cancelButtonIndex;

/** @brief Check alert view is visible. */
@property (nonatomic, readonly, getter = isVisible) BOOL visible;

/** Defalt is nil, when alert view clicked, value is the clicked button title.
 *
 * @brief The button title of clicked button.
 */
@property (nonatomic, readonly) NSString *clickedButtonTitle;

// View settings
/** Defauls value 0.0, when shown is 5.0 if value not changed.
 *
 * @brief The corner radius dispaly in alert view background.
 */
@property (assign) CGFloat cornerRadius;

/** Default is nil. 
 *
 * @brief The background view display in alert view.
 */
@property (nonatomic, retain) UIView *backgroundView;

/** Default is nil on not shown. inital it at shown.<br/>
 * Only can get it when DTAlertViewMode is DTAlertViewModeTextInput.
 *
 * @brief The UITextField appears DTAlertViewModeTextInput.
 */
@property (nonatomic, readonly) UITextField *textField;

/** Default is blue (aka. iOS 7 default blue color).
 *
 * @brief Set all of button text color.
 */
@property (nonatomic, retain) UIColor *buttonTextColor;

/** Default is blue (aka. iOS 7 default blue color).<br/>
 * Only can be set it when DTAlertViewMode is DTAlertViewModeProgress and DTAlertViewModeDuoProgress.
 *
 * @brief Set all of UIProgressView progress bar tint color.
 */
@property (nonatomic, retain) UIColor *progressBarColor;

/** @brief Initial for class method with delegate.
 *
 * @param title The alert view title. appears in the title bar.
 * @param message The alert view message, descriptive text more datails than title.
 * @param delegate The receiver's delegate or nil if it doesn’t have a delegate.
 * @param cancelButtonTitle The title of cancel button or nil if there is no cancel button.
 * @param positiveButtonTitle The title of positive button or nil if there is no positive button.
 *
 * @return Newly initialized alert view.
 *
 * @see initWithTitle:message:delegate:cancelButtonTitle:positiveButtonTitle:
 * @see delegate
 * @see title
 * @see message
 */
+ (DTInstancetype)alertViewWithTitle:(NSString *)title message:(NSString *)message delegate:(id<DTAlertViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

/** @brief Initial method with delegate.
 *
 * @param title The alert view title. appears in the title bar.
 * @param message The alert view message, descriptive text more datails than title.
 * @param delegate The receiver's delegate or nil if it doesn’t have a delegate.
 * @param cancelButtonTitle The title of cancel button or nil if there is no cancel button.
 * @param positiveButtonTitle The title of positive button or nil if there is no positive button.
 *
 * @return Newly initialized alert view.
 *
 * @see alertViewWithTitle:message:delegate:cancelButtonTitle:positiveButtonTitle:
 * @see delegate
 * @see title
 * @see message
 */
- (DTInstancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<DTAlertViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

#if __has_feature(blocks)

/** @brief Initial for class method with block.
 *
 * @param block The DTAlertViewButtonClickedBlock block.
 * @param title The alert view title. appears in the title bar.
 * @param message The alert view message, descriptive text more datails than title.
 * @param cancelButtonTitle The title of cancel button or nil if there is no cancel button.
 * @param positiveButtonTitle The title of positive button or nil if there is no positive button.
 *
 * @return Newly initialized alert view.
 *
 * @see initWithBlock:title:message:cancelButtonTitle:positiveButtonTitle:
 * @see title
 * @see message
 */
+ (DTInstancetype)alertViewUseBlock:(DTAlertViewButtonClickedBlock)block title:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

/** @brief Initial method with block.
 *
 * @param block The DTAlertViewButtonClickedBlock block.
 * @param title The alert view title. appears in the title bar.
 * @param message The alert view message, descriptive text more datails than title.
 * @param cancelButtonTitle The title of cancel button or nil if there is no cancel button.
 * @param positiveButtonTitle The title of positive button or nil if there is no positive button.
 *
 * @return Newly initialized alert view.
 *
 * @see alertViewUseBlock:title:message:cancelButtonTitle:positiveButtonTitle:
 * @see title
 * @see message
 */
- (DTInstancetype)initWithBlock:(DTAlertViewButtonClickedBlock)block title:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle positiveButtonTitle:(NSString *)positiveButtonTitle;

#endif

/** @brief Set iOS7 style blur background color
 *
 * @param color The color of blur display color.
 * @param alpha The opacity value of the color object, specified as a value from 0.0 to 1.0.
 *
 * @warning This method only available iOS7.
 */
- (void)setBlurBackgroundWithColor:(UIColor *)color alpha:(CGFloat)alpha NS_AVAILABLE_IOS(7_0);

/** Default is Enable.
 * @brief Set positive button enable or disable.
 *
 * @param enable If NO the positive button will disable.
 */
- (void)setPositiveButtonEnable:(BOOL)enable;

/** @brief Adjust the current progress status at DTAlertViewModeDuoProgress mode,<br/>
 * first (top) progress view's progress will adjust by this receiver at DTAlertViewModeDuoProgress mode.
 * 
 * @param status The current status of the receiver.
 */
- (void)setProgressStatus:(DTProgressStatus)status;

/** @brief Adjust the current percentage at DTAlertViewModeNormal and DTAlertViewModeDuoProgress mode.<br/>
 * Percentage show under porgress view at DTAlertViewModeNormal or under second (bottom) progress view at DTAlertViewModeDuoProgress.<br/>
 * Progress view's (upper this percentage) progress will adjust by this receiver.
 *
 * @param percentage This value represented a floating-point value between 0.0 and 1.0, inclusive,<br/>
 * where 1.0 indicates the completion of the task. The default value is 0.0.<br/>
 * Values less than 0.0 and greater than 1.0 are pinned to those limits.
 */
- (void)setPercentage:(CGFloat)percentage;

#if __has_feature(blocks)

/** The method performs textField text change.<br/>
 * For example, if you want disable positive button on less 10 characters, edable on great 10 characters.
 *
 *     <code><pre>[alertView setTextFieldDidChangeBlock:^(DTAlertView *_alertView, NSString *text){
 *     &#9;[_alertView setPositiveButtonEnable:(text.length > 10)];
 *     }];</pre></code>
 *
 * @brief Set block to notify when text in textField is changed.
 *
 * @param textBlock A block containing the changes textFidle text did change. This is where you programmatically change setPositiveButtonEnable enable or disable and other.
 */
- (void)setTextFieldDidChangeBlock:(DTAlertViewTextDidChangeBlock)textBlock;

#endif

/* 
 * Shows *
 */
/// @brief Shows popup alert with default animation.
- (void)show;

/** See the descriptions of the constants of the DTAlertViewAnimation type for more information.
 * @brief Shows popup alert for input pasword with receiver animation and would not dissmiss when click button.</br>
 * Want to dismiss this alert to use dismiss or dismissWithAnimation: .
 *
 * @param animation A constant to define what animation will show alert view.
 */
- (void)showForPasswordInputWithAnimation:(DTAlertViewAnimation)animation;

/** See the descriptions of the constants of the DTAlertViewAnimation type for more information.
 * @brief Shows popup alert with receiver animation.
 *
 * @param animation A constant to define what animation will show alert view.
 */
- (void)showWithAnimation:(DTAlertViewAnimation)animation;

/*
 * Dismiss *
 */

/** @brief Hide all alert.
 *
 *  @return If Yes is succed hide all alert view, No is failed hide alert view or no alert view is shown.
 */
+ (BOOL)dismissAllAlertView;

/** @brief Hide filtered alert view via correspond the title.
 *
 * @param title The title to filter all of shown alert views.
 *
 * @return If <b>Yes</b> is succed hide all alert view, <b>No</b> is failed hide alert view or no alert view correspond the receive title.
 *
 * @see title
 */
+ (BOOL)dismissAlertViewViaTitle:(NSString *)title;

/** @brief Hide filtered alert view via correspond the message .
 *
 * @param message The message to filter all of shown alert views.
 *
 * @return If <b>Yes</b> is succed hide all alert view, <b>No</b> is failed hide alert view or no alert view correspond the receive message.
 *
 * @see message
 */
+ (BOOL)dismissAlertViewViaMessage:(NSString *)message;

/// @brief Hide alert with default animation.
- (void)dismiss;

/** See the descriptions of the constants of the DTAlertViewAnimation type for more information.
 * @brief Hide alert with receiver animation.
 *
 * @param animation A constant to define what animation will dismiss alert view.
 */
- (void)dismissWithAnimation:(DTAlertViewAnimation)animation;

/// @brief The shake animation, appearance like password error animation on OS X.
- (void)shakeAlertView;

@end

@protocol DTAlertViewDelegate  <NSObject>

/** @brief Sent to the delegate when the user clicks a button on an alert view.
 *
 * @param alertView The alert view containing the button.
 * @param buttonIndex The button index of clicked button, value 0 is cancel button, 1 is positive button.
 */
- (void)alertView:(DTAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@optional

/** @brief Sent to the delegate before an alert view is dismissed.
 *
 * @param alertView The alert view that is about to be dismissed.
 */
- (void)alertViewWillDismiss:(DTAlertView *)alertView;

/** @brief Sent to the delegate after an alert view is dismissed from the screen.
 *
 * @param alertView The alert view that was dismissed.
 */
- (void)alertViewDidDismiss:(DTAlertView *)alertView;

/** @brief Sent to the delegate when textField text did change.
 *
 * @param alertView The alert view containing textField.
 */
- (void)alertViewTextDidChanged:(DTAlertView *)alertView;

@end
