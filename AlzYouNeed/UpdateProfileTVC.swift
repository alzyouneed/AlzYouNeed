//
//  UpdateProfileTVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/27/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit
import PKHUD
import SkyFloatingLabelTextField
import Firebase

class UpdateProfileTVC: UITableViewController {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var notificationSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // TODO: Reload info here if update made
        setupNameLabel()
        self.navigationController?.navigationBar.tintColor = UIColor(hex: "7189FF")
        UIApplication.shared.statusBarStyle = .default
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupView() {
        setupUserImageView()
        setupNameLabel()
        setupNotificationSwitch()
    }
    
    func setupUserImageView() {
        userImageView.layer.masksToBounds = false
        userImageView.layer.cornerRadius = self.userImageView.frame.height/2
        userImageView.clipsToBounds = true
//        userImageView.layer.borderWidth = 2
//        userImageView.layer.borderColor = UIColor.white.cgColor
//        userImageView.layer.borderColor = UIColor(hex: "7189FF").cgColor
        
        if let userImage = AYNModel.sharedInstance.userImage {
            userImageView.image = userImage
        }
    }
    
    func setupNameLabel() {
        if let user = FIRAuth.auth()?.currentUser {
            self.nameLabel.text = user.displayName?.components(separatedBy: " ").first
        }
    }
    
    func setupNotificationSwitch() {
        if UIApplication.shared.isRegisteredForRemoteNotifications {
            notificationSwitch.isOn = true
        } else {
            notificationSwitch.isOn = false
        }
    }

    @IBAction func changePicturePressed(_ sender: UIButton) {
        
    }
    
    func changeNameAction() {
        print("Change name action")
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeName" {
            if let destVC: UpdateActionVC = segue.destination as? UpdateActionVC {
                destVC.type = "changeName"
            }
        } else if segue.identifier == "changePassword" {
            if let destVC: UpdateActionVC = segue.destination as? UpdateActionVC {
                destVC.type = "changePassword"
            }
        }
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
