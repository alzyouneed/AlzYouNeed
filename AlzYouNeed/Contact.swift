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
    
    var avatarId: String!
    
//    var admin: String!
    
//    init(uID: String, userDict: NSMutableDictionary) {
////    init(uID: String, userDict: [String:String]) {
//        super.init()
//        
//        self.userId = uID
//        self.fullName = userDict.valueForKey("name") as! String
////        self.fullName = userDict["name"]
////        self.email = userDict["email"]
//        self.email = userDict.valueForKey("email") as! String
////        self.phoneNumber = userDict["phoneNumber"]
//        self.phoneNumber = userDict.valueForKey("phoneNumber") as! String
////        self.photoURL = userDict["photoURL"]
//        self.photoURL = userDict.valueForKey("photoURL") as! String
////        self.patient = userDict["patient"]
//        self.patient = userDict.valueForKey("patient") as! String
//        
//        self.avatarId = userDict.valueForKey("avatarId") as! String
//    }
    
    init?(uID: String, userDict: NSDictionary) {
        super.init()
        
        self.userId = uID
        
        self.fullName = userDict.valueForKey("name") as! String
        self.email = userDict.valueForKey("email") as! String
        self.phoneNumber = userDict.valueForKey("phoneNumber") as! String
        self.patient = userDict.valueForKey("patientStatus") as! String
        
        self.avatarId = userDict.valueForKey("avatarId") as! String
        
//        self.admin = userDict.valueForKey("admin") as! String
    }
    
//    override var description: String {
//        return "userId: \(userId) | fullName: \(fullName) | email: \(email) | phoneNumber: \(phoneNumber) | patient: \(patient) | photoURL: \(photoURL) | avatarId: \(avatarId)"
//    }
    
    override var description: String {
        return "userId: \(userId) -- fullName: \(fullName) -- email: \(email) -- phoneNumber: \(phoneNumber) -- patient: \(patient) -- avatarId: \(avatarId)"
    }
    
//    func asDictionary() -> NSMutableDictionary? {
//    }

}
