//
//  FirebaseManager.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/24/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class FirebaseManager: NSObject {
    
    // MARK: - User Management
    class func createNewUserWithEmail(email: String, password: String, completionHandler: (user:FIRUser?, error: NSError?) -> Void) {
        FIRAuth.auth()?.createUserWithEmail(email, password: password, completion: { (user, error) in
            if error != nil {
                print("There was an error creating user")
                completionHandler(user: user, error: error)
            }
            else {
                print("New user created")
                completionHandler(user: user, error: error)
            }
        })
    }
    
    class func getUserSignUpStatus(completionHandler: (status: String?, error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let userId = user.uid
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("users").child(userId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let signupStatus = snapshot.value!["completedSignup"] as? String {
                    print("User signup status retrieved")
                    completionHandler(status: signupStatus, error: nil)
                }
                else {
                    print("completedSignup field does not exist")
                    completionHandler(status: nil, error: nil)
                }
            }) { (error) in
                print("Error occurred while retrieving user signup status")
                completionHandler(status: nil, error: error)
            }
        }
    }

    class func getCurrentUser(completionHandler: (userDict: NSDictionary?, error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let userId = user.uid
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("users").child(userId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let dict = snapshot.value! as? NSDictionary {
//                    print("Current user retrieved")
                    completionHandler(userDict: dict, error: nil)
                }
                else {
                    // No user to retrieve
                    print("No user found in RTDB")
                    let error = NSError(domain: "UserRTDBErrorDomain", code: 2, userInfo: nil)
                    completionHandler(userDict: nil, error: error)
                }
            }) { (error) in
                print("Error occurred while retrieving current user")
                completionHandler(userDict: nil, error: error)
            }
        }
    }
    
    // Update user in real-time database with dictionary of changes
    class func updateUser(updates: NSDictionary, completionHandler: (error: NSError?) -> Void ) {
        if let user = FIRAuth.auth()?.currentUser {
            let userId = user.uid
            let databaseRef = FIRDatabase.database().reference()
            
            let updatesDict = updates as [NSObject : AnyObject]
            databaseRef.child("users").child(userId).updateChildValues(updatesDict, withCompletionBlock: { (error, newRef) in
                if error != nil {
                    print("Error updating user")
                    completionHandler(error: error)
                }
                else {
                    print("Updated user in RTDB -- Updating in family")
                    updateUserInFamily(updatesDict, completionHandler: { (error) in
                        if error != nil {
                            // Key does not exist -- proceed normally
                            if error?.code == 0 {
                                completionHandler(error: nil)
                            }
                            else {
                                // Error
                                completionHandler(error: error)
                            }
                        }
                        else {
                            // Success
                            completionHandler(error: nil)
                        }
                    })
                }
            })
        }
    }
    
    // Helper func for updateUser
    private class func updateUserInFamily(updates: NSDictionary, completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            getCurrentUser({ (userDict, error) in
                if error == nil {
                    if let userDict = userDict {
                        // Check if key exists yet
                        if let familyId = userDict.objectForKey("familyId") as? String {
                            let userId = user.uid
                            let databaseRef = FIRDatabase.database().reference()
                            let updatesDict = updates as [NSObject : AnyObject]
                            
                            databaseRef.child("families").child(familyId).child("members").child(userId).updateChildValues(updatesDict, withCompletionBlock: { (error, newRef) in
                                if error != nil {
                                    print("Error updating user in family")
                                    completionHandler(error: error)
                                }
                                else {
                                    print("Updated user in family")
                                    completionHandler(error: nil)
                                }
                            })
                        }
                        // Key does not exist -- do not update
                        else {
                            print("User does not belong to family -- skipping family update")
                            let error = NSError(domain: "familyIdError", code: 0, userInfo: nil)
                            completionHandler(error: error)
                        }
                    }
                }
            })
        }
    }
    
    // Delete current auth user, and entry in real time database and in family group
    class func deleteCurrentUser(completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            deleteUserFromFamily { (error, databaseRef) in
                // If user does not belong to family, proceed normally
                if error != nil {
                    // Check that user belongs to family and exists in RTDB
                    if error?.code != 0 && error?.code != 2 {
                        // Error
                        print("Error occurred while deleting account from family")
                        completionHandler(error: error)
                    }
                    // Delete account immediately since it cannot be found in RTDB
                    else if error?.code == 2 {
                        user.deleteWithCompletion({ (error) in
                            if error != nil {
                                // Error
                                print("Error occurred while deleting account: \(error)")
                                completionHandler(error: error)
                            }
                            else {
                                // Success
                                print("Account deleted")
                                completionHandler(error: nil)
                            }
                        })
                    }
                    
                }
                // Success
                deleteUserFromRTDB({ (error, databaseRef) in
                    if error != nil {
                        // Error
                        completionHandler(error: error)
                    }
                    else {
                        // Success
                        user.deleteWithCompletion({ (error) in
                            if error != nil {
                                // Error
                                print("Error occurred while deleting account: \(error)")
                                completionHandler(error: error)
                            }
                            else {
                                // Success
                                print("Account deleted")
                                completionHandler(error: nil)
                            }
                        })
                    }
                })
            }
        }
    }
    
    // Helper func for deleteCurrentUser
    private class func deleteUserFromRTDB(completionHandler: (error: NSError?, databaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("users").child(user.uid).removeValueWithCompletionBlock({ (error, oldRef) in
                if error != nil {
                    print("Error deleting user from real time database")
                    completionHandler(error: error, databaseRef: nil)
                }
                else {
                    print("User deleted from real time database")
                    completionHandler(error: nil, databaseRef: oldRef)
                }
            })
        }
    }
    
    // Helper func for deleteCurrentUser
    private class func deleteUserFromFamily(completionHandler: (error: NSError?, databaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            getCurrentUser({ (userDict, error) in
                if let userDict = userDict {
                    let databaseRef = FIRDatabase.database().reference()
                    
                    // Check if key exists yet
                    if let familyId = userDict.objectForKey("familyId") as? String {
                        
                        databaseRef.child("families").child(familyId).child("members").child(user.uid).removeValueWithCompletionBlock({ (error, oldRef) in
                            if error != nil {
                                print("Error deleting user from family group")
                                completionHandler(error: error, databaseRef: nil)
                            }
                            else {
                                print("User deleted from family group")
                                completionHandler(error: nil, databaseRef: oldRef)
                            }
                        })
                    }
                        // FamilyID does not exist
                    else {
                        print("User does not belong to family group -- skipping step")
                        let error = NSError(domain: "familyIdError", code: 0, userInfo: nil)
                        completionHandler(error: error, databaseRef: nil)
                    }
                }
                else if error != nil {
//                    print("error: \(error?.domain)")
                    completionHandler(error: error, databaseRef: nil)
                }
            })
        }
    }
    
    // MARK: - Family Group Management
    class func createNewFamilyGroup(familyId: String, password: String, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            // Check if family group already exists
            lookUpFamilyGroup(familyId, completionHandler: { (error, familyExists) in
                // No error
                if error == nil {
                    // Check that bool exists
                    if let familyExists = familyExists {
                        // Family already exists
                        if familyExists {
                           // Don't create new family
                            print("Family name already in use")
                            let error = NSError(domain: "ExistingFamilyGroupError", code: 00001, userInfo: nil)
                            completionHandler(error: error, newDatabaseRef: nil)
                        }
                        else {
                            getCurrentUser({ (userDict, error) in
                                if let userInfo = userDict {
                                    let databaseRef = FIRDatabase.database().reference()
                                    
                                    // Remove key for save to family group
                                    let modifiedDict = userInfo.mutableCopy() as! NSMutableDictionary
                                    modifiedDict.removeObjectForKey("completedSignup")
                                    modifiedDict["admin"] = "true"
                                    
                                    let familyToSave = ["password": password, "members":[user.uid: modifiedDict]]
                                    
                                    // Update current user and new family, and signup Status
                                    let childUpdates = ["/users/\(user.uid)/familyId": familyId,
                                        "/users/\(user.uid)/completedSignup": "true",
                                        "/users/\(user.uid)/admin": "true",
                                        "/families/\(familyId)": familyToSave]
                                    
                                    databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                                        if error != nil {
                                            print("Error creating new family group")
                                            completionHandler(error: error, newDatabaseRef: databaseRef)
                                        }
                                        else {
                                            print("New family group created -- joined Family: \(familyId)")
                                            completionHandler(error: error, newDatabaseRef: databaseRef)
                                        }
                                    })
                                }
                            })
                        }
                    }
                }
            })
        }
    }

    class func joinFamilyGroup(familyId: String, password: String, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            
            getFamilyPassword(familyId, completionHandler: { (familyPassword, error) in
                if let actualFamilyPassword = familyPassword {
                    
                    // Check that passwords match
                    if actualFamilyPassword == password {
                        
                        getCurrentUser({ (userDict, error) in
                            if let userInfo = userDict {
                                let databaseRef = FIRDatabase.database().reference()
                                
                                // Remove key for save to family group
                                let modifiedDict = userInfo.mutableCopy() as! NSMutableDictionary
                                modifiedDict.removeObjectForKey("completedSignup")
                                
                                // Update current user and new family, and signUp status
                                let childUpdates = ["/users/\(user.uid)/familyId": familyId,
                                                    "/users/\(user.uid)/completedSignup": "true",
                                                    "/users/\(user.uid)/admin": "false"]

                                databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                                    if error != nil {
                                        print("Error occurred while updating user with new family group values")
                                        completionHandler(error: error, newDatabaseRef: nil)
                                    }
                                    else {
                                        print("User family group values updated")
                                        databaseRef.child("families").child(familyId).child("members").child(user.uid).setValue(modifiedDict, withCompletionBlock: { (secondError, secondDatabaseRef) in
                                            if error != nil {
                                                print("Error occurred while adding user to family")
                                                completionHandler(error: secondError, newDatabaseRef: secondDatabaseRef)
                                            }
                                            else {
                                                print("User added to family")
                                                completionHandler(error: nil, newDatabaseRef: secondDatabaseRef)
                                            }
                                        })
                                    }
                                })
                            }
                        })
                    }
                    else {
                        print("Incorrect password to join family: \(familyId)")
                        let wrongPasswordError = NSError(domain: "Incorrect password", code: 3, userInfo: nil)
                        completionHandler(error: wrongPasswordError, newDatabaseRef: nil)
                    }
                }
            })
        }
    }

    class func lookUpFamilyGroup(familyId: String, completionHandler: (error: NSError?, familyExists: Bool?) -> Void) {
        let databaseRef = FIRDatabase.database().reference()
        
        databaseRef.child("families").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let groupExists = snapshot.hasChild(familyId) as Bool? {
                print("Family group exists: \(groupExists)")
                completionHandler(error: nil, familyExists: groupExists)
            }
        }) { (error) in
            print("Error occurred while looking up family group")
            completionHandler(error: error, familyExists: nil)
        }
    }
    
    class func getFamilyPassword(familyId: String, completionHandler: (password: String?, error: NSError?) -> Void) {
        let databaseRef = FIRDatabase.database().reference()
        
        databaseRef.child("families").child(familyId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let familyPassword = snapshot.value!["password"] as? String {
                print("Family password retrieved")
                completionHandler(password: familyPassword, error: nil)
            }
        }) { (error) in
            print("Error occurred while retrieving family password")
            completionHandler(password: nil, error: error)
        }
    }

    class func getFamilyMembers(completionHandler: (members: [Contact]?, error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser{
            getCurrentUser { (userDict, error) in
                if error != nil {
                    // Error
                    completionHandler(members: nil, error: error)
                }
                else {
                    let userId = user.uid
                    // Search for members using current user's familyId
                    if let userFamilyId = userDict?.valueForKey("familyId") as? String {
                        let databaseRef = FIRDatabase.database().reference()
                        var membersArr = [Contact]()
                        
                        databaseRef.child("families").child(userFamilyId).child("members").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                            if let dict = snapshot.value! as? NSDictionary {
                                for (key, value) in dict {
                                    if let uId = key as? String {
                                        // Prevent adding current user to array
                                        if uId != userId {
                                            if let memberDict = value as? NSDictionary {
                                                if let contact = Contact(uID: uId, userDict: memberDict) {
                                                    membersArr.append(contact)
                                                }
                                            }
                                        }
                                    }
                                }
                                print("Family members retrieved")
                                completionHandler(members: membersArr, error: nil)
                            }
                        }) { (error) in
                            print("Error occurred while retrieving family members")
                            
                        }
                    }
                }
            }
        }
    }
    
    // Custom UserInfo unique to each familyMember's instance of their relationship to others
    class func updateFamilyMemberUserInfo(contactId: String, updates: NSDictionary, completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            getCurrentUser({ (userDict, error) in
                if error != nil {
                    // Error
                    completionHandler(error: error)
                }
                else {
                    if let userFamilyId = userDict?.valueForKey("familyId") as? String {
                        let userId = user.uid
                        let databaseRef = FIRDatabase.database().reference()
                    
                        let updatesDict = updates as [NSObject : AnyObject]
                        
                        databaseRef.child("families").child(userFamilyId).child("members").child(userId).child("communicationInfo").child(contactId).updateChildValues(updatesDict, withCompletionBlock: { (error, newRef) in
                            if error != nil {
                                // Error
                                print("Error updating family member userInfo")
                                completionHandler(error: error)
                            }
                            else {
                                // Success
                                print("Updated family member userInfo")
                                completionHandler(error: nil)
                            }
                        })
                    }
                }
            })  
        }
    }
    
    // MARK: - Reminders
    class func createFamilyReminder(reminder: NSDictionary, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        getCurrentUser { (userDict, error) in
            if error != nil {
                // Error
                completionHandler(error: error, newDatabaseRef: nil)
            }
            else {
                // Get user family id to save reminder
                if let userFamilyId = userDict?.valueForKey("familyId") as? String {
                    let databaseRef = FIRDatabase.database().reference()
                    
                    databaseRef.child("families").child(userFamilyId).child("reminders").childByAutoId().setValue(reminder, withCompletionBlock: { (error, newDatabaseRef) in
                        if error != nil {
                            // Error
                            print("Error creating reminder")
                            completionHandler(error: error, newDatabaseRef: nil)
                        }
                        else {
                            // Success
                            print("Created new family reminder")
                            completionHandler(error: nil, newDatabaseRef: newDatabaseRef)
                        }
                    })
                }
            }
        }
    }
    
    class func deleteFamilyReminder(reminderId: String, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        getCurrentUser { (userDict, error) in
            if error != nil {
                // Error
                completionHandler(error: error, newDatabaseRef: nil)
            }
            else {
                // Get user family id to save reminder
                if let userFamilyId = userDict?.valueForKey("familyId") as? String {
                    let databaseRef = FIRDatabase.database().reference()
                    
                    databaseRef.child("families").child(userFamilyId).child("reminders").child(reminderId).removeValueWithCompletionBlock({ (error, oldRef) in
                        if error != nil {
                            print("Error deleting reminder")
                            completionHandler(error: error, newDatabaseRef: nil)
                        }
                        else {
                            print("Reminder deleted")
                            completionHandler(error: nil, newDatabaseRef: oldRef)
                        }
                    })
                }
            }
        }
    }
    
    class func completeFamilyReminder(reminder: Reminder, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        getCurrentUser { (userDict, error) in
            if error != nil {
                completionHandler(error: error, newDatabaseRef: nil)
            }
            else {
                if let userFamilyId = userDict?.valueForKey("familyId") as? String {
                    let databaseRef = FIRDatabase.database().reference()
                    
                    let modifiedReminderDict = reminder.asDict().mutableCopy() as! NSMutableDictionary
                    modifiedReminderDict["completedDate"] = NSDate().timeIntervalSince1970.description

                    let childUpdates = ["/families/\(userFamilyId)/completedReminders/\(reminder.id)": modifiedReminderDict]
                    
                    databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                        if error != nil {
                            print("Error occurred while marking reminder as complete")
                            completionHandler(error: error, newDatabaseRef: nil)
                        }
                        else {
                            print("Reminder completed -- deleting from old location")
                            deleteFamilyReminder(reminder.id, completionHandler: { (error, newDatabaseRef) in
                                if error != nil {
                                    completionHandler(error: error, newDatabaseRef: nil)
                                }
                                else {
                                    completionHandler(error: nil, newDatabaseRef: newDatabaseRef)
                                }
                            })
                        }
                    })
                }
            }
        }
    }
    
    class func getCompletedFamilyReminders(completionHandler: (completedReminders: [Reminder]?, error: NSError?) -> Void) {
        getCurrentUser { (userDict, error) in
            if error != nil {
                // Error
                completionHandler(completedReminders: nil, error: error)
            }
            else {
                if let userFamilyId = userDict?.valueForKey("familyId") as? String {
                    let databaseRef = FIRDatabase.database().reference()
                    var remindersArr = [Reminder]()
                    
                    databaseRef.child("families").child(userFamilyId).child("completedReminders").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                        if let dict = snapshot.value! as? NSDictionary {
                            for (key, value) in dict {
                                if let reminderId = key as? String {
                                    if let reminderDict = value as? NSDictionary {
                                        if let completedReminder = Reminder(reminderId: reminderId, reminderDict: reminderDict) {
                                            remindersArr.append(completedReminder)
                                        }
                                    }
                                }
                            }
                            print("Completed reminders retrieved")
                            completionHandler(completedReminders: remindersArr, error: nil)
                        }
                    }) { (error) in
                        print("Error occurred while retrieving completed reminders")
                        
                    }
                }
            }
        }
    }
    
}
