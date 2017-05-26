//
//  NewProfile.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/20/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import Foundation

class NewProfile {
    
    class var sharedInstance: NewProfile {
        struct Static {
            static let instance: NewProfile = NewProfile()
        }
        return Static.instance
    }
    
    // Required
    var name: String!

    // Optional
    var photoURL: String?
    
    func asDict() -> Dictionary<String, String> {
        let newProfileDict: Dictionary<String, String> = ["name": name,
                                                          "photoURL": photoURL ?? ""]
        return newProfileDict
    }
    
    func resetModel() {
        print("Reset new profile")
        name = ""
        photoURL = ""
    }
    
}
