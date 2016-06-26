//
//  DashboardViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/16/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class DashboardViewController: UIViewController {
    
    @IBOutlet var userView: UserDashboardView!
    @IBOutlet var dateView: DateDashboardView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        FirebaseManager.getUserSignUpStatus { (status, error) in
            if error == nil {
                if let signupStatus = status {
                    print("Sign up completed: \(signupStatus)")
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        let now = NSDate()
        dateView.configureView(now)
        
        getCurrentFamily { (familyId) in
            print("Current family: \(familyId)")
            FirebaseManager.getFamilyMembers(familyId, completionHandler: { (contacts, error) in
                if let contactsArr = contacts {
                    for contact in contactsArr {
                        for (key, value) in contact {
                            FirebaseManager.getUserByID(key, completionHandler: { (contact, error) in
                                if let userContact = contact {
                                    print("Contact: \(userContact.description)")
                                    FirebaseManager.downloadPictureWithURL(userContact.userId, url: userContact.photoURL, completionHandler: { (image, error) in
                                        
//                                    })
//                                    FirebaseManager.downloadPictureWithURL(userContact.photoURL, completionHandler: { (image, error) in
                                        if let userImage = image {
                                            dispatch_async(dispatch_get_main_queue(), { 
                                                self.userView.userImageView.image = userImage
                                            })
                                        }
                                    })
                                }
                            })
                        }
                    }
                }
            })
        }
        
//        getCurrentFamily { (familyId) in
//            print("Current family: \(familyId)")
//            FirebaseManager.getFamilyMembers(familyId, completionHandler: { (contacts, error) in
//                if let contactsArr = contacts {
//                    for contact in contactsArr {
//                      
//                    }
//                }
//            })
//            
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func logout(sender: UIBarButtonItem) {
        try! FIRAuth.auth()?.signOut()
    }
    
    // MARK: - Firebase
    
    func uploadPicture() {
        if let user = FIRAuth.auth()?.currentUser {
            
            let storage = FIRStorage.storage()
            let storageRef = storage.reference()
            
            //        let pictureRef = storageRef.child("test.jpg")
            //        let pictureImagesRef = storageRef.child("images/test.jpg")
            
            let data = UIImageJPEGRepresentation(UIImage(named: "validEntry")!, 1)
            
            let imageRef = storageRef.child("userImages/\(user.uid)")
            
            let uploadTask = imageRef.putData(data!, metadata: nil) { (metadata, error) in
                if (error != nil) {
                    print("Error occurred while uploading picture: \(error)")
                }
                else {
                    print("Successfully uploaded picture: \(metadata!.downloadURL())")
                }
            }
        }
    }
    
    func getCurrentFamily(completionHandler:(String)->()){
        let userId = FIRAuth.auth()?.currentUser?.uid
        let databaseRef = FIRDatabase.database().reference()
        
        databaseRef.child("users").child(userId!).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let familyId = snapshot.value!["familyId"] as? String {
                completionHandler(familyId)
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }

}
