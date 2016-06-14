//
//  Person.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class Person: NSObject, NSCoding {
    // MARK: - Properties
    var identifier: String!
    var firstName: String!
    var lastName: String?
//    var photo: UIImage?
    // Save image path for more efficient storage and loading
    var photoPath: String?
    var phoneNumber: String?
    
    
    // MARK: - Init
    init(identifier: String, firstName: String, lastName: String?, photoPath: String?, phoneNumber: String?) {
        super.init()
        self.identifier = identifier
        self.firstName = firstName
        self.lastName = lastName
        self.photoPath = photoPath
        self.phoneNumber = phoneNumber
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let identifier = aDecoder.decodeObjectForKey("identifier") as! String
        let firstName = aDecoder.decodeObjectForKey("firstName") as! String
        let lastName = aDecoder.decodeObjectForKey("lastName") as? String
        let photoPath = aDecoder.decodeObjectForKey("photoPath") as? String
        let phoneNumber = aDecoder.decodeObjectForKey("phoneNumber") as? String
        self.init(identifier: identifier, firstName: firstName, lastName: lastName, photoPath: photoPath, phoneNumber: phoneNumber)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.identifier, forKey: "identifier")
        aCoder.encodeObject(self.firstName, forKey: "firstName")
        aCoder.encodeObject(self.lastName, forKey: "lastName")
        aCoder.encodeObject(self.photoPath, forKey: "photoPath")
        aCoder.encodeObject(self.phoneNumber, forKey: "phoneNumber")
    }

}
