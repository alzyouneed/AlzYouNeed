//
//  Contact.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/25/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class Contact: NSObject {
    
    var userId: String!
    var fullName: String!
    var email: String!
    var phoneNumber: String!
    var photoURL: String!
    var patient: String!
    
    init(uID: String, userDict: [String:String]) {
        super.init()
        
        self.userId = uID
        self.fullName = userDict["name"]
        self.email = userDict["email"]
        self.phoneNumber = userDict["phoneNumber"]
        self.photoURL = userDict["photoURL"]
        self.patient = userDict["patient"]
    }
    
    override var description: String {
        return "userId: \(userId) | fullName: \(fullName) | email: \(email) | phoneNumber: \(phoneNumber) | patient: \(patient) | photoURL: \(photoURL)"
    }

}
