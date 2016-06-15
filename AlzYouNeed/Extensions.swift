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
    override public var description: String {
        let id = identifier ?? ""
        return "id: \(id), constant: \(constant)"
    }
}