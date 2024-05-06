//
//  TweakedAlertController.swift
//
//  Created by Jan de Vries on 06/05/2024.
//

import UIKit

public extension UIAlertController {
    
    /**
     Improves callback delay, alert tapping outside behavior and fixes tintAdjustmentMode issues for all future alerts and actionSheets/confirmationDialogs (UIKit/SwiftUI).
    
     - Parameter alertCallbackDelay: The time between closing the alert and triggering the action callback. Enter 0.3 to trigger immediately after closing animation. Use a lower value to cut the animation short or 0 to skip it entirely. Enter 0.4 for original behavior. Default value is 0.3.
     - Parameter actionSheetCallbackDelay: Same as above but for actionSheets/confirmationDialogs
     - Parameter alertCancelOnTapOutside: Enable to allow user to trigger alert's cancel action by tapping outside, like you can on actionSheets/confirmationDialogs. Default value is false.
     */
    
    static func tweak(
        alertCallbackDelay: TimeInterval? = nil,
        actionSheetCallbackDelay: TimeInterval? = nil,
        alertCancelOnTapOutside: Bool? = nil)
    {
        UIAlertController.tweakedSwizzleLifecycleMethods()
        if let alertCallbackDelay {
            Self.tweakedAlertCallbackDelay = max(min(alertCallbackDelay, 0.4),0)
        }
        if let actionSheetCallbackDelay {
            Self.tweakedActionSheetCallbackDelay = max(min(actionSheetCallbackDelay, 0.4),0)
        }
        if let alertCancelOnTapOutside {
            Self.tweakedAlertCancelOnTapOutside = alertCancelOnTapOutside
        }
    }
}

fileprivate extension UIAlertController {

    static var tweakedAlertCallbackDelay: TimeInterval = 0.3
    static var tweakedActionSheetCallbackDelay: TimeInterval = 0.3
    static var tweakedAlertCancelOnTapOutside: Bool = false
        
    static func tweakedSwizzleLifecycleMethods() {
        //this makes sure it can only swizzle once
        _ = self.tweakedActuallySwizzleLifecycleMethods
    }
    
    static let tweakedActuallySwizzleLifecycleMethods: Void = {
        let originalVwaMethod = class_getInstanceMethod(UIAlertController.self, #selector(viewWillAppear(_:)))
        let swizzledVwaMethod = class_getInstanceMethod(UIAlertController.self, #selector(tweakedViewWillAppear(_:)))
        method_exchangeImplementations(originalVwaMethod!, swizzledVwaMethod!)
        
        let originalVwdMethod = class_getInstanceMethod(UIAlertController.self, #selector(viewWillDisappear(_:)))
        let swizzledVwdMethod = class_getInstanceMethod(UIAlertController.self, #selector(tweakedViewWillDisappear(_:)))
        method_exchangeImplementations(originalVwdMethod!, swizzledVwdMethod!)

    }()
    
    func tweakedDelay(_ animated: Bool) -> TimeInterval {
        animated ? (self.preferredStyle == .alert ? Self.tweakedAlertCallbackDelay : Self.tweakedActionSheetCallbackDelay) : 0.0
    }
    
    @objc func tweakedViewWillAppear(_ animated: Bool) -> Void {
        tweakedViewWillAppear(animated) //run original implementation
        
        //Somehow dimming normally only works on root VC, causing seemly inconsistent behavior.
        //This code always dims the underlying VC, wether it's the root VC or not.
        DispatchQueue.main.async {
            if let pvcView = self.presentingViewController?.view, pvcView.tintAdjustmentMode != .dimmed {
                UIView.animate(withDuration: self.tweakedDelay(animated), delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                    pvcView.tintAdjustmentMode = .dimmed
                })
            }
        }

        if self.preferredStyle == .alert, view.superview?.gestureRecognizers == nil {
            view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tweakedBackgroundTapped)))
        }
    }
    
    @objc func tweakedViewWillDisappear(_ animated: Bool) -> Void {
        tweakedViewWillDisappear(animated) //run original implementation
        
        DispatchQueue.main.asyncAfter(deadline: .now() + tweakedDelay(animated)) { [weak self] in //0.26667 //0.2833333
            (self?.view.superview?.superview ?? self?.view.window)?.tweakedRemoveAnimations()
        }
        
        if let pvcView = presentingViewController?.view, pvcView.tintAdjustmentMode == .dimmed {
            UIView.animate(withDuration: min(tweakedDelay(animated), 0.3), delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                pvcView.tintAdjustmentMode = .automatic
            })
        }
    }
    
    @objc func tweakedBackgroundTapped() {
        if !isBeingDismissed {
            for textField in textFields ?? [] {
                if textField.isFirstResponder {
                    textField.resignFirstResponder()
                    return;
                }
            }
            if Self.tweakedAlertCancelOnTapOutside {
                presentingViewController?.dismiss(animated: true) {
                    self.tweakedTapCancelButton()
                }
            }
        }
    }

    typealias tweakedAlertHandler = @convention(block) (UIAlertAction) -> Void

    func tweakedTapCancelButton() {
        for action in actions {
            if action.style == .cancel {
                tweakedTriggerAction(action)
                break
            }
        }
    }
    
    func tweakedTapPreferredActionButton() {
        for action in actions {
            if action == preferredAction {
                tweakedTriggerAction(action)
                break
            }
        }
    }
    
    func tweakedTriggerAction(_ action: UIAlertAction) {
        guard let block = action.value(forKey: "handler") else { return }
        let handler = unsafeBitCast(block as AnyObject, to: tweakedAlertHandler.self)
        handler(action)
    }
}

fileprivate extension UIView {
    func tweakedRemoveAnimations(level : UInt = 0) {
        for animationKey in layer.animationKeys() ?? [] {
            let animation = self.layer.animation(forKey: animationKey)
            layer.removeAnimation(forKey: animationKey)
        }
        for subview in subviews {
            subview.tweakedRemoveAnimations(level: level+1)
        }
    }
}
