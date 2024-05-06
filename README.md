[![Swift Package Manager compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)

# TweakedAlertController (UIKit/SwiftUI)
UIAlertController for iOS but with a few UX improvements:
- Reduced action callback delay for a more snappy experience
- tintAdjustmentMode (dimmed effect) now works everywhere instead of only on root VC
- Tap outside on alert with active textfield to close keyboard
- Tap outside on alert to close (optional)
###
- Easy 1 line of code setup
- No need to change any existing code
- Compatible with both UIKit and SwiftUI

## Installation

First install this package through SPM using the Github url `https://github.com/Janneman84/TweakedAlertController`. I suggest to use the main branch. Make sure the library is linked to the target.

Or you can just copy/paste the `TweakedAlertController.swift` file to your project, which is not recommended since you won't receive updates this way.

## Setup

You'll need to run 1 line of code at some point when your app starts. For UIKit I suggest to use `application(_:didFinishLaunchingWithOptions:)` in `AppDelegate.swift`.

If you used SPM add import:
``` swift
import TweakedAlertController
```
And add this line:
``` swift
UIAlertController.tweak()
```

That's it! All alerts and action sheets will now be tweaked automatically.

## Settings

The `tweak` method has a few optional arguments:

```swift
UIAlertController.tweak(
    alertCallbackDelay: 0.3,
    actionSheetCallbackDelay: 0.3,
    alertCancelOnTapOutside: false
)
```

Here you can customize the desired action callback delay. If you choose 0.3 (default value) the callback will be triggered immediately after the closing animation finishes. Choosing a value lower than this will cut the animation short, or choose 0 to skip the animation entirely. Choose 0.4 to get original untweaked behavior.

`alertCancelOnTapOutside` enables you to cancel alerts by tapping outside, just like you can on actionSheets/confirmationDialogs. This is disabled by default.

You can call the `tweak` method as many times as you like to change these settings.