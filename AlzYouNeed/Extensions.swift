//
//  Extensions.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/15/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

// For improved constraint debugging in log
extension NSLayoutConstraint {
    override open var description: String {
        let id = identifier ?? ""
        return "id: \(id), constant: \(constant)"
    }
}

extension UINavigationController {
    public func presentTransparentNavBar() {
        navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationBar.isTranslucent = true
        navigationBar.shadowImage = UIImage()
        setNavigationBarHidden(false, animated: true)
    }
    
    public func hideTransparentNavBar() {
        setNavigationBarHidden(true, animated: false)
        navigationBar.setBackgroundImage(UINavigationBar.appearance().backgroundImage(for: UIBarMetrics.default), for: UIBarMetrics.default)
        navigationBar.isTranslucent = UINavigationBar.appearance().isTranslucent
        navigationBar.shadowImage = UINavigationBar.appearance().shadowImage
    }
    
//    public func presentColoredNavBar() {
//        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
////        navigationBar.opaque = true
//        navigationBar.barTintColor = slateBlue
////        navigationBar.backgroundColor = slateBlue
//        navigationBar.shadowImage = UIImage()
////        navigationBar.clipsToBounds = true
//        setNavigationBarHidden(false, animated: true)
//    }
}
