//
//  FirebaseManager.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/24/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

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
    
    class func getUserById(userId: String, completionHandler: (userDict: NSDictionary?, error: NSError?) -> Void) {
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child("users").child(userId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let dict = snapshot.value! as? NSDictionary {
                 print("User retrieved by ID")
                completionHandler(userDict: dict, error: nil)
            }
            else {
                // No user to retrieve
                print("No user found in RTDB for userId")
                let error = NSError(domain: "UserRTDBErrorDomain", code: 2, userInfo: nil)
                completionHandler(userDict: nil, error: error)
            }
        }) { (error) in
            print("Error occurred while retrieving user by userId")
            completionHandler(userDict: nil, error: error)
        }
    }
    
    // Update user in real-time database with dictionary of changes
    class func updateUser(updates: NSDictionary, completionHandler: (error: NSError?) -> Void ) {
        if let user = FIRAuth.auth()?.currentUser {
            let userId = user.uid
            let databaseRef = FIRDatabase.database().reference()
            
            var updatesDict = updates as [NSObject : AnyObject]
            
            // Save image first
            if let imageData = updatesDict["profileImage"] as! NSData? {
                // Remove from dict before it saves illegal type
                updatesDict.removeValueForKey("profileImage")
                
                let filePath = "profileImage/\(user.uid)"
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                
                let storageRef = FIRStorage.storage().reference()
                
                // Storage image
                storageRef.child(filePath).putData(imageData, metadata: metadata, completion: { (metadata, error) in
                    if let error = error {
                        // Error
                        print("Error saving profile image: \(error.localizedDescription)")
                        completionHandler(error: error)
                    } else {
                        // Success - save photoURL
                        print("Saved user profile image -- attempting to update photo url")
                        
                        let fileUrl: String = (metadata?.downloadURLs![0].absoluteString)!
                        let changeRequestPhoto = user.profileChangeRequest()
                        changeRequestPhoto.photoURL = NSURL(string: fileUrl)
                        changeRequestPhoto.commitChangesWithCompletion({ (error) in
                            if let error = error {
                                // Error
                                print("Error completing profile photo URL change request: \(error.localizedDescription)")
                                completionHandler(error: error)
                            } else {
                                // Success
                                print("Saved user profile photo url")
                                // Update new dict for RTDB save
                                updatesDict["photoUrl"] = fileUrl
                                
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
                        })
                    }
                })
            }
            else {
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
                        deleteUserProfileImage({ (error) in
                            if let error = error {
                                completionHandler(error: error)
                            } else {
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
    
    private class func deleteUserProfileImage(completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let storageRef = FIRStorage.storage().reference()
            
            storageRef.child("profileImage").child(user.uid).deleteWithCompletion({ (error) in
                if let error = error {
                    // Error
                    if error.code == -13010 {
                        // Object does not exist -- proceed as if no error
                        print("User profile image does not exist -- proceed normally")
                        completionHandler(error: nil)
                    } else {
                        print("Error deleting user profile image -- code: \(error.code) , description: \(error.localizedDescription)")
                        completionHandler(error: error)
                    }
                } else {
                    // Success
                    print("Deleted user profile image")
                    completionHandler(error: nil)
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
            lookUpFamilyGroup(familyId, completionHandler: { (error, familyExists) in
                if let error = error {
                    // Error
                    completionHandler(error: error, newDatabaseRef: nil)
                } else {
                    if let familyExists = familyExists {
                        // Family does not exist
                        if !familyExists {
                            print("Family does not exist")
                            let familyError = NSError(domain: "familyIdError", code: 00004, userInfo: nil)
                            completionHandler(error: familyError, newDatabaseRef: nil)
                        } else {
                            // Family exists -- continue normally
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
                }
            })
//            getFamilyPassword(familyId, completionHandler: { (familyPassword, error) in
//                if let actualFamilyPassword = familyPassword {
//                    
//                    // Check that passwords match
//                    if actualFamilyPassword == password {
//                        
//                        getCurrentUser({ (userDict, error) in
//                            if let userInfo = userDict {
//                                let databaseRef = FIRDatabase.database().reference()
//                                
//                                // Remove key for save to family group
//                                let modifiedDict = userInfo.mutableCopy() as! NSMutableDictionary
//                                modifiedDict.removeObjectForKey("completedSignup")
//                                
//                                // Update current user and new family, and signUp status
//                                let childUpdates = ["/users/\(user.uid)/familyId": familyId,
//                                                    "/users/\(user.uid)/completedSignup": "true",
//                                                    "/users/\(user.uid)/admin": "false"]
//
//                                databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
//                                    if error != nil {
//                                        print("Error occurred while updating user with new family group values")
//                                        completionHandler(error: error, newDatabaseRef: nil)
//                                    }
//                                    else {
//                                        print("User family group values updated")
//                                        databaseRef.child("families").child(familyId).child("members").child(user.uid).setValue(modifiedDict, withCompletionBlock: { (secondError, secondDatabaseRef) in
//                                            if error != nil {
//                                                print("Error occurred while adding user to family")
//                                                completionHandler(error: secondError, newDatabaseRef: secondDatabaseRef)
//                                            }
//                                            else {
//                                                print("User added to family")
//                                                completionHandler(error: nil, newDatabaseRef: secondDatabaseRef)
//                                            }
//                                        })
//                                    }
//                                })
//                            }
//                        })
//                    }
//                    else {
//                        print("Incorrect password to join family: \(familyId)")
//                        let wrongPasswordError = NSError(domain: "Incorrect password", code: 3, userInfo: nil)
//                        completionHandler(error: wrongPasswordError, newDatabaseRef: nil)
//                    }
//                }
//            })
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
            // Reset unread messages
            AYNModel.sharedInstance.unreadMessagesCount = 0
            
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
                                                    
//                                                    if 
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
    class func updateFamilyMemberUserInfo(contactUserId: String, updates: NSDictionary, completionHandler: (error: NSError?) -> Void) {
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
                        
                        databaseRef.child("families").child(userFamilyId).child("members").child(userId).child("communicationInfo").child(contactUserId).updateChildValues(updatesDict, withCompletionBlock: { (error, newRef) in
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
    
    class func getFamilyMemberUserInfo(contactUserId: String, completionHandler: (error: NSError?, userInfo: NSDictionary?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            getCurrentUser({ (userDict, error) in
                if error != nil {
                    // Error
                    completionHandler(error: error, userInfo: nil)
                }
                else {
                    if let userFamilyId = userDict?.valueForKey("familyId") as? String {
                        let userId = user.uid
                        let databaseRef = FIRDatabase.database().reference()
                        
                        databaseRef.child("families").child(userFamilyId).child("members").child(userId).child("communicationInfo").child(contactUserId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                            if let dict = snapshot.value! as? NSDictionary {
                                print("Retrieved family member userInfo")
                                completionHandler(error: nil, userInfo: dict)
                            }
                        }) { (error) in
                            print("Error retrieving family member userInfo")
                            completionHandler(error: error, userInfo: nil)
                        }
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
    
    // MARK: - Messages
    class func sendNewMessage(receiverId: String, message: NSDictionary, completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            getCurrentUser({ (userDict, error) in
                if let error = error {
                    // Error
                    completionHandler(error: error)
                }
                else {
                    // Check for existing conversations
                    getConversationId(receiverId, completionHandler: { (error, conversationId) in
                        if let error = error {
                            // Error
                            completionHandler(error: error)
                        } else {
                            if let userFamilyId = userDict?.valueForKey("familyId") as? String {
                                
                                // Create var to change based on conversationId
                                let databaseRef = FIRDatabase.database().reference()
                                var key = ""
                                
                                if let conversationId = conversationId {
                                    // Existing conversation ID found
                                    key = databaseRef.child("families").child(userFamilyId).child("conversations").child(conversationId).key
                                } else {
                                    // No conversation ID found -- create new conversation between users
                                    key = databaseRef.child("families").child(userFamilyId).child("conversations").childByAutoId().key
                                    
                                }
                                
                                let messageKey = databaseRef.child("families").child(userFamilyId).child("conversations").child(key).childByAutoId().key
                                // Add current user ID to message object
                                let modifiedMessage = message.mutableCopy() as! NSMutableDictionary
                                modifiedMessage.setObject(user.uid, forKey: "senderId")
                                
                                let messageDict = [messageKey : modifiedMessage]
                                
                                let childUpdates = ["/families/\(userFamilyId)/conversations/\(key)": messageDict,
                                    "/users/\(user.uid)/conversations/\(key)": "true",
                                    "/users/\(receiverId)/conversations/\(key)": "true"] as [NSObject : AnyObject]
                                
                                databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                                    if error != nil {
                                        print("Error sending new message")
                                        completionHandler(error: error)
                                    }
                                    else {
                                        print("Sent new message")
                                        completionHandler(error: nil)
                                    }
                                })
                            }
                        }
                    })
                }
            })
        }
    }
    
    private class func getConversationId(receiverId: String, completionHandler: (error: NSError?, conversationId: String?) -> Void) {
        if (FIRAuth.auth()?.currentUser) != nil {
            getCurrentUser({ (userDict, error) in
                if let error = error {
                    // Error
                    completionHandler(error: error, conversationId: nil)
                } else {
                    // Get list of current user's conversations (by ID)
                    if let senderConversations = userDict?.objectForKey("conversations") as? NSDictionary {
                        // Lookup receiver
                        getUserById(receiverId, completionHandler: { (userDict, error) in
                            if let error = error {
                                // Error
                                completionHandler(error: error, conversationId: nil)
                            } else {
                                // Get list of receiver's conversations (by ID)
                                if let receiverConversations = userDict?.objectForKey("conversations") as? NSDictionary {
                                    if let senderConversationKeys = senderConversations.allKeys as [AnyObject]? {
                                        // Iterate through each key of sender to find matching conversation ID
                                        for key in senderConversationKeys {
                                            if receiverConversations.objectForKey(key) != nil {
                                                print("Sender keys: \(senderConversationKeys)")
                                                // Found matching conversation ID for both users
                                                if let conversationId = key as? String {
                                                    print("Retrieved conversation ID for users")
                                                    completionHandler(error: nil, conversationId: conversationId)
                                                }
                                            }
                                        }
                                        // No matching conversation ID found
                                        print("Could not find matching conversation ID for users")
                                        completionHandler(error: nil, conversationId: nil)
                                    }
                                } else {
                                    // Receiver has no saved conversations
                                    print("Receiver has no saved conversations")
                                    completionHandler(error: nil, conversationId: nil)
                                }
                            }
                        })
                    } else {
                        // Sender has no saved conversations
                        print("Sender has no saved conversations")
                        completionHandler(error: nil, conversationId: nil)
                    }
                }
            })
        }
    }
    
}
