//
//  UIViewController+Convenience.swift
//  AlertSample
//
//  Created by Terry Lee on 2020/4/23.
//  Copyright © 2020 Terry Lee. All rights reserved.
//

import UIKit

extension UIViewController {
    
    var topVC: UIViewController? {
        if presentedViewController == nil {
            return self
        }
        if let navigation = presentedViewController as? UINavigationController,
            let topVC = navigation.visibleViewController?.topVC {
            return topVC
        }
        if let tab = presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topVC
            }
            return tab.topVC
        }
        return presentedViewController?.topVC
    }
}
