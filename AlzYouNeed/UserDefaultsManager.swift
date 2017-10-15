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
//        print("Saved current user in UserDefaults")
    }
    
    class func loadCurrentUser() -> NSDictionary? {
        let defaults = UserDefaults.standard
        
        if let savedUserDict = defaults.object(forKey: "currentUser") as? NSDictionary {
            return savedUserDict
        } else {
            print("Could not find user in UserDefaults")
            return nil
        }
    }
    
    class func saveCurrentUserNotepad(note: String) {
        let defaults = UserDefaults.standard
        
        defaults.set(note, forKey: "userNote")
        defaults.synchronize()
    }
    
    class func loadCurrentNote() -> String? {
        let defaults = UserDefaults.standard
        
        if let savedNote = defaults.object(forKey: "userNote") as? String {
            print("Loading note from UserDefaults")
            return savedNote
        } else {
            print("Could not find note in UserDefaults")
            return nil
        }
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
        // Create new dict and try again 
        resetUserTutorials()
        return getTutorialCompletion(tutorial: tutorial)
    }
    
    class func getReminderWarningStatus() -> Bool {
        let defaults = UserDefaults.standard
        let status = defaults.bool(forKey: "getReminderWarningStatus")
        return status
    }
    
    class func setReminderWarningStatus(status: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(status, forKey: "getReminderWarningStatus")
        defaults.synchronize()
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
    
    class func reset() {
        print("Reset UserDefaultsManager")
        resetUserTutorials()
        setReminderWarningStatus(status: false)
        setNotificationStatus(status: false)
        saveDeviceToken(token: "")
        saveCurrentUser(_user: NSDictionary())
    }
    
}
