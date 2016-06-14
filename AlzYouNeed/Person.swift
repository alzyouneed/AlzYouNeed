//
//  Person.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class Person: NSObject {
    // MARK: - Properties
    var identifier: String!
    var firstName: String!
    var lastName: String?
//    var photo: UIImage?
    // Save image path for more efficient storage and loading
    var photoPath: String?
    var phoneNumber: String!
    
    
    // MARK: - Init
    init(identifier: String, firstName: String, lastName: String?, photoPath: String?, phoneNumber: String) {
        super.init()
        self.identifier = identifier
        self.firstName = firstName
        self.lastName = lastName
        self.photoPath = photoPath
        self.phoneNumber = phoneNumber
    }

}
