//
//  DataObjects.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 1/11/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import Foundation
import UIKit

// A collection of all data objects
struct Contact {
    var userId: String!
    var name: String!
    var phoneNumber: String!
    var photoUrl: String!
    var deviceToken: String!
    
    var photo: UIImage!
    
    init?(userId: String, userDict: NSDictionary) {
        self.userId = userId
        
        guard let name = userDict.value(forKey: "name") as? String else {return nil}
        self.name = name
        
        self.photoUrl = userDict.value(forKey: "photoURL") as? String ?? nil
        
        self.deviceToken = userDict.value(forKey: "deviceToken") as? String ?? nil
        
        self.phoneNumber = userDict.value(forKey: "phoneNumber") as? String ?? nil
    }
}

struct Message {
    var messageId: String!
    var senderId: String!
    var dateSent: String!
    var messageString: String!
//    var favorited: [String:String]!
    
    init?(messageId: String, messageDict: NSDictionary) {
        self.messageId = messageId
        
        guard let senderId = messageDict.object(forKey: "senderId") as? String else {return nil}
        self.senderId = senderId
        
        guard let dateSent = messageDict.object(forKey: "timestamp") as? String else {return nil}
        self.dateSent = dateSent
        
        guard let messageString = messageDict.object(forKey: "messageString") as? String else {return nil}
        self.messageString = messageString
        
//        self.favorited = messageDict.object(forKey: "favorited") as? [String:String] ?? [:]
    }
}

struct Reminder {
    var id: String!
    var title: String!
    var reminderDescription: String!
    var createdDate: String!
    var dueDate: String!
    var completedDate: String!
    var alertBeforeInterval: String!
    var repeats: String!
    
    init?(reminderId: String, reminderDict: NSDictionary) {
        self.id = reminderId
        
        guard let title = reminderDict.value(forKey: "title") as? String else {return nil}
        self.title = title
        
        guard let reminderDescription = reminderDict.value(forKey: "description") as? String else {return nil}
        self.reminderDescription = reminderDescription
        
        guard let createdDate = reminderDict.value(forKey: "createdDate") as? String else {return nil}
        self.createdDate = createdDate
        
        guard let dueDate = reminderDict.value(forKey: "dueDate") as? String else {return nil}
        self.dueDate = dueDate
        
        guard let alertBeforeInterval = reminderDict.value(forKey: "alertBeforeInterval") as? String else {return nil}
        self.alertBeforeInterval = alertBeforeInterval
        
        guard let repeats = reminderDict.value(forKey: "repeats") as? String else {return nil}
        self.repeats = repeats
        
        self.completedDate = reminderDict.value(forKey: "completedDate") as? String ?? ""
    }
    
    func asDict() -> Dictionary<String, String> {
        let reminderDict: Dictionary<String, String> = ["title": self.title, "description": self.reminderDescription, "createdDate": self.createdDate, "dueDate": self.dueDate, "completedDate": self.completedDate, "repeats": self.repeats, "alertBeforeInterval": self.alertBeforeInterval]
        return reminderDict
    }
}

// Keeps track of new accounts during onboarding
struct Profile {
    // Required
    var name: String!
    var groupName: String!
    var admin: Bool!
    
    // Optional
    var photoURL: String?
    
    // Extra
    var authProvider: String!
}

