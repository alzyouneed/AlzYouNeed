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
    
//    class func getUserByID(userId: String, completionHandler: (contact: Contact?, error: NSError?) -> Void) {
//        if let user = FIRAuth.auth()?.currentUser {
//            let databaseRef = FIRDatabase.database().reference()
//            
//            databaseRef.child("users").child(userId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
//                if let user = snapshot.value! as? [String:String] {
//                    print("User retrieved")
////                    print("user: \(user)")
//                    let newContact = Contact(uID: userId, userDict: user)
//                    completionHandler(contact: newContact, error: nil)
//                    
////                    completionHandler(status: signupStatus, error: nil)
//                }
//            }) { (error) in
//                print("Error occurred while retrieving user")
//                completionHandler(contact: nil, error: error)
//            }
//        }
//    }
    
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
                    
                    // Update current user and new family, and signup Status
                    let childUpdates = ["/users/\(user.uid)/familyId": familyId, "/users/\(user.uid)/completedSignup": "true", "/families/\(familyId)": familyToSave]
                    databaseRef.updateChildValues(childUpdates as [NSObject : AnyObject])
                    
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
    
    class func joinFamilyGroup(familyId: String, password: String, completionHandler: (error: NSError?, newDatabaseRef: FIRDatabaseReference?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            
            getFamilyPassword(familyId, completionHandler: { (familyPassword, error) in
                if let actualFamilyPassword = familyPassword {
                    
                    if actualFamilyPassword == password {
                        
                        getUserPatientStatus({ (status, error) in
                            if let patientStatus = status {
                                let databaseRef = FIRDatabase.database().reference()
                                
                                let userToAdd = ["name":user.displayName!, "admin": "false", "patient": patientStatus]
                                
                                // Update current user and new family, and signUp status
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

//        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
//        let docsDir = "\(dirPaths[0] as String)/" // Document directory
//        
//        let completePath = "\(docsDir)\(userId)"
//        
//        let imageHttpsRef = FIRStorage.storage().referenceForURL(url)
////        let localURL: NSURL! = NSURL(string: completePath)
////        let localURL: NSURL! = NSURL(string: "file://local/images/\(userId)")
//        
//        let tempDirectory = NSURL(fileURLWithPath: NSTemporaryDirectory())
//        let localURL = tempDirectory.URLByAppendingPathComponent(userId) //.URLByAppendingPathExtension("jpg")
//        
//        let downloadTask = imageHttpsRef.writeToFile(localURL) { (url, error) in
//            if error != nil {
//                print("Error occurred while downloading image: \(error!)")
//                completionHandler(image: nil, error: error)
//            }
//            else {
//                print("Image downloaded successfully at: \(localURL)")
//                if let userImage = UIImage(contentsOfFile: (localURL.absoluteString)) {
////                if let userImage = UIImage(contentsOfFile: (url?.absoluteString)!) {
//                    print("Image retrieved for use")
//                    completionHandler(image: userImage, error: nil)
//                }
//            }
//        }
        
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

//    class func getFamilyMembers(familyId: String, completionHandler: (contacts: [[String:[String:String]]]?, error: NSError?) -> Void) {
//        if let user = FIRAuth.auth()?.currentUser {
//            let databaseRef = FIRDatabase.database().reference()
//            
//            databaseRef.child("families").child(familyId).child("members").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
//                
//                if let familyMembers = snapshot.value! as? NSMutableDictionary {
//                    print("Family members retrieved")
//                    
//                    var contactsArr = [[String:[String:String]]]()
//                    
//                    // Add dictionary entries to array
//                    for (key,value) in familyMembers {
//                        // Check that values exist
//                        if let keyItem = key as? String {
//                            if let valueItem = value as? Dictionary<String, String> {
//                                // Make sure current user is not included
//                                if keyItem != user.uid {
//                                    contactsArr.append([keyItem : valueItem])
//                                }
//                            }
//                        }
//                    }
//                    completionHandler(contacts: contactsArr, error: nil)
//                }
//            }) { (error) in
//                print("Error occurred while retrieving family members")
//                completionHandler(contacts: nil, error: error)
//            }
//        }
//    }
    
    class func getFamilyMembers(familyId: String, completionHandler: (contacts: [Contact]?, error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("families").child(familyId).child("members").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                if let familyMembers = snapshot.value! as? NSMutableDictionary {
                    print("Family members retrieved")
                    
                    var contactsArr = [Contact]()
                    
                    // Add dictionary entries to array
                    for (key,value) in familyMembers {
                        // Check that values exist
                        if let keyItem = key as? String {
//                            if let valueItem = value as? Dictionary<String, String> {
                            if let valueItem = value as? NSMutableDictionary {
                                print("key: \(keyItem) | value: \(valueItem)")
                                
                                // Make sure current user is not included
                                if keyItem != user.uid {
                                    let newUser = Contact(uID: keyItem, userDict: valueItem)
                                    
                                    contactsArr.append(newUser)
                                }
                            }
                        }
                    }
                    completionHandler(contacts: contactsArr, error: nil)
                }
            }) { (error) in
                print("Error occurred while retrieving family members")
                completionHandler(contacts: nil, error: error)
            }
        }
    }
}
