//
//  DTAlertController.m
//  DTAlertViewDemo
//
//  Created by EdenLi on 2014/9/24.
//  Copyright (c) 2014年 Darktt. All rights reserved.
//

#import "DTAlertController.h"

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

NSString *const KeyPathTextColor = @"textColor";

@interface DTAlertAction ()
{
    DTAlertActionHandle _handler;
    
    // Property variable.
    UIColor *_textColor;
}

@property (DT_Retain, nonatomic) NSString *title;
@property (DT_Assign, nonatomic) DTAlertActionStyle style;

@end

@implementation DTAlertAction

+ (instancetype)alertActionWithTitle:(NSString *)title alertStyle:(DTAlertActionStyle)alertStyle handle:(DTAlertActionHandle)handle
{
    DTAlertAction *action = [[DTAlertAction alloc] initWithTitle:title alertStyle:alertStyle handle:handle];
    
    return [action autorelease];
}

- (instancetype)initWithTitle:(NSString *)title alertStyle:(DTAlertActionStyle)alertStyle handle:(DTAlertActionHandle)handle
{
    self = [super init];
    if (self == nil) return nil;
    
    [self setTitle:title];
    [self setStyle:alertStyle];
    
    _handler = DTBlockCopy(handle);
    
    [self setTextColor:[UIColor colorWithRed:0 green:122.0f/255.0f blue:1 alpha:1]];
    
    return self;
}

- (void)dealloc
{
    
#ifdef ARC_MODE_NOT_USED
    
    [super dealloc];
    
    [self setTitle:nil];
    
    DTBlockRelease(_handler);
    [_textColor release];
    
#endif
    
}

- (void)setTextColor:(UIColor *)textColor
{
    if (_textColor != nil) {
        DTRelease(_textColor);
    }
    
    if (self.style == DTAlertActionStyleDestructive) {
        _textColor = DTRetain([UIColor redColor]);
        
        return;
    }
    
    _textColor = DTRetain(textColor);
}

- (UIColor *)textColor
{
    return _textColor;
}

@end

@interface DTAlertController ()

@end

@implementation DTAlertController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
