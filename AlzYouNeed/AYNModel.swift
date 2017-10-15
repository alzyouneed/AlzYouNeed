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
    
    // MARK: - New
    var groupId: String? = nil
    var userImage: UIImage? = nil
    
    var contactsArr: [Contact] = []
    var remindersArr: [Reminder] = []
    var completedRemindersArr: [Reminder] = []
    
    var familyMemberNumbers: [String] = []
    
    var currentUser: NSDictionary? = nil
//    var familyMemberNumbers: [String] = []
    
    var wasReset = false
    var contactsArrWasReset = false
    var profileWasUpdated = false
//    var remindersArrWasReset = false
//    var completedRemindersArrWasReset = false
    
    var onboarding = false
    
    func loadFromFirebase(completionHandler: @escaping (_ complete: Bool) -> Void) {
        FirebaseManager.getCurrentUser { (userDict, error) in
            if let error = error {
                print("Could not load user from Firebase: ", error.localizedDescription)
                completionHandler(false)
            } else {
                if let userDict = userDict {
                    print("Loaded user from Firebase")
                    guard let groupId = userDict.value(forKey: "groupId") as? String else {
                        completionHandler(false)
                        return
                    }
                    self.groupId = groupId
                    
                    UserDefaultsManager.saveCurrentUser(_user: userDict)
                    completionHandler(true)
                }
            }
        }
    }
    
    func loadFromDefaults(completionHandler: @escaping (_ complete: Bool) -> Void) {
        if let userDict = UserDefaultsManager.loadCurrentUser() {
            print("Loaded user from Defaults")
            guard let groupId = userDict.value(forKey: "groupId") as? String else {
                completionHandler(false)
                return
            }
            self.groupId = groupId
            completionHandler(true)
        } else {
            print("Could not load user from Defaults")
            completionHandler(false)
        }
    }

    func resetModel() {
        print("Resetting model")
        contactsArr.removeAll()
        remindersArr.removeAll()
        completedRemindersArr.removeAll()
        userImage = nil
//        currentUserProfileImage = nil
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
