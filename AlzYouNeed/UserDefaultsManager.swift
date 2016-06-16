//
//  UserDefaultsManager.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class UserDefaultsManager: NSObject {
    
    class func saveContact(person: Person) {
        
        // Only save if new person
        if !contactExists(person.identifier) {
            let defaults = NSUserDefaults.standardUserDefaults()
        
            var contacts = getAllContacts()
        
            // Add new contact to old list
            contacts?.append(person)
        
            // Encode data for storage
            let encodedData = NSKeyedArchiver.archivedDataWithRootObject(contacts!)
            defaults.setObject(encodedData, forKey: "savedContacts")
            defaults.synchronize()
        }
        else {
            print("Contact already exists: \(person.firstName) | \(person.identifier)")
        }
    }
    
    class func getAllContacts() -> [Person]? {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        var savedContacts = [Person]()
        
        if let decoded = defaults.objectForKey("savedContacts") as? NSData {
            let decodedContacts = NSKeyedUnarchiver.unarchiveObjectWithData(decoded) as! [Person]
            savedContacts = decodedContacts
        }
        return savedContacts
    }
    
    class func contactExists(identifier: String) -> Bool {
        let contacts = getAllContacts()
        
        for person in contacts! {
            if person.identifier == identifier {
                return true
            }
        }
        return false
    }

    class func deleteContact(identifier: String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        var contacts = getAllContacts()
        
        // Iterate through contacts to find match by identifier
        for (index, person) in contacts!.enumerate() {
            if person.identifier == identifier {
                contacts?.removeAtIndex(index)
            }
        }
        
        // Encode data for storage
        let encodedData = NSKeyedArchiver.archivedDataWithRootObject(contacts!)
        defaults.setObject(encodedData, forKey: "savedContacts")
        defaults.synchronize()
    }

    class func login() {
//        print("Logging in -- logged in: \(loggedIn())")
        if !loggedIn() {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(true, forKey: "loggedIn")
            defaults.synchronize()
        }
    }
    
    class func logout() {
//        print("Logging Out -- logged in: \(loggedIn())")
        if loggedIn() {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(false, forKey: "loggedIn")
            defaults.synchronize()
        }
    }
    
    // Check if user is logged in
    class func loggedIn() -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
//        print("Logged in: \(defaults.boolForKey("loggedIn"))")
        return defaults.boolForKey("loggedIn")
    }
    
}
