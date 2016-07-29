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
    var photoUrl: String!
    var patient: String!
    var avatarId: String!
    var admin: String!
    
    init?(uID: String, userDict: NSDictionary) {
        super.init()
        
        self.userId = uID
        self.fullName = userDict.valueForKey("name") as! String
        self.email = userDict.valueForKey("email") as! String
        self.phoneNumber = userDict.valueForKey("phoneNumber") as! String
        self.patient = userDict.valueForKey("patient") as! String
//        self.avatarId = userDict.valueForKey("avatarId") as! String
        self.admin = userDict.valueForKey("admin") as? String ?? "false"
        
        self.photoUrl = userDict.valueForKey("photoUrl") as? String ?? ""

    }

    override var description: String {
//        return "userId: \(userId) -- fullName: \(fullName) -- email: \(email) -- phoneNumber: \(phoneNumber) -- patient: \(patient) -- avatarId: \(avatarId) -- photoUrl: \(photoUrl)"
        return "userId: \(userId) -- fullName: \(fullName) -- email: \(email) -- phoneNumber: \(phoneNumber) -- patient: \(patient) -- photoUrl: \(photoUrl)"
    }

}
