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
    
    class func updateUserDisplayName(name: String, completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let changeRequest = user.profileChangeRequest()
            
            changeRequest.displayName = name
            changeRequest.commitChangesWithCompletion({ (error) in
                if error != nil {
                    print("Error occurred while updating user display name")
                    completionHandler(error: error)
                }
                else {
                    print("User display name updated")
                    completionHandler(error: error)
                }
            })
        }
    }
    
    class func updateUserPhotoURL(url: String, completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let changeRequest = user.profileChangeRequest()
            
            changeRequest.photoURL = NSURL(string: url)
            changeRequest.commitChangesWithCompletion({ (error) in
                if error != nil {
                    print("Error occurred while updating user photo URL")
                    completionHandler(error: error)
                }
                else {
                    print("User photo URL updated")
                    completionHandler(error: error)
                }
            })
        }
    }
    
    class func getUserPatientStatus(completionHandler: (status: String?, error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let userId = user.uid
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("users").child(userId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let patientStatus = snapshot.value!["patientStatus"] as? String {
                    print("User patient status retrieved")
                    completionHandler(status: patientStatus, error: nil)
                }
            }) { (error) in
                print("Error occurred while retrieving user patient status")
                completionHandler(status: nil, error: error)
            }
        }
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
                    print("Current user retrieved")
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
                    print("Successfully updated user")
                    completionHandler(error: nil)
                }
            })
        }
    }
    
    // NEW: Delete current auth user and entry in real time database
    class func deleteCurrentUser(completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            deleteUserFromRTDB { (error, databaseRef) in
                if error != nil {
                    // Error
                    print("Error occurred while deleting account from RTDB")
                    completionHandler(error: error)
                }
                else {
                    // Success
                    user.deleteWithCompletion({ (error) in
                        if error != nil {
                            // Error
                            print("Error occurred while deleting account")
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
    
    // MARK: - Family Group Management
    // NEW
    class func createNewFamilyGroup(familyId: String, password: String, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            
            getCurrentUser({ (userDict, error) in
                if let userInfo = userDict {
                   let databaseRef = FIRDatabase.database().reference()
                    
//                    let familyToSave = ["password": password, "members":[user.uid: ["admin": "true", "patient": patientStatus]]]
                    let familyToSave = ["password": password, "members":[user.uid: userInfo]]
                    
                    // Update current user and new family, and signup Status
                    let childUpdates = ["/users/\(user.uid)/familyId": familyId,
                                        "/users/\(user.uid)/completedSignup": "true",
                                        "/users/\(user.uid)/admin": "true",
                                        "/families/\(familyId)": familyToSave]
//                                        "/families/\(familyId)/members/\(user.uid)/familyId": familyId,
//                                        "/families/\(familyId)/members/\(user.uid)/completedSignup": "true",
//                                        "/families/\(familyId)/members/\(user.uid)/admin": "true"]
//                    databaseRef.updateChildValues(childUpdates as [NSObject : AnyObject])
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
                                
                                // Update current user and new family, and signUp status
                                let childUpdates = ["/users/\(user.uid)/familyId": familyId,
                                                    "/users/\(user.uid)/completedSignup": "true"]
//                                databaseRef.updateChildValues(childUpdates as [NSObject : AnyObject])
                                databaseRef.child("families").child(familyId).child("members").child(user.uid).setValue(userInfo)
                                
                                databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                                    if error != nil {
                                        print("Error occurred while updating user with new family group values")
                                        completionHandler(error: error, newDatabaseRef: databaseRef)
                                    }
                                    else {
                                        print("User family group values updated")
                                        databaseRef.child("families").child(familyId).child("members").child(user.uid).setValue(userInfo, withCompletionBlock: { (secondError, secondDatabaseRef) in
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
    
    // MARK: - Database Management
    /*
    class func uploadPictureToDatabase(image: UIImage?, completionHandler: (metadata: FIRStorageMetadata?, error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            if let userImage = image {
                let storage = FIRStorage.storage()
                let storageRef = storage.reference()
                
                let data = UIImageJPEGRepresentation(userImage, 0.8)
                let imageRef = storageRef.child("userImages/\(user.uid)")
                
                let uploadTask = imageRef.putData(data!, metadata: nil, completion: { (metadata, error) in
                    if error != nil {
                        print("Error occurred while uploading user image file")
                        completionHandler(metadata: metadata, error: error)
                    }
                    else {
                        print("User image file uploaded")
                        
                        if let photoUrl = metadata?.downloadURL()?.absoluteString {
                            updateUserPhotoURL(photoUrl, completionHandler: { (error) in
                                if error != nil {
                                    // Failed to update user photo url
                                }
                                else {
                                    // Successfully updated user photo url
                                    updateUserPhotoURLInRealTimeDatabase(photoUrl, completionHandler: { (error) in
                                        if error != nil {
                                            // Failed to update user photo url in realTime database
                                        }
                                        else {
                                            // Successfully updated user photo url in realtTime database
                                            completionHandler(metadata: metadata, error: error)
                                        }
                                    })
                                }
                            })
                        }
                        
//                        completionHandler(metadata: metadata, error: error)
                    }
                })
            }
            else {
                print("No iamge to upload")
            }
        }
    }
    
    class func downloadPictureWithURL(userId: String, url: String, completionHandler: (image: UIImage?, error: NSError?) -> Void) {
        
        let storage = FIRStorage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("userImages").child(userId)
        
        imageRef.dataWithMaxSize(5 * 1024 * 1024) { (data, error) in
            if error != nil {
                // Error
                print("Error occurred while downloading image file -- error: \(error)")
                completionHandler(image: nil, error: error)
            }
            else {
                // Success
                if let imageData = data {
                    if let image = UIImage(data: imageData) {
                        print("Successfully downlaoded image file")
                        completionHandler(image: image, error: nil)
                    }
                }
            }
        }
    }
    
    class func deletePictureFromDatabase(completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let storage = FIRStorage.storage()
            let storageRef = storage.reference()
            
            let userImageRef = storageRef.child("userImages/\(user.uid)")
            
            userImageRef.deleteWithCompletion({ (error) in
                if error != nil {
                    print("Error occurred while deleting user image file")
                    completionHandler(error: error)
                }
                else {
                    print("User image file deleted")
                    completionHandler(error: error)
                }
            })
        }
    }
    
    class func updateUserPhotoURLInRealTimeDatabase(url: String, completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("users/\(user.uid)").child("photoURL").setValue(url, withCompletionBlock: { (error, newDatabaseRef) in
                if error != nil {
                    print("Error updating user photo URL in realTime database")
                    completionHandler(error: error)
                }
                else {
                    print("User photo URL updated in realTime database")
                    completionHandler(error: error)
                }
            })
            
        }
    }
 
    
    */
    
    class func getFamilyMembers(familyId: String, completionHandler: (contacts: [Contact]?, error: NSError?) -> Void) {
        if (FIRAuth.auth()?.currentUser) != nil {
            let databaseRef = FIRDatabase.database().reference()
            
            // Retrieve family member ID's for user lookup
            databaseRef.child("families").child(familyId).child("members").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let familyMembers = snapshot.value! as? NSMutableDictionary {

//                    var contactsArr = [Contact]()
                    
                    if let userIds = familyMembers.allKeys as? [String] {
                            getUsersById(userIds, completionHandler: { (contacts, error) in
                                if error != nil {
                                    // Error occurred
                                    completionHandler(contacts: nil, error: error)
                                }
                                else {
                                    // Success
                                    completionHandler(contacts: contacts, error: nil)
                                }
                            })
                    }
//                    
//                    // Iterate through all members to get all information for each user
//                    for (key,value) in familyMembers {
//                        if let userId = key as? String {
//                            getUserById(userId, completionHandler: { (contact, error) in
//                                if error != nil {
//                                    // Error occurred
//                                    completionHandler(contacts: nil, error: error)
//                                }
//                                else {
//                                    if let newContact = contact {
//                                        print("contact: \(newContact)")
//                                        contactsArr.append(newContact)
//                                    }
//                                }
//                            })
//                        }
//                    }
//                    if !contactsArr.isEmpty {
//                    print("Successfully retrieved family members -- contactsArr: \(contactsArr)")
//                    completionHandler(contacts: contactsArr, error: nil)
//                    }
                }
            }) { (error) in
//                print("Error occurred while retrieving family members")
            }
        }
    }
    
    private class func getSingleUserById(userId: String, completionHandler: (contact: Contact?, error: NSError?) -> Void) {
        if (FIRAuth.auth()?.currentUser) != nil {
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("users").child(userId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let userFromDB = snapshot.value! as? NSMutableDictionary {
                    if let newContact = Contact(uID: userId, userDict: userFromDB) {
                        print("Successfully retrieved user by ID")
                        completionHandler(contact: newContact, error: nil)
                    }
                    else {
                        print("Error creating new contact")
                    }
                }
            }) { (error) in
                print("Error occurred while looking up user by ID")
            }
        }
    }
}
