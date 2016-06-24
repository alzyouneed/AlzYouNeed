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
                if let patientStatus = snapshot.value!["patient"] as? String {
                    print("User patient status retrieved")
                    completionHandler(status: patientStatus, error: nil)
                }
            }) { (error) in
                print("Error occurred while retrieving user patient status")
                completionHandler(status: nil, error: error)
            }
        }
    }
    
    class func deleteCurrentUser(completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            user.deleteWithCompletion({ (error) in
                if error != nil {
                    print("Error occurred while deleting account")
                    completionHandler(error: error)
                }
                else {
                    print("Account deleted")
                    completionHandler(error: error)
                }
            })
        }
    }
    
    // MARK: - Family Group Management
    class func createNewFamilyGroup(familyId: String, password: String, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            
            getUserPatientStatus({ (status, error) in
                if let patientStatus = status {
                    let databaseRef = FIRDatabase.database().reference()
                    
                    let familyToSave = ["password": password, "members":[user.uid: ["name":user.displayName!, "admin": "true", "patient": patientStatus]]]
                    
                    // Update current user and new family
                    let childUpdates = ["/users/\(user.uid)/familyId": familyId, "/users/\(user.uid)/completedSignup": "true", "/families/\(familyId)": familyToSave]
                    databaseRef.updateChildValues(childUpdates as [NSObject : AnyObject])
                    
                    databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                        if error != nil {
                            print("Error creating new family group")
                            completionHandler(error: error, newDatabaseRef: databaseRef)
                        }
                        else {
                            print("New family group created")
                            completionHandler(error: error, newDatabaseRef: databaseRef)
                        }
                    })
                }
            })
        }
    }
    
    class func joinFamilyGroup(familyId: String, password: String, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            
            getFamilyPassword(familyId, completionHandler: { (familyPassword, error) in
                if let actualFamilyPassword = familyPassword {
                    
                    if actualFamilyPassword == password {
                        
                        getUserPatientStatus({ (status, error) in
                            if let patientStatus = status {
                                let databaseRef = FIRDatabase.database().reference()
                                
                                let userToAdd = ["name":user.displayName!, "admin": "false", "patient": patientStatus]
                                
                                // Update current user and new family
                                let childUpdates = ["/users/\(user.uid)/familyId": familyId, "/users/\(user.uid)/completedSignup": "true"]
                                databaseRef.updateChildValues(childUpdates as [NSObject : AnyObject])
                                databaseRef.child("families").child(familyId).child("members").child(user.uid).setValue(userToAdd)
                                
                                databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                                    if error != nil {
                                        print("Error occurred while updating user with new family group values")
                                        completionHandler(error: error, newDatabaseRef: databaseRef)
                                    }
                                    else {
                                        print("User family group values updated")
                                        databaseRef.child("families").child(familyId).child("members").child(user.uid).setValue(userToAdd, withCompletionBlock: { (secondError, secondDatabaseRef) in
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
                    completionHandler(error: nil, newDatabaseRef: nil)
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
    class func uploadPictureToDatabase(image: UIImage?, completionHandler: (metadata: FIRStorageMetadata?, error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            if let userImage = image {
                let storage = FIRStorage.storage()
                let storageRef = storage.reference()
                
                let data = UIImageJPEGRepresentation(userImage, 1)
                let imageRef = storageRef.child("userImages/\(user.uid)")
                
                let uploadTask = imageRef.putData(data!, metadata: nil, completion: { (metadata, error) in
                    if error != nil {
                        print("Error occurred while uploading user image file")
                        completionHandler(metadata: metadata, error: error)
                    }
                    else {
                        print("User image file uploaded")
                        completionHandler(metadata: metadata, error: error)
                    }
                })
            }
            else {
                print("No iamge to upload")
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
    
    class func saveUserToRealTimeDatabase(name: String, phoneNumber: String, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let databaseRef = FIRDatabase.database().reference()
            
            let userToSave = ["name": name, "email": "\(user.email!)", "phoneNumber": phoneNumber, "familyId": "", "patient": "false", "completedSignup": "false", "photoURL":""]
            
            databaseRef.child("users/\(user.uid)").setValue(userToSave, withCompletionBlock: { (error, newDatabaseRef) in
                if error != nil {
                    print("Error occurred while saving user to realTime database")
                    completionHandler(error: error, newDatabaseRef: newDatabaseRef)
                }
                else {
                    print("User saved to realTime database")
                    completionHandler(error: error, newDatabaseRef: newDatabaseRef)
                }
            })
        }
    }
    
    class func deleteUserFromRealTimeDatabase(completionHandler: (error: NSError?, databaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let databaseRef = FIRDatabase.database().reference()
            databaseRef.child("users/\(user.uid)").removeValueWithCompletionBlock({ (error, oldDatabaseRef) in
                if error != nil {
                    print("Error deleting user from realTime database")
                    completionHandler(error: error, databaseRef: oldDatabaseRef)
                }
                else {
                    print("User deleted from realTime database")
                    completionHandler(error: error, databaseRef: oldDatabaseRef)
                }
            })
        }
    }

}
