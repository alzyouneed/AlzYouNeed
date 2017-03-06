//
//  AYNModel.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/12/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import Foundation
import UIKit

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
    
    var currentUserProfileImage: UIImage? = UIImage()
//    var currentUserFamilyId: String? = String()
    
    var currentUser: NSDictionary? = nil
    var familyMemberNumbers: [String] = []
    
    var wasReset = false
    var contactsArrWasReset = false
    var profileWasUpdated = false
//    var remindersArrWasReset = false
//    var completedRemindersArrWasReset = false
    
    var onboarding = false
    
    func resetModel() {
        print("Resetting model")
        contactsArr.removeAll()
        remindersArr.removeAll()
        completedRemindersArr.removeAll()
        
        currentUserProfileImage = nil
//        currentUserFamilyId = nil
        currentUser = nil
        familyMemberNumbers.removeAll()
        
        wasReset = true
        contactsArrWasReset = true
        UserDefaultsManager.setNotificationStatus(status: false)
        UserDefaultsManager.saveDeviceToken(token: "")
//        remindersArrWasReset = true
//        completedRemindersArrWasReset = true
    }
}
