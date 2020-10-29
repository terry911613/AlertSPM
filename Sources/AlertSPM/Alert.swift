//
//  Alert.swift
//  AlertSample
//
//  Created by Terry Lee on 2020/4/23.
//  Copyright © 2020 Terry Lee. All rights reserved.
//

import UIKit
import SwiftUI

public class Alert: UIAlertController {

    public enum DisplayingBehavior {

        /// Presenting: Show alert if no presented yet. Otherwise, dismiss the presented and show itself.
        /// Dismissing: Dismiss the presented and show the next from queue if exists.
        case `default`

        /// Dismiss the presented alert if it shown and clear queue.
        case discardAll

        /// Presenting: Show alert if no presented yet. Otherwise, add to the end of queue for showing after all alerts.
        /// Dismissing: Put presented alert in queue and dismiss it without presenting new.
        /// Call `Alert.presentNext()` to present a waiting alert from queue.
        case passive
    }

    var shouldSkip = false

    // MARK: - Public

    public override func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        dismiss(animated: animated, behavior: .default, completion: completion)
    }

    public func dismiss(animated: Bool = true, behavior: DisplayingBehavior, completion: (() -> Void)? = nil) {
        switch behavior {
        case .default:
            break
        case .discardAll:
            Alert.queue.removeAll()
        case .passive:
            addToQueue(animated: true)
        }

        if !isPresented {
            // Current (self) alert is not presented
            completion?()
            return
        }

        switch behavior {
        case .passive:
            super.dismiss(animated: animated, completion: completion)
        case .default, .discardAll:
            guard let alertItem = Alert.queue.popLast() else {
                super.dismiss(animated: animated, completion: completion)
                return
            }
            super.dismiss(animated: animated) {
                alertItem.alert.show(animated: alertItem.animated) {
                    alertItem.completion?()
                    completion?()
                }
            }
        }
    }

    public func show(animated: Bool = true, behavior: DisplayingBehavior = .default, isUnique: Bool = false, completion: (() -> Void)? = nil) {
        if shouldSkip {
            return
        }
        guard let host = Alert.topViewController else { return }
        if !isUnique {
            if isPresented || isAlreadyInQueue {
                return
            }
        }
        switch behavior {
        case .default:
            if let presentedAlert = host as? Alert {
                presentedAlert.addToQueue(animated: true)
                presentedAlert.dismiss(animated: false) {
                    Alert.topViewController?.present(self, animated: animated, completion: completion)
                }
                return
            }
        case .discardAll:
            Alert.queue.removeAll()
            if let presentedAlert = host as? Alert {
                presentedAlert.dismiss(animated: animated, behavior: .passive) {
                    Alert.topViewController?.present(self, animated: animated, completion: completion)
                }
                return
            }
        case .passive:
            if host is Alert {
                addToQueue(animated: animated)
                completion?()
                return
            }
        }
        host.present(self, animated: animated, completion: completion)
    }

    /// Just adds alert in queue without presentation or dismission.
    public func postponePresentation(animated: Bool = true, completion: (() -> Void)? = nil) {
        if !isPresented {
            addToQueue(animated: animated, completion: completion)
        }
    }

    public static func showNext(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let top = Alert.topViewController else { return }
        if let presentedAlert = top as? Alert {
            // Popping of next alert will perform in `dismiss()`
            presentedAlert.dismiss(animated: false, completion: completion)
            return
        }
        guard let alertItem = Alert.queue.popLast() else {
            completion?()
            return
        }
        top.present(alertItem.alert, animated: animated) {
            alertItem.completion?()
            completion?()
        }
    }

    public static func dismissTop(animated: Bool = true, behavior: DisplayingBehavior = .default, completion: (() -> Void)? = nil) {
        if let top = Alert.topViewController as? Alert {
            top.dismiss(animated: animated, behavior: behavior, completion: completion)
        } else {
            completion?()
        }
    }
    
    public static func showDatePicker(completion: @escaping (Date) -> ()) {
        //  建立警告控制器顯示 datePicker
        let dateAlert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        
        let datePicker = UIDatePicker()
        //  顯示 datePicker 方式和大小
//        datePicker.locale = Locale(identifier: "zh_TW")
        datePicker.locale = Locale.current
        datePicker.datePickerMode = .time
        datePicker.frame = CGRect(x: 0, y: 0, width: dateAlert.view.frame.width, height: 250)
        dateAlert.view.addSubview(datePicker)
        
        //  警告控制器裡的確定按鈕
        let okAction = UIAlertAction(title: "done", style: .default) { (alert: UIAlertAction) in
            completion(datePicker.date)
            print(datePicker.date)
        }
        dateAlert.addAction(okAction)
        //  警告控制器裡的取消按鈕
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        dateAlert.addAction(cancelAction)
    }

    // MARK: - Action

    @discardableResult
    public func addAction(title: String?, style: UIAlertAction.Style = .default, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        let action = UIAlertAction(title: title, style: style) { inAction in
            handler?(inAction)
            if let alertItem = Alert.queue.popLast() {
                alertItem.alert.show(animated: alertItem.animated, completion: alertItem.completion)
            }
        }
        addAction(action)
        return action
    }

    public func addCancel(title: String? = nil, handler: (() -> Void)? = nil) {
        addAction(title: title ?? "cancel", style: .cancel) { _ in handler?() }
    }

    // MARK: - Queue

    public var isAlreadyInQueue: Bool {
        return Alert.queue.contains { isEqual($0.alert) }
    }

    public var isPresented: Bool {
        if presentingViewController != nil {
            return true
        }
        // Check top presented Alert is equal to self to prevent show similar alert
        if let presentedAlert = Alert.topViewController as? Alert,
            isEqual(presentedAlert) {
            return true
        }
        return false
    }

    private struct QueueItem {
        let alert: Alert
        let animated: Bool
        let completion: (() -> Void)?
    }

    private static var queue: [QueueItem] = []

    private func addToQueue(animated: Bool, completion: (() -> Void)? = nil) {
        if !isAlreadyInQueue {
            Alert.queue.append(QueueItem(alert: self, animated: animated, completion: completion))
        }
    }

    private func isEqual(_ other: Alert) -> Bool {
        return title == other.title
            && message == other.message
            && other.actions.count == actions.count
    }

    // MARK: - Private

    private static var topViewController: UIViewController? {
        if let windowScence = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let scenceDelegat = windowScence.delegate as? SceneDelegate {
            
            return scenceDelegat.window?.rootViewController?.topVC
        }
        return nil
    }
}

// MARK: - Convenience

extension Alert {

//    public static func makeMessageActionSheet(title: String? = nil, message: String? = "",
//                                       confirmTitle: String = "ok", confirmStyle: UIAlertAction.Style = .default, confirmHandler: ((UIAlertAction) -> Void)? = nil) -> Alert {
//        let alert = Alert(title: title, message: message, preferredStyle: .actionSheet)
//        alert.addAction(title: confirmTitle, style: confirmStyle, handler: confirmHandler)
//        return alert
//    }
//
//    public static func makePromptActionSheet(title: String? = nil, message: String? = "", style: UIAlertController.Style = .alert,
//                                             confirmTitle: String = "ok", confirmStyle: UIAlertAction.Style = .default, confirmHandler: ((UIAlertAction) -> Void)? = nil,
//                                             cancelTitle: String = "cancel", cancelStyle: UIAlertAction.Style = .cancel, cancelHandler: ((UIAlertAction) -> Void)? = nil) -> Alert {
//        let alert = makeMessageActionSheet(title: title, message: message, confirmTitle: confirmTitle, confirmStyle: confirmStyle, confirmHandler: confirmHandler)
//        alert.addAction(title: cancelTitle, style: cancelStyle, handler: cancelHandler)
//        return alert
//    }

    public static func makeMessage(title: String? = nil, message: String? = "", style: UIAlertController.Style = .alert,
                                  confirmTitle: String = "ok", confirmStyle: UIAlertAction.Style = .default, confirmHandler: ((UIAlertAction) -> Void)? = nil) -> Alert {
        let alert = Alert(title: title, message: message, preferredStyle: style)
        alert.addAction(title: confirmTitle, style: confirmStyle, handler: confirmHandler)
        return alert
    }

    public static func makePrompt(title: String? = nil, message: String? = "", style: UIAlertController.Style = .alert,
                                  confirmTitle: String = "ok", confirmStyle: UIAlertAction.Style = .default, confirmHandler: ((UIAlertAction) -> Void)? = nil,
                                  cancelTitle: String = "cancel", cancelStyle: UIAlertAction.Style = .cancel, cancelHandler: ((UIAlertAction) -> Void)? = nil) -> Alert {
        let alert = makeMessage(title: title, message: message, style: style,
                                confirmTitle: confirmTitle, confirmStyle: confirmStyle, confirmHandler: confirmHandler)
        alert.addAction(title: cancelTitle, style: cancelStyle, handler: cancelHandler)
        return alert
    }

}




