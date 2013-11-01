DTAlertView
===========
![Perview 1](https://raw.github.com/Darktt/DTAlertView/master/Raw/Image/Perview1.png)![Perview 2](https://raw.github.com/Darktt/DTAlertView/master/Raw/Image/Perview2.png)

Custom alert view to solved the UIAlertView can't addSubview problem on iOS7.

**NEW Feature:**

New effect for show and dismiss animations.
* DTAlertViewAnimationSlideTop

![Slide to top](https://raw.github.com/Darktt/DTAlertView/master/Raw/DemoGif/SlideTop.gif)
* DTAlertViewAnimationSlideBottom

![Slide to bottom](https://raw.github.com/Darktt/DTAlertView/master/Raw/DemoGif/SlideBottom.gif)
* DTAlertViewAnimationSlideLeft

![Slide to left](https://raw.github.com/Darktt/DTAlertView/master/Raw/DemoGif/SlideLeft.gif)
* DTAlertViewAnimationSlideRight

![Slide to right](https://raw.github.com/Darktt/DTAlertView/master/Raw/DemoGif/SlideRight.gif)

And also can use different dismiss animation at click different button.

![Use different animation](https://raw.github.com/Darktt/DTAlertView/master/Raw/DemoGif/Different.gif)

New method **-showForPasswordInputWithAnimation:** for input password scenario, and animation **-shakeAlertView** for password error scenario.

![Password error](https://raw.github.com/Darktt/DTAlertView/master/Raw/DemoGif/PasswordError.gif)

##ATTENTION##

* This demo code create on **Xcode 5.0**, but probably have issues on **Xcode 4 or less**.
* Demo code use at **non-ARC** mode, but **DTAlertView** main class support **ARC** and **non-ARC** mode.

##Q & A##

Q: How to hidden status bar when alert presented on iOS 7?

A: Set **UIViewControllerBasedStatusBarAppearance** to **NO** in your *info.plist*, the status bar won't appear again.

##Installation##

1. Add `QuartzCore` framework.
2. Drag the `DTAlertView` folder into your project.

##Usage##

Import the header file and declare in want to used class.

	#import "DTAlertView.h"
	
###Initializing DTAlertView in your class:###

``` objective-c
// initial for class method
DTAlertView *alertView = [DTAlertView alertViewWithTitle:@"Demo" message:@"This is normal alert view." delegate:nil cancelButtonTitle:@"Cancel" positiveButtonTitle:@"OK"];

// inital for instance method
DTAlertView *alertView = [[DTAlertView alloc] initWithTitle:@"Demo" message:@"This is normal alert view." delegate:nil cancelButtonTitle:@"Cancel" positiveButtonTitle:@"OK"];
```

and you can use **Block** with alert view:

``` objective-c
DTAlertViewButtonClickedBlock block = ^(DTAlertView *_alertView, NSUInteger buttonIndex, NSUInteger cancelButtonIndex){
	// You can get button title of clicked button.
    NSLog(@"%@", _alertView.clickedButtonTitle);
};

DTAlertView *alertView = [DTAlertView alertViewUseBlock:block title:@"Demo" message:@"This is normal alert view with block." cancelButtonTitle:@"Cancel" positiveButtonTitle:nil];
```

###Show & dismiss:###

Show alert view:

``` objective-c
[alertView show];
```
<!--
// Show alert view use custom animation.
[alertView showWithAnimationBlock:^{
	// Implemnet your custom animation code
	
}];
-->

Dismiss alert view:

``` objective-c
[alertView dismiss];
```

##Install Code Snippet##
Copy codesnippet files under `Code Snippet` folder to `~/Library/Developer/Xcode/UserData/CodeSnippets/`. <br/>

* If your Xcode is opened, please quit Xcode and reopen Xcode

You can find code snippet at there.

![Code Snippet](https://raw.github.com/Darktt/DTAlertView/master/Raw/Image/CodeSnippet.png)

Or use key word `DTAlertViewButtonClickedBlock` or `DTAlertViewTextDidChangeBlock`.

![Key Word](https://raw.github.com/Darktt/DTAlertView/master/Raw/Image/KeyWord.png)

##Inatall Document Set##

###USE Xcode Documentation Viewer###
Copy `com.darktt.DTAlertView.docset` file under `Docset` folder to `~/Library/Developer/Shared/Documentation/DocSets/`. <br/>

* If your Xcode is opened, please quit Xcode and reopen Xcode

You can find it in Documentation Viewer.

###Use Dash###
Add `com.darktt.DTAlertView.docset` file under `Docset` folder on Dash preferences.

![Dash preferences](https://raw.github.com/Darktt/DTAlertView/master/Raw/Image/Dash.png)

##License##
Licensed under the Apache License, Version 2.0 (the "License");  
you may not use this file except in compliance with the License.  
You may obtain a copy of the License at

>[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)
 
Unless required by applicable law or agreed to in writing,  
software distributed under the License is distributed on an  
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,  
either express or implied.   
See the License for the specific language governing permissions  
and limitations under the License.