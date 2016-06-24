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
            if error == nil {
                print("Sign up successful")
                completionHandler(user: user, error: error)
            }
            else {
                print("There was an error creating user")
                completionHandler(user: user, error: error)
            }
        })
    }
    
    class func deleteCurrentUser(completionHandler: (error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            user.deleteWithCompletion({ (error) in
                if let error = error {
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
    
    // MARK: - Database Management
    class func uploadPictureToDatabase(image: UIImage?, completionHandler: (metadata: FIRStorageMetadata?, error: NSError?) -> Void) {
        if let user = FIRAuth.auth()?.currentUser {
            if let userImage = image {
                let storage = FIRStorage.storage()
                let storageRef = storage.reference()
                
                let data = UIImageJPEGRepresentation(userImage, 1)
                let imageRef = storageRef.child("userImages/\(user.uid)")
                
                let uploadTask = imageRef.putData(data!, metadata: nil, completion: { (metadata, error) in
                    if let error = error {
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
                if let error = error {
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
                if let error = error {
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
    

}
