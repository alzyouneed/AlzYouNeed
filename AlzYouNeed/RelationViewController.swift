//
//  RelationViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 10/15/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class RelationViewController: UIViewController {
    
    @IBOutlet var relationPickerView: UIPickerView!
    @IBOutlet var patientSwitch: UISwitch!
    @IBOutlet var nextButton: UIButton!
    
    let pickerData = ["Daughter", "Son", "Granddaughter", "Grandson", "Mother", "Father", "Friend", "Other"]
    
    var selectedRelation = ""
    var userRelationAdded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        relationPickerView.delegate = self
        relationPickerView.dataSource = self
        
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.presentTransparentNavBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        self.navigationItem.hidesBackButton = true
    }
    
    func updateUserRelation() {
        var updates = [:] as [String : String]
        
        if patientSwitch.isOn {
           updates["patient"] = "true"
        } else {
            updates["patient"] = "false"
            updates["relation"] = selectedRelation
        }
        
        FirebaseManager.updateUser(updates as NSDictionary, completionHandler: { (error) in
            if error != nil {
                // Error
            }
            else {
                // Updated user
                self.userRelationAdded = true
                self.performSegue(withIdentifier: "pushNotification", sender: self)
            }
        })
    }
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        updateUserRelation()
    }
    
    @IBAction func cancelOnboarding(_ sender: UIBarButtonItem) {
        AYNModel.sharedInstance.onboarding = false
        cancelAccountCreation()
    }
    
    func cancelAccountCreation() {
        let alertController = UIAlertController(title: "Cancel Signup", message: "All progress will be lost", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { (action) in
            self.deleteUser()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func deleteUser() {
        FirebaseManager.deleteCurrentUser { (error) in
            if error != nil {
                // Error deleting user
            }
            else {
                // Successfully deleted user
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "loginNav") as! UINavigationController
                self.present(onboardingVC, animated: true, completion: nil)
            }
        }
    }

    @IBAction func patientStatusChanged(_ sender: UISwitch) {
        if patientSwitch.isOn {
            relationPickerView.isUserInteractionEnabled = false
            relationPickerView.alpha = 0.3
        } else {
            relationPickerView.isUserInteractionEnabled = true
            relationPickerView.alpha = 1
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "pushNotification" {
            return userRelationAdded
        }
        return false
    }

}

extension RelationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRelation = pickerData[row]
    }
}
