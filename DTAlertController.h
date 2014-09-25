//
//  DTAlertController.h
//  DTAlertViewDemo
//
//  Created by EdenLi on 2014/9/24.
//  Copyright (c) 2014年 Darktt. All rights reserved.
//

#import <UIKit/UIKit.h>

#if __has_feature(objc_arc)

#define DT_Retain strong
#define DT_Assign weak

#else

#define DT_Retain retain
#define DT_Assign assign

#endif

/** The style for action's button behavior. */
typedef NS_ENUM(NSUInteger, DTAlertActionStyle) {
    /** Default style to action's button. */
    DTAlertActionStyleNormal = 0,
    
    /** Bold font style to action's button. */
    DTAlertActionStyleBold,
    
    /**  Red text color for destructive. Ignore text color setting. */
    DTAlertActionStyleDestructive
} NS_ENUM_AVAILABLE_IOS(8_0);

// Action Handle Block
typedef void (^DTAlertActionHandle) (void);

NS_CLASS_AVAILABLE_IOS(8_0) @interface DTAlertAction : NSObject

// Readonly property.
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) DTAlertActionStyle style;

// Assignable property.
@property (DT_Retain, nonatomic) UIColor *textColor;
@property (DT_Assign, getter=isEnabled) BOOL enabled;

+ (instancetype)alertActionWithTitle:(NSString *)title alertStyle:(DTAlertActionStyle)alertStyle handle:(DTAlertActionHandle)handle;

@end

@class DTAlertController;

/** The style of display to user. */
typedef NS_ENUM(NSInteger, DTAlertStyle) {
    /** Normal alert view, it's dafult mode. */
    DTAlertStyleNormal = 0,
    
    /** Alert view with UITextField. */
    DTAlertStyleTextInput,
    
    /** Alert view with Single UIProgressView. */
    DTAlertStyleProgress,
    
    /** Alert view with Two UIProgressView. */
    DTAlertStyleDuoProgress,
    
    /** Alert view with UIActivityIndicator */
    DTAlertStyleIndeterminate,
    
    /** Alert view with custom view */
    DTAlertStyleCustomView
} NS_ENUM_AVAILABLE_IOS(8_0);

typedef void (^DTConfigurationHandler) (DTAlertController *alert, UITextField *testField);

NS_CLASS_AVAILABLE_IOS(8_0) @interface DTAlertController : UIViewController

// Readonly property.
@property (nonatomic, readonly) NSArray *actions;

// Assignable property.
@property (DT_Assign) DTAlertStyle preferredStyle;

/** @brief Apply a custom view in DTAlertStyleCustomView style. It will repleace message positition.
 */
@property (DT_Retain, nonatomic) UIView *customView;

+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message alertStyle:(DTAlertStyle)style;

- (void)addAction:(DTAlertAction *)action;
- (void)setTextFieldHandler:(DTConfigurationHandler)textFieldHandler;

@end
