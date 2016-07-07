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
                print("New user created successfully")
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
    
    // NEW
    class func getCurrentUser(completionHandler: (userDict: NSDictionary?, error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let userId = user.uid
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("users").child(userId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let dict = snapshot.value! as? NSDictionary {
//                    print("Current user retrieved")
                    completionHandler(userDict: dict, error: nil)
                }
            }) { (error) in
                print("Error occurred while retrieving current user")
                completionHandler(userDict: nil, error: error)
            }
        }
    }
    
    // NEW: Update user in real-time database with dictionary of changes
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
                    print("Successfully updated user -- Updating in family")
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
    
    // NEW: Helper func for updateUser
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
                                    print("Successfully updated user in family")
                                    completionHandler(error: nil)
                                }
                            })
                        }
                        // Key does not exist -- do not update
                        else {
                            print("familyId key does not exist -- skipping family update")
                            let error = NSError(domain: "familyIdError", code: 0, userInfo: nil)
                            completionHandler(error: error)
                        }
                    }
                }
            })
        }
    }
    
    // NEW: Delete current auth user, and entry in real time database and in family group
    class func deleteCurrentUser(completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            deleteUserFromFamily { (error, databaseRef) in
                // If user does not belong to family, proceed normally
                if error != nil {
                    if error?.code != 0 {
                        // Error
                        print("Error occurred while deleting account from family")
                        completionHandler(error: error)
                    }
                    
                }
//                else {
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
//                }
            }
        }
    }
    
    // NEW: Helper func for deleteCurrentUser
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
    
    // NEW: Helper func for deleteCurrentUser
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
            })
        }
    }
    
    // MARK: - Family Group Management
    
    // NEW
    class func createNewFamilyGroup(familyId: String, password: String, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            
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
//                                        "/families/\(familyId)/members/\(user.uid)/familyId": familyId,
//                                        "/families/\(familyId)/members/\(user.uid)/completedSignup": "true",
//                                        "/families/\(familyId)/members/\(user.uid)/admin": "true"]

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
    
    // NEW
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
                                        completionHandler(error: error, newDatabaseRef: databaseRef)
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
                                                completionHandler(error: secondError, newDatabaseRef: secondDatabaseRef)
                                            }
                                        })
                                    }
                                })
                            }
                        })
                    }
                    print("Incorrect password to join family: \(familyId)")
                    let wrongPasswordError = NSError(domain: "Incorrect password", code: 0, userInfo: nil)
                    completionHandler(error: wrongPasswordError, newDatabaseRef: nil)
                }
            })
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
    
    // NEW
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
    
}
