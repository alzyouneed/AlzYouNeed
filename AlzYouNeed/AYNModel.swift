//
//  AYNModel.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/12/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import Foundation

class AYNModel {
    
    class var sharedInstance: AYNModel {
        struct Static {
            static let instance: AYNModel = AYNModel()
        }
        return Static.instance
    }
    
    var contactsArr: [Contact] = []
    var remindersArr: [Reminder] = []
    var completedRemindersArr: [Reminder] = []
    
    var wasReset = false
    var contactsArrWasReset = false
//    var remindersArrWasReset = false
//    var completedRemindersArrWasReset = false
    
    func resetModel() {
        print("Resetting model")
        contactsArr.removeAll()
        remindersArr.removeAll()
        completedRemindersArr.removeAll()
        wasReset = true
        contactsArrWasReset = true
//        remindersArrWasReset = true
//        completedRemindersArrWasReset = true
    }
}