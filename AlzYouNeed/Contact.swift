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
    var relation: String?
    
    init?(uID: String, userDict: NSDictionary) {
        super.init()
        
        self.userId = uID
        self.fullName = userDict.value(forKey: "name") as! String
        self.email = userDict.value(forKey: "email") as! String
        self.phoneNumber = userDict.value(forKey: "phoneNumber") as! String
        self.patient = userDict.value(forKey: "patient") as! String
//        self.avatarId = userDict.valueForKey("avatarId") as! String
        self.admin = userDict.value(forKey: "admin") as? String ?? "false"
        
        self.photoUrl = userDict.value(forKey: "photoUrl") as? String ?? ""
        self.relation = userDict.value(forKey: "relation") as? String ?? nil
    }

    override var description: String {
//        return "userId: \(userId) -- fullName: \(fullName) -- email: \(email) -- phoneNumber: \(phoneNumber) -- patient: \(patient) -- avatarId: \(avatarId) -- photoUrl: \(photoUrl)"
        return "userId: \(userId) -- fullName: \(fullName) -- email: \(email) -- phoneNumber: \(phoneNumber) -- patient: \(patient) -- photoUrl: \(photoUrl)"
    }

}
