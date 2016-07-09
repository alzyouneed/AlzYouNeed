//
//  Reminder.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/9/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class Reminder: NSObject {

    var title: String!
    var reminderDescription: String!
    var dueDate: String!
    
    init(reminderTitle: String, reminderDescription: String, reminderDueDate: String) {
        super.init()
        self.title = reminderTitle
        self.reminderDescription = reminderDescription
        self.dueDate = reminderDueDate
    }
    
    init?(reminderDict: NSDictionary) {
        super.init()
        self.title = reminderDict.valueForKey("title") as! String
        self.reminderDescription = reminderDict.valueForKey("description") as! String
        self.dueDate = reminderDict.valueForKey("dueDate") as! String
    }
    
    override var description: String {
        return "title: \(title) -- description: \(reminderDescription) -- dueDate: \(dueDate)"
    }
    
}
