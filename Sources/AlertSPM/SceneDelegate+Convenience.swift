//
//  SceneDelegate+Convenience.swift
//  AlertSample
//
//  Created by Terry Lee on 2020/4/23.
//  Copyright © 2020 Terry Lee. All rights reserved.
//

import UIKit

extension SceneDelegate {
    var topmostViewController: UIViewController? {
        return window?.rootViewController?.topVC
    }
}
