//
//  Reminder.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/9/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class Reminder: NSObject {

    var id: String!
    var title: String!
    var reminderDescription: String!
    var createdDate: String!
    var dueDate: String!
    var completedDate: String!
    var repeats: String!
    
    init(reminderId: String, reminderTitle: String, reminderDescription: String, reminderDueDate: String) {
        super.init()
        self.id = reminderId
        self.title = reminderTitle
        self.reminderDescription = reminderDescription
        self.dueDate = reminderDueDate
    }
    
    init?(reminderId: String, reminderDict: NSDictionary) {
        super.init()
        self.id = reminderId
        self.title = reminderDict.value(forKey: "title") as! String
        self.reminderDescription = reminderDict.value(forKey: "description") as! String
        self.createdDate = reminderDict.value(forKey: "createdDate") as! String
        self.dueDate = reminderDict.value(forKey: "dueDate") as! String
        self.completedDate = reminderDict.value(forKey: "completedDate") as? String ?? ""
        self.repeats = reminderDict.value(forKey: "repeats") as? String ?? "None"
    }
    
    override var description: String {
        return "id: \(id) -- title: \(title) -- description: \(reminderDescription) -- createdDate: \(createdDate) -- dueDate: \(dueDate) -- completedDate: \(completedDate) -- repeats: \(repeats)"
    }

    func asDict() -> Dictionary<String, String> {
        let reminderDict: Dictionary<String, String> = ["title": self.title, "description": self.reminderDescription, "createdDate": self.createdDate, "dueDate": self.dueDate, "completedDate": self.completedDate, "repeats": self.repeats]
        return reminderDict
    }
    
}
