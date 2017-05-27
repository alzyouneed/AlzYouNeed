//
//  UpdateActionVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/27/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import PKHUD
import Firebase

class UpdateActionVC: UIViewController {
    
    @IBOutlet var typeLabel: UILabel!
    var type: String!
    
    @IBOutlet var topTextField: SkyFloatingLabelTextField!
    @IBOutlet var bottomTextField: SkyFloatingLabelTextField!
    
    @IBOutlet var updateButton: UIButton!
    @IBOutlet var updateButtonBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(EmailVC.keyboardWillShow(sender:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EmailVC.keyboardWillHide(sender:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        validateFields()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupView() {
        setupTypeLabel()
        setupTopTextField()
        setupBottomTextField()
    }
    
    func setupTypeLabel() {
        if type == "changeName" {
            typeLabel.text = "Change Name"
        } else if type == "changePassword" {
            typeLabel.text = "Change Password"
        }
    }
    
    func setupTopTextField() {
        let changeName = (type == "changeName")
        
        topTextField.font = UIFont(name: "OpenSans", size: 20)
        topTextField.placeholder = changeName ? "First name" : "New password"
        topTextField.title = changeName ? "Name" : "Password"
        topTextField.textColor = UIColor.black
        topTextField.tintColor = UIColor(hex: "7189FF")
        topTextField.lineColor = UIColor.lightGray
        
        topTextField.selectedTitleColor = UIColor(hex: "7189FF")
        topTextField.selectedLineColor = UIColor(hex: "7189FF")
        
//        topTextField.delegate = self
        topTextField.addTarget(self, action:#selector(UpdateActionVC.editedTopTextFieldText), for:UIControlEvents.editingChanged)
        topTextField.autocorrectionType = UITextAutocorrectionType.no
        topTextField.autocapitalizationType = UITextAutocapitalizationType.words
    }
    
    func setupBottomTextField() {
        let changePassword = (type == "changePassword")
        if changePassword {
            bottomTextField.font = UIFont(name: "OpenSans", size: 20)
            bottomTextField.placeholder = "Confirm password"
            bottomTextField.title = "Confirm password"
            bottomTextField.textColor = UIColor.black
            bottomTextField.tintColor = UIColor(hex: "7189FF")
            bottomTextField.lineColor = UIColor.lightGray
            
            bottomTextField.selectedTitleColor = UIColor(hex: "7189FF")
            bottomTextField.selectedLineColor = UIColor(hex: "7189FF")
            
//            bottomTextField.delegate = self
            bottomTextField.addTarget(self, action:#selector(UpdateActionVC.editedBottomTextFieldText), for:UIControlEvents.editingChanged)
            bottomTextField.autocorrectionType = UITextAutocorrectionType.no
            bottomTextField.autocapitalizationType = UITextAutocapitalizationType.words
        } else {
            bottomTextField.isHidden = true
            bottomTextField.isEnabled = false
        }
    }
    
    func editedTopTextFieldText() {
        validateFields()
    }
    
    func editedBottomTextFieldText() {
        validateFields()
    }
    
    // MARK: - Validation
    func validateFields() {
        if type == "changeName" {
            // Check top not empty
            let topEmpty = (topTextField.text?.isEmpty)!
            enableUpdateButton(enable: !topEmpty)
        } else {
            let topEmpty = (topTextField.text?.isEmpty)!
            let bottomEmpty = (bottomTextField.text?.isEmpty)!
            let passwordsMatch = topTextField.text == bottomTextField.text
            enableUpdateButton(enable: (!topEmpty && !bottomEmpty && passwordsMatch))
        }
    }
    
    func enableUpdateButton(enable: Bool) {
        updateButton.isEnabled = enable
        updateButton.alpha = enable ? 1 : 0.6
    }
    
    // MARK: - Adjusting keyboard
    func adjustingKeyboardHeight(show: Bool, notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.uintValue
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (keyboardFrame.height) //* (show ? 1 : -1)
        
        UIView.performWithoutAnimation({
            self.topTextField.layoutIfNeeded()
            self.bottomTextField.layoutIfNeeded()
        })
        
        if show {
            // Change constraints here
            updateButtonBottomConstraint.constant = changeInHeight
        } else {
            // Reset constraints here
            updateButtonBottomConstraint.constant = 0
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func keyboardWillShow(sender: NSNotification) {
        adjustingKeyboardHeight(show: true, notification: sender)
    }
    
    func keyboardWillHide(sender: NSNotification) {
        adjustingKeyboardHeight(show: false, notification: sender)
    }
    
    // MARK: - Profile Updates
    @IBAction func updateButtonPressed(_ sender: UIButton) {
        if type == "changeName" {
            changeName()
        } else {
            changePassword()
        }
    }
    
    func changeName() {
        let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
        changeRequest?.displayName = topTextField.text
        changeRequest?.commitChanges { (error) in
            // Save to RTDB
            FirebaseManager.updateUser(updates: ["name" : self.topTextField.text!] as NSDictionary, completionHandler: { (error) in
                if let error = error {
                    print("Error updating user: ", error.localizedDescription)
                } else {
                    print("Updated name")
                    self.navigationController?.popViewController(animated: true)
                }
            })
        }
    }
    
    func changePassword() {
        FIRAuth.auth()?.currentUser?.updatePassword(bottomTextField.text!, completion: { (error) in
            if let error = error {
                print("Error updating password: ", error.localizedDescription)
            } else {
                print("Updated password")
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
    
}
