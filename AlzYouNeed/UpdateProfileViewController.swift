//
//  UpdateProfileViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/29/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class UpdateProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    
    @IBOutlet var selectionView: avatarSelectionView!
    @IBOutlet var nameVTFView: validateTextFieldView!
    @IBOutlet var phoneNumberVTFView: validateTextFieldView!
    @IBOutlet var updateButton: UIButton!
    
    var userName: String!
    var userPhoneNumber: String!
    var userAvatarId: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        FirebaseManager.getCurrentUser { (userDict, error) in
            if error == nil {
                if let userDict = userDict {
                    self.userName = userDict.objectForKey("name") as! String
                    self.userPhoneNumber = userDict.objectForKey("phoneNumber") as! String
                    self.userAvatarId = userDict.objectForKey("avatarId") as! String
                    
                    self.configureView()
                }
            }
        }
        
    }
    
//    override func viewWillAppear(animated: Bool) {
//        configureView()
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
//        selectionView.userImageView.image = UIImage(named: userAvatarId)
        nameVTFView.textField.placeholder = userName
        phoneNumberVTFView.textField.placeholder = userPhoneNumber
    }
    
    @IBAction func updateProfile(sender: UIButton) {
        
    }
    
    func updatesToSave() -> Bool {
      return false
    }
    
    func enableUpdateButton(enable: Bool) {
        if enable {
           updateButton.alpha = 1
            updateButton.enabled = true
        }
        else {
            updateButton.alpha = 0.5
            updateButton.enabled = false
        }
    }
    

}
