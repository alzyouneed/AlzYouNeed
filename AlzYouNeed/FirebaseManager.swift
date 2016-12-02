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
    class func createNewUserWithEmail(_ email: String, password: String, completionHandler: @escaping (_ user:FIRUser?, _ error: NSError?) -> Void) {
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print("There was an error creating user")
                completionHandler(user, error as NSError?)
            }
            else {
                print("New user created")
                completionHandler(user, error as NSError?)
            }
        })
    }
    
    class func getUserSignUpStatus(_ completionHandler: @escaping (_ status: String?) -> Void) {
        if AYNModel.sharedInstance.currentUser != nil {
            if let signupStatus = AYNModel.sharedInstance.currentUser?.value(forKey: "completedSignup") as? String {
                print("User signup status retrieved")
                completionHandler(signupStatus)
            } else {
                print("User signup field does not exist")
                completionHandler(nil)
            }
        }
    }

    class func getCurrentUser(_ completionHandler: @escaping (_ userDict: NSDictionary?, _ error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let userId = user.uid
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("users").child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
                if let dict = snapshot.value! as? NSDictionary {
                    // Used by UserDefaults to check auth of saved user before loading
                    dict.setValue(snapshot.key, forKey: "userId")
                    UserDefaultsManager.saveCurrentUser(_user: dict)
                    AYNModel.sharedInstance.currentUser = dict
                    
                    completionHandler(dict, nil)
                }
                else {
                    // No user to retrieve
                    print("No user found in RTDB")
                    let error = NSError(domain: "UserRTDBErrorDomain", code: 2, userInfo: nil)
                    completionHandler(nil, error)
                }
            }) { (error) in
                print("Error occurred while retrieving current user")
                completionHandler(nil, error as NSError?)
            }
        }
    }
    
    class func getUserById(_ userId: String, completionHandler: @escaping (_ userDict: NSDictionary?, _ error: NSError?) -> Void) {
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child("users").child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dict = snapshot.value! as? NSDictionary {
                 print("User retrieved by ID")
                completionHandler(dict, nil)
            }
            else {
                // No user to retrieve
                print("No user found in RTDB for userId")
                let error = NSError(domain: "UserRTDBErrorDomain", code: 2, userInfo: nil)
                completionHandler(nil, error)
            }
        }) { (error) in
            print("Error occurred while retrieving user by userId")
            completionHandler(nil, error as NSError?)
        }
    }
    
    // Update user in real-time database with dictionary of changes
    class func updateUser(_ updates: NSDictionary, completionHandler: @escaping (_ error: NSError?) -> Void ) {
        if let user = FIRAuth.auth()?.currentUser {
            let userId = user.uid
            let databaseRef = FIRDatabase.database().reference()
            
            var updatesDict = updates as! [AnyHashable: Any]
            
            // Save image first
            if let imageData = updatesDict["profileImage"] as! Data? {
                // Remove from dict before it saves illegal type
                updatesDict.removeValue(forKey: "profileImage")
                
                let filePath = "profileImage/\(user.uid)"
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                
                let storageRef = FIRStorage.storage().reference()
                
                // Storage image
                storageRef.child(filePath).put(imageData, metadata: metadata, completion: { (metadata, error) in
                    if let error = error {
                        // Error
                        print("Error saving profile image: \(error.localizedDescription)")
                        completionHandler(error as NSError?)
                    } else {
                        // Success - save photoURL
                        print("Saved user profile image -- attempting to update photo url")
                        
                        let fileUrl: String = (metadata?.downloadURLs![0].absoluteString)!
                        let changeRequestPhoto = user.profileChangeRequest()
                        changeRequestPhoto.photoURL = URL(string: fileUrl)
                        changeRequestPhoto.commitChanges(completion: { (error) in
                            if let error = error {
                                // Error
                                print("Error completing profile photo URL change request: \(error.localizedDescription)")
                                completionHandler(error as NSError?)
                            } else {
                                // Success
                                print("Saved user profile photo url")
                                // Update new dict for RTDB save
                                updatesDict["photoUrl"] = fileUrl
                                
                                databaseRef.child("users").child(userId).updateChildValues(updatesDict, withCompletionBlock: { (error, newRef) in
                                    if error != nil {
                                        print("Error updating user")
                                        completionHandler(error as NSError?)
                                    }
                                    else {
                                        print("Updated user in RTDB -- Updating in family 1")
                                        updateUserInFamily(updatesDict as NSDictionary, completionHandler: { (error) in
                                            if error != nil {
                                                // Key does not exist -- proceed normally
                                                if error?.code == 0 {
                                                    completionHandler(nil)
                                                }
                                                else {
                                                    // Error
                                                    completionHandler(error)
                                                }
                                            }
                                            else {
                                                // Success
                                                completionHandler(nil)
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
                        completionHandler(error as NSError?)
                    }
                    else {
                        print("Updated user in RTDB -- Updating in family 2")
                        updateUserInFamily(updatesDict as NSDictionary, completionHandler: { (error) in
                            if error != nil {
                                // Key does not exist -- proceed normally
                                if error?.code == 0 {
                                    completionHandler(nil)
                                }
                                else {
                                    // Error
                                    completionHandler(error)
                                }
                            }
                            else {
                                // Success
                                completionHandler(nil)
                            }
                        })
                    }
                })
            }
        }
    }
    
    // Helper func for updateUser
    fileprivate class func updateUserInFamily(_ updates: NSDictionary, completionHandler: @escaping (_ error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            if AYNModel.sharedInstance.currentUser != nil {
                // Check if key exists yet
                if let familyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let userId = user.uid
                    let databaseRef = FIRDatabase.database().reference()
                    let updatesDict = updates as! [AnyHashable: Any]
                    
                    databaseRef.child("families").child(familyId).child("members").child(userId).updateChildValues(updatesDict, withCompletionBlock: { (error, newRef) in
                        if error != nil {
                            print("Error updating user in family")
                            completionHandler(error as NSError?)
                        }
                        else {
                            print("Updated user in family")
                            completionHandler(nil)
                        }
                    })
                }
                    // Key does not exist -- do not update
                else {
                    print("User does not belong to family -- skipping family update")
                    let error = NSError(domain: "familyIdError", code: 0, userInfo: nil)
                    completionHandler(error)
                }
            } else {
                print("Onboarding -- User does not belong to family -- skipping family update")
                let error = NSError(domain: "familyIdError", code: 0, userInfo: nil)
                completionHandler(error)
            }
        }
    }

    // Delete current auth user, and entry in real time database and in family group
    class func deleteCurrentUser(_ completionHandler: @escaping (_ error: NSError?) -> Void) {
        print("FirebaseManager: Deleting current user")
        if let user = FIRAuth.auth()?.currentUser {
            deleteUserFromFamily { (error, databaseRef) in
                // If user does not belong to family, proceed normally
                if error != nil {
                    // Check that user belongs to family and exists in RTDB
                    if error?.code != 0 && error?.code != 2 {
                        // Error
                        print("Error occurred while deleting account from family")
                        completionHandler(error)
                    }
                    // Delete account immediately since it cannot be found in RTDB
                    else if error?.code == 2 {
                        user.delete(completion: { (error) in
                            if error != nil {
                                // Error
                                print("Error occurred while deleting account: \(error)")
                                completionHandler(error as NSError?)
                            }
                            else {
                                // Success
                                print("Account deleted")
                                completionHandler(nil)
                            }
                        })
                    }
                }
                // Success
                deleteUserFromRTDB({ (error, databaseRef) in
                    if error != nil {
                        // Error
                        completionHandler(error)
                    }
                    else {
                        deleteUserProfileImage({ (error) in
                            if let error = error {
                                completionHandler(error)
                            } else {
                                // Success
                                user.delete(completion: { (error) in
                                    if error != nil {
                                        // Error
                                        print("Error occurred while deleting account: \(error)")
                                        completionHandler(error as NSError?)
                                    }
                                    else {
                                        // Success
                                        print("Account deleted")
                                        completionHandler(nil)
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
    fileprivate class func deleteUserFromRTDB(_ completionHandler: @escaping (_ error: NSError?, _ databaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("users").child(user.uid).removeValue(completionBlock: { (error, oldRef) in
                if error != nil {
                    print("Error deleting user from real time database")
                    completionHandler(error as NSError?, nil)
                }
                else {
                    print("User deleted from real time database")
                    completionHandler(nil, oldRef)
                }
            })
        }
    }
    
    // Helper func for deleteCurrentUser
    fileprivate class func deleteUserFromFamily(_ completionHandler: @escaping (_ error: NSError?, _ databaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            if AYNModel.sharedInstance.currentUser != nil {
                let databaseRef = FIRDatabase.database().reference()
                
                // Check if key exists yet
                if let familyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    
                    databaseRef.child("families").child(familyId).child("members").child(user.uid).removeValue(completionBlock: { (error, oldRef) in
                        if error != nil {
                            print("Error deleting user from family group")
                            completionHandler(error as NSError?, nil)
                        }
                        else {
                            print("User deleted from family group")
                            completionHandler(nil, oldRef)
                        }
                    })
                }
                    // FamilyID does not exist
                else {
                    print("User does not belong to family group -- skipping step")
                    let error = NSError(domain: "familyIdError", code: 0, userInfo: nil)
                    completionHandler(error, nil)
                }
            }
        }
    }

    fileprivate class func deleteUserProfileImage(_ completionHandler: @escaping (_ error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let storageRef = FIRStorage.storage().reference()
            
            storageRef.child("profileImage").child(user.uid).delete(completion: { (error) in
                if let error = error {
                    // Error
                    if error._code == -13010 {
                        // Object does not exist -- proceed as if no error
                        print("User profile image does not exist -- proceed normally")
                        completionHandler(nil)
                    } else {
                        print("Error deleting user profile image -- code: \(error._code) , description: \(error.localizedDescription)")
                        completionHandler(error as NSError?)
                    }
                } else {
                    // Success
                    print("Deleted user profile image")
                    completionHandler(nil)
                }
            })
        }
    }
    
    // MARK: - Family Group Management
    class func createNewFamilyGroup(_ familyId: String, password: String, completionHandler: @escaping (_ error: NSError?, _ newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            // Check if family group already exists
            lookUpFamilyGroup(familyId, completionHandler: { (error, familyExists) in
                if error != nil {
                    completionHandler(error, nil)
                } else {
                    if let familyExists = familyExists {
                        if familyExists {
                            // Family exists - don't create new one
                            print("Family name already in use")
                            let error = NSError(domain: "ExistingFamilyGroupError", code: 00001, userInfo: nil)
                            completionHandler(error, nil)
                        } else {
                            // Family name is free
                            getCurrentUser({ (userDict, error) in
                                if error != nil {
                                    completionHandler(error, nil)
                                } else {
                                    if let userDict = userDict {
                                        let databaseRef = FIRDatabase.database().reference()
                                        let modifiedDict = userDict.mutableCopy() as! NSMutableDictionary
                                        modifiedDict["admin"] = "true"
                                        let familyToSave = ["password": password, "members":[user.uid: modifiedDict], "notepad" : "Store your notes here!"] as [String : Any]
                                        
                                        // Update current user and new family, and signup Status
                                        let childUpdates = ["/users/\(user.uid)/familyId": familyId,
                                                            "/users/\(user.uid)/completedSignup": "true",
                                                            "/users/\(user.uid)/admin": "true",
                                                            "/families/\(familyId)": familyToSave] as [String : Any]
                                        
                                        databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                                            if error != nil {
                                                print("Error creating new family group")
                                                completionHandler(error as NSError?, databaseRef)
                                            }
                                            else {
                                                print("New family group created -- joined Family: \(familyId)")
                                                AYNModel.sharedInstance.currentUser = modifiedDict
                                                completionHandler(error as NSError?, databaseRef)
                                            }
                                        })
                                    }
                                }
                            })
                        }
                    }
                }
            })
        }
    }
    
    class func joinFamilyGroup(_ familyId: String, password: String, completionHandler: @escaping (_ error: NSError?, _ newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            lookUpFamilyGroup(familyId, completionHandler: { (error, familyExists) in
                if error != nil {
                    completionHandler(error, nil)
                } else {
                    if let familyExists = familyExists {
                        if familyExists {
                            // Family exists -- check password
                            getFamilyPassword(familyId, completionHandler: { (familyPassword, error) in
                                if error != nil {
                                    completionHandler(error, nil)
                                } else {
                                    if let familyPassword = familyPassword {
                                        // Compare password to user input
                                        if password == familyPassword {
                                            // Password correct
                                            getCurrentUser({ (userDict, error) in
                                                if error != nil {
                                                    completionHandler(error, nil)
                                                } else {
                                                    if let userDict = userDict {
                                                        let databaseRef = FIRDatabase.database().reference()
                                                        // Update current user and new family, and signUp status
                                                        let childUpdates = ["/users/\(user.uid)/familyId": familyId,
                                                                            "/users/\(user.uid)/completedSignup": "true",
                                                                            "/users/\(user.uid)/admin": "false"]
                                                        
                                                        databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                                                            if error != nil {
                                                                print("Error occurred while updating user with new family group values")
                                                                completionHandler(error as NSError?, nil)
                                                            }
                                                            else {
                                                                print("User family group values updated")
                                                                databaseRef.child("families").child(familyId).child("members").child(user.uid).setValue(userDict, withCompletionBlock: { (secondError, secondDatabaseRef) in
                                                                    if error != nil {
                                                                        print("Error occurred while adding user to family")
                                                                        completionHandler(secondError as NSError?, secondDatabaseRef)
                                                                    }
                                                                    else {
                                                                        print("User added to family")
                                                                        AYNModel.sharedInstance.currentUser = userDict
                                                                        completionHandler(nil, secondDatabaseRef)
                                                                    }
                                                                })
                                                            }
                                                        })
                                                    }
                                                }
                                            })
                                            
                                        } else {
                                            // Password incorrect
                                            print("Incorrect password to join family: \(familyId)")
                                            let wrongPasswordError = NSError(domain: "Incorrect password", code: 3, userInfo: nil)
                                            completionHandler(wrongPasswordError, nil)
                                        }
                                    }
                                }
                            })
                        } else {
                            // Family does not exist
                            print("Family does not exist")
                            let familyError = NSError(domain: "familyIdError", code: 00004, userInfo: nil)
                            completionHandler(familyError, nil)
                        }
                    }
                }
            })
            
        }
    }

    class func lookUpFamilyGroup(_ familyId: String, completionHandler: @escaping (_ error: NSError?, _ familyExists: Bool?) -> Void) {
        let databaseRef = FIRDatabase.database().reference()
        
        databaseRef.child("families").observeSingleEvent(of: .value, with: { (snapshot) in
            if let groupExists = snapshot.hasChild(familyId) as Bool? {
                print("Family group exists: \(groupExists)")
                completionHandler(nil, groupExists)
            }
        }) { (error) in
            print("Error occurred while looking up family group")
            completionHandler(error as NSError?, nil)
        }
    }
    
    class func getFamilyPassword(_ familyId: String, completionHandler: @escaping (_ password: String?, _ error: NSError?) -> Void) {
        let databaseRef = FIRDatabase.database().reference()
        
        databaseRef.child("families").child(familyId).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dict = snapshot.value as? NSDictionary, let familyPassword = dict["password"] as? String {
            // if let familyPassword = snapshot.value!["password"] as? String {  SWIFT 3 CHANGE
                print("Family password retrieved")
                completionHandler(familyPassword, nil)
            }
        }) { (error) in
            print("Error occurred while retrieving family password")
            completionHandler(nil, error as NSError?)
        }
    }

    class func getFamilyMembers(_ completionHandler: @escaping (_ members: [Contact]?, _ error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser{
            
            if AYNModel.sharedInstance.currentUser != nil {
                let userId = user.uid
                // Search for members using current user's familyId
                if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let databaseRef = FIRDatabase.database().reference()
                    var membersArr = [Contact]()
                    
                    databaseRef.child("families").child(userFamilyId).child("members").observeSingleEvent(of: .value, with: { (snapshot) in
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
                            completionHandler(membersArr, nil)
                        }
                    }) { (error) in
                        print("Error occurred while retrieving family members")
                        
                    }
                }
            }
        }
    }
    
    // Custom UserInfo unique to each familyMember's instance of their relationship to others
    class func updateFamilyMemberUserInfo(_ contactUserId: String, updates: NSDictionary, completionHandler: @escaping (_ error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            if AYNModel.sharedInstance.currentUser != nil {
                if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let userId = user.uid
                    let databaseRef = FIRDatabase.database().reference()
                    
                    let updatesDict = updates as! [AnyHashable: Any]
                    
                    databaseRef.child("families").child(userFamilyId).child("members").child(userId).child("communicationInfo").child(contactUserId).updateChildValues(updatesDict, withCompletionBlock: { (error, newRef) in
                        if error != nil {
                            // Error
                            print("Error updating family member userInfo")
                            completionHandler(error as NSError?)
                        }
                        else {
                            // Success
                            print("Updated family member userInfo")
                            completionHandler(nil)
                        }
                    })
                }
            }
        }
    }
    
    class func getFamilyMemberUserInfo(_ contactUserId: String, completionHandler: @escaping (_ error: NSError?, _ userInfo: NSDictionary?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            if AYNModel.sharedInstance.currentUser != nil {
                if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let userId = user.uid
                    let databaseRef = FIRDatabase.database().reference()
                    
                    databaseRef.child("families").child(userFamilyId).child("members").child(userId).child("communicationInfo").child(contactUserId).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let dict = snapshot.value! as? NSDictionary {
                            print("Retrieved family member userInfo")
                            completionHandler(nil, dict)
                        }
                    }) { (error) in
                        print("Error retrieving family member userInfo")
                        completionHandler(error as NSError?, nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Reminders
    class func createFamilyReminder(_ reminder: NSDictionary, completionHandler: @escaping (_ error: NSError?, _ newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if AYNModel.sharedInstance.currentUser != nil {
            // Get user family id to save reminder
            if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                let databaseRef = FIRDatabase.database().reference()
                
                databaseRef.child("families").child(userFamilyId).child("reminders").childByAutoId().setValue(reminder, withCompletionBlock: { (error, newDatabaseRef) in
                    if error != nil {
                        // Error
                        print("Error creating reminder")
                        completionHandler(error as NSError?, nil)
                    }
                    else {
                        // Success
                        print("Created new family reminder")
                        completionHandler(nil, newDatabaseRef)
                    }
                })
            }
        }
    }
    
    class func deleteFamilyReminder(_ reminderId: String, completionHandler: @escaping (_ error: NSError?, _ newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if AYNModel.sharedInstance.currentUser != nil {
            // Get user family id to save reminder
            if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                let databaseRef = FIRDatabase.database().reference()
                
                databaseRef.child("families").child(userFamilyId).child("reminders").child(reminderId).removeValue(completionBlock: { (error, oldRef) in
                    if error != nil {
                        print("Error deleting reminder")
                        completionHandler(error as NSError?, nil)
                    }
                    else {
                        print("Reminder deleted")
                        completionHandler(nil, oldRef)
                    }
                })
            }
        }
    }
    
    class func completeFamilyReminder(_ reminder: Reminder, completionHandler: @escaping (_ error: NSError?, _ newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if AYNModel.sharedInstance.currentUser != nil {
            if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                let databaseRef = FIRDatabase.database().reference()
                
                var modifiedReminderDict = reminder.asDict()
                
                modifiedReminderDict["completedDate"] = Date().timeIntervalSince1970.description
                
                let childUpdates = ["/families/\(userFamilyId)/completedReminders/\(reminder.id!)": modifiedReminderDict]
                
                databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                    if error != nil {
                        print("Error occurred while marking reminder as complete")
                        completionHandler(error as NSError?, nil)
                    }
                    else {
                        print("Reminder completed -- deleting from old location")
                        deleteFamilyReminder(reminder.id, completionHandler: { (error, newDatabaseRef) in
                            if error != nil {
                                completionHandler(error, nil)
                            }
                            else {
                                completionHandler(nil, newDatabaseRef)
                            }
                        })
                    }
                })
            }
        }
    }
    
    class func getCompletedFamilyReminders(_ completionHandler: @escaping (_ completedReminders: [Reminder]?, _ error: NSError?) -> Void) {
        if AYNModel.sharedInstance.currentUser != nil {
            if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                let databaseRef = FIRDatabase.database().reference()
                var remindersArr = [Reminder]()
                
                databaseRef.child("families").child(userFamilyId).child("completedReminders").observeSingleEvent(of: .value, with: { (snapshot) in
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
                        completionHandler(remindersArr, nil)
                    }
                }) { (error) in
                    print("Error occurred while retrieving completed reminders")
                    
                }
            }
        }
    }
    
    // MARK: - Messages
    class func sendNewMessage(_ receiverId: String, conversationId: String, message: NSDictionary, completionHandler: @escaping (_ error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            if AYNModel.sharedInstance.currentUser != nil {
                if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let databaseRef = FIRDatabase.database().reference()
                    let messageKey = databaseRef.child("families").child(userFamilyId).child("conversations").child(conversationId).childByAutoId().key
                    
                    // Add current user ID to message object
                    let modifiedMessage = message.mutableCopy() as! NSMutableDictionary
                    modifiedMessage.setObject(user.uid, forKey: "senderId" as NSCopying)
                    
                    let favoritedDict = [user.uid : "false", receiverId : "false"]
                    modifiedMessage.setObject(favoritedDict, forKey: "favorited" as NSCopying)
                    
                    databaseRef.child("families").child(userFamilyId).child("conversations").child(conversationId).child(messageKey).setValue(modifiedMessage, withCompletionBlock: { (error, newDatabaseRef) in
                        if error != nil {
                            // Error
                            print("Error sending message")
                            completionHandler(error as NSError?)
                        }
                        else {
                            // Success
                            print("Sent new message")
                            completionHandler(nil)
                        }
                    })
                }
            }
        }
    }
    
    class func favoriteMessage(_ conversationId: String, messageId: String, favorited: String, completionHandler: @escaping (_ error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            if AYNModel.sharedInstance.currentUser != nil {
                if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let databaseRef = FIRDatabase.database().reference()
                    
                    let childUpdates = [user.uid : favorited]
                    databaseRef.child("families").child(userFamilyId).child("conversations").child(conversationId).child(messageId).updateChildValues(childUpdates, withCompletionBlock: { (error, newDatabaseRef) in
                        if let error = error {
                            // Error
                            print("Error updating favorite value for message")
                            completionHandler(error as NSError?)
                        } else {
                            // Success
                            print("Updated favorite value for message")
                            completionHandler(nil)
                        }
                    })
                }
            }
        }
    }
    
    class func getConversationId(_ familyId: String, receiverId: String, completionHandler: @escaping (_ error: NSError?, _ conversationId: String?) -> Void) {
        if (FIRAuth.auth()?.currentUser) != nil {
            if AYNModel.sharedInstance.currentUser != nil {
                // Get list of current user's conversations (by ID)
                // Must use getCurrentUser to ensure most up-to-date information (newly created conversations)
                getCurrentUser({ (userDict, error) in
                    if error != nil {
                        completionHandler(error, nil)
                    } else {
                        if let userDict = userDict {
                            if let senderConversations = userDict.object(forKey: "conversations") as? NSDictionary {
                                //                            if let senderConversations = AYNModel.sharedInstance.currentUser?.object(forKey: "conversations") as? NSDictionary {
                                // Lookup receiver
                                getUserById(receiverId, completionHandler: { (userDict, error) in
                                    if let error = error {
                                        // Error
                                        completionHandler(error, nil)
                                    } else {
                                        // Get list of receiver's conversations (by ID)
                                        if let receiverConversations = userDict?.object(forKey: "conversations") as? NSDictionary {
                                            if let senderConversationKeys = senderConversations.allKeys as [AnyObject]? {
                                                // Iterate through each key of sender to find matching conversation ID
                                                for key in senderConversationKeys {
                                                    if receiverConversations.object(forKey: key) != nil {
                                                        //                                                print("Sender keys: \(senderConversationKeys)")
                                                        // Found matching conversation ID for both users
                                                        if let conversationId = key as? String {
                                                            print("Found existing conversation ID for users")
                                                            completionHandler(nil, conversationId)
                                                            return
                                                        }
                                                    }
                                                }
                                                // No matching conversation ID found
                                                print("Could not find matching conversation ID for users -- creating new conversation")
                                                // Create ID here
                                                createNewConversation(receiverId, familyId: familyId, completionHandler: { (error, conversationId) in
                                                    if let error = error {
                                                        // Error
                                                        completionHandler(error, nil)
                                                    } else {
                                                        // Success
                                                        completionHandler(nil, conversationId)
                                                    }
                                                })
                                            }
                                        } else {
                                            // Receiver has no saved conversations
                                            print("Receiver has no saved conversations -- creating new conversation")
                                            // Create ID here
                                            createNewConversation(receiverId, familyId: familyId, completionHandler: { (error, conversationId) in
                                                if let error = error {
                                                    // Error
                                                    completionHandler(error, nil)
                                                } else {
                                                    // Success
                                                    completionHandler(nil, conversationId)
                                                }
                                            })
                                        }
                                    }
                                })
                            } else {
                                // Sender has no saved conversations
                                print("Sender has no saved conversations -- creating new conversation")
                                // Create ID here
                                createNewConversation(receiverId, familyId: familyId, completionHandler: { (error, conversationId) in
                                    if let error = error {
                                        // Error
                                        completionHandler(error, nil)
                                    } else {
                                        // Success
                                        completionHandler(nil, conversationId)
                                    }
                                })
                            }
                        }
                    }
                })
            }
        }
    }
    
    fileprivate class func createNewConversation(_ receiverId: String, familyId: String, completionHandler: @escaping (_ error: NSError?, _ conversationId: String?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let databaseRef = FIRDatabase.database().reference()
            let newConversationId = databaseRef.child("families").child(familyId).child("conversations").childByAutoId().key
            
            let childUpdates = ["/users/\(user.uid)/conversations/\(newConversationId)": "true",
                                "/users/\(receiverId)/conversations/\(newConversationId)": "true"] as [AnyHashable: Any]
            
            databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                if error != nil {
                    print("Error adding users to new conversation")
                    completionHandler(error as NSError?, nil)
                }
                else {
                    print("Created new conversation with users")
                    completionHandler(nil, newConversationId)
                }
            })
        }
    }
    
}

extension FirebaseManager {
    class func getFamilyNote(completionHandler: @escaping (_ error: NSError?, _ familyNote: String?) -> Void) {
        if AYNModel.sharedInstance.currentUser != nil {
            if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                let databaseRef = FIRDatabase.database().reference()

                databaseRef.child("families").child(userFamilyId).child("notepad").observeSingleEvent(of: .value, with: { (snapshot) in
                    if let familyNote = snapshot.value as? String {
                        print("Retrieved family note")
                        completionHandler(nil, familyNote)
                    }
                    else {
                        let firstNote = "Store your notes here!"
                        databaseRef.child("families").child(userFamilyId).updateChildValues(["notepad": firstNote], withCompletionBlock: { (error, newRef) in
//                        databaseRef.child("families").child(userFamilyId).child("notepad").updateChildValues(familyNote, withCompletionBlock: { (error, newRef) in
                            if error != nil {
                                // Error
                                print("Error saving first note")
                                completionHandler(error as NSError?, nil)
                            }
                            else {
                                // Success
                                print("Saved first note")
                                completionHandler(nil, firstNote)
                            }
                        })
                        
                    }
                }) { (error) in
                    print("Error retrieving family notepad:", error)
                    completionHandler(error as NSError?, nil)
                }
            }
        }
    }
    
    class func saveFamilyNote(_changes: String, completionHandler: @escaping (_ error: NSError?) -> Void) {
        if AYNModel.sharedInstance.currentUser != nil {
            if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                let databaseRef = FIRDatabase.database().reference()
                
                databaseRef.child("families").child(userFamilyId).updateChildValues(["notepad": _changes], withCompletionBlock: { (error, newRef) in
                    if error != nil {
                        // Error
                        print("Error saving note")
                        completionHandler(error as NSError?)
                    }
                    else {
                        // Success
                        print("Saved note")
                        completionHandler(nil)
                    }
                })
            }
        }
    }
}

