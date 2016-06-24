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
    }
    
    override func viewDidAppear(animated: Bool) {
        let now = NSDate()
        dateView.configureView(now)
        
        getCurrentFamily { (familyId) in
            print("Current family: \(familyId)")
        }
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
