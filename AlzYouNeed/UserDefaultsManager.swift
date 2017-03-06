//
//  UserDefaultsManager.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class UserDefaultsManager: NSObject {
    
    class func saveCurrentUser(_user: NSDictionary) {
        let defaults = UserDefaults.standard
        
        defaults.set(_user, forKey: "currentUser")
        defaults.synchronize()
        print("Saved current user in UserDefaults")
    }
    
    class func loadCurrentUser(_userId: String) -> NSDictionary? {
        let defaults = UserDefaults.standard
        if let savedUserDict = defaults.object(forKey: "currentUser") as? NSDictionary {
            if let savedUserId = savedUserDict.value(forKey: "userId") as? String {
                if savedUserId == _userId {
                    print("Loading user from UserDefaults")
//                    print("Loading user from UserDefaults:", savedUserDict)
                    return savedUserDict
                } else {
                    // Not the same user -- return nil
                    print("Different user in UserDefaults - skipping")
                    return nil
                }
            }
            print("Could not find userId in UserDefaults")
            return nil
        }
        print("Could not find user in UserDefaults")
        return nil
    }
    
    class func saveCurrentUserNotepad(_note: String) {
        let defaults = UserDefaults.standard
        
        if let userId = AYNModel.sharedInstance.currentUser?.object(forKey: "userId") as? String {
            defaults.set(_note, forKey: userId)
            defaults.synchronize()
            print("Saved current user notepad to UserDefaults")
        }
    }
    
    class func loadCurrentNote() -> String? {
        let defaults = UserDefaults.standard
        if let userId = AYNModel.sharedInstance.currentUser?.object(forKey: "userId") as? String {
            if let savedUserNote = defaults.object(forKey: userId) as? String {
                print("Loading note from UserDefaults")
                return savedUserNote
            } else {
                print("Could not find note in UserDefaults")
                return nil
            }
        }
        return nil
    }
    
    // Handle first time using certain features
    class func resetUserTutorials() {
        let defaults = UserDefaults.standard
        
        // Dict of features with tutorials
        let newPrefs = [Tutorials.notepad.rawValue : "false",
                        Tutorials.contactList.rawValue : "false",
                        Tutorials.reminders.rawValue : "false"]
        defaults.setValue(newPrefs, forKeyPath: "completedTutorials")
        defaults.synchronize()
        print("Reset user tutorial prefs")
    }
    
    class func completeTutorial(tutorial: String) {
        let defaults = UserDefaults.standard
        
        if let completedTutorials = defaults.object(forKey: "completedTutorials") as? [String:String] {
            if (completedTutorials[tutorial] as String?) != nil {
                print("Found requested tutorial -- completing")
                var modifiedDict = completedTutorials
                modifiedDict[tutorial] = "true"

                defaults.setValue(modifiedDict, forKeyPath: "completedTutorials")
                defaults.synchronize()
                
//                print("Tutorials:", modifiedDict)
            } else {
                print("Tutorial doesn't exist -- not completing:", tutorial)
            }
        } else {
            print("No completedTutorials dictionary found")
        }
    }
    
    class func getTutorialCompletion(tutorial: String) -> String? {
        let defaults = UserDefaults.standard
        
        if let completedTutorials = defaults.object(forKey: "completedTutorials") as? [String:String] {
            if let requestedTutorial = completedTutorials[tutorial] as String? {
                print("Found requested tutorial")
                return requestedTutorial
            } else {
                print("Tutorial doesn't exist:", tutorial)
            }
        }
        print("No completedTutorials dictionary found")
        return nil
    }
    
    class func getNotificationStatus() -> Bool {
        let defaults = UserDefaults.standard
        let status = defaults.bool(forKey: "notificationStatus")
        print("Get notification status:", status)
        return status
    }
    
    class func setNotificationStatus(status: Bool) {
        print("Set notification status:", status)
        let defaults = UserDefaults.standard
        defaults.set(status, forKey: "notificationStatus")
        defaults.synchronize()
    }
    
    // MARK: - Device Token
    class func saveDeviceToken(token: String) {
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "deviceToken")
        defaults.synchronize()
    }
    
    class func getDeviceToken() -> String? {
        let defaults = UserDefaults.standard
        let deviceToken = defaults.string(forKey: "deviceToken")
        return deviceToken
    }
    
}
