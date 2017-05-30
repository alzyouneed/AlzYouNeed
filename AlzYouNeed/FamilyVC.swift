//
//  FamilyVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/19/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import Firebase
import PKHUD
import Crashlytics

class FamilyVC: UIViewController, UITextFieldDelegate {

    @IBOutlet var familyControl: UISegmentedControl!
    @IBOutlet var familyNameTextField: SkyFloatingLabelTextField!
    @IBOutlet var passwordTextField: SkyFloatingLabelTextField!
    @IBOutlet var confirmPasswordTextField: SkyFloatingLabelTextField!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var actionButtonBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(FamilyVC.keyboardWillShow(sender:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FamilyVC.keyboardWillHide(sender:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        validateFields()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Setup view
    func setupView() {
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        let attr = NSDictionary(object: UIFont(name: "OpenSans", size: 15)!, forKey: NSFontAttributeName as NSCopying)
        familyControl.setTitleTextAttributes(attr as? [AnyHashable : Any], for: .normal)
        
        setupFamilyNameTextField()
        setupPasswordTextField()
        setupConfirmPasswordTextField()
    }
    
    func setupFamilyNameTextField() {
        familyNameTextField.font = UIFont(name: "OpenSans", size: 20)
        familyNameTextField.placeholder = "Group name"
        familyNameTextField.title = "Group name"
        familyNameTextField.textColor = UIColor.black
        familyNameTextField.tintColor = UIColor(hex: "16D0C5")
        familyNameTextField.lineColor = UIColor.lightGray
        
        familyNameTextField.selectedTitleColor = UIColor(hex: "16D0C5")
        familyNameTextField.selectedLineColor = UIColor(hex: "16D0C5")
        
        familyNameTextField.delegate = self
        familyNameTextField.addTarget(self, action:#selector(FamilyVC.editedFamilyNameText), for:UIControlEvents.editingChanged)
        familyNameTextField.autocorrectionType = UITextAutocorrectionType.no
        familyNameTextField.autocapitalizationType = UITextAutocapitalizationType.words
    }
    
    func setupPasswordTextField() {
        passwordTextField.font = UIFont(name: "OpenSans", size: 20)
        passwordTextField.placeholder = "Password"
        passwordTextField.title = "Password"
        passwordTextField.textColor = UIColor.black
        passwordTextField.tintColor = UIColor(hex: "16D0C5")
        passwordTextField.lineColor = UIColor.lightGray
        
        passwordTextField.selectedTitleColor = UIColor(hex: "16D0C5")
        passwordTextField.selectedLineColor = UIColor(hex: "16D0C5")
        
        passwordTextField.delegate = self
        passwordTextField.addTarget(self, action:#selector(FamilyVC.editedPasswordText), for:UIControlEvents.editingChanged)
        passwordTextField.autocorrectionType = UITextAutocorrectionType.no
    }

    func setupConfirmPasswordTextField() {
        confirmPasswordTextField.font = UIFont(name: "OpenSans", size: 20)
        confirmPasswordTextField.placeholder = "Confirm password"
        confirmPasswordTextField.title = "Confirm password"
        confirmPasswordTextField.textColor = UIColor.black
        confirmPasswordTextField.tintColor = UIColor(hex: "16D0C5")
        confirmPasswordTextField.lineColor = UIColor.lightGray
        
        confirmPasswordTextField.selectedTitleColor = UIColor(hex: "16D0C5")
        confirmPasswordTextField.selectedLineColor = UIColor(hex: "16D0C5")
        
        confirmPasswordTextField.delegate = self
        confirmPasswordTextField.addTarget(self, action:#selector(FamilyVC.editedConfirmPasswordText), for:UIControlEvents.editingChanged)
        confirmPasswordTextField.autocorrectionType = UITextAutocorrectionType.no
    }
    
    // MARK: - TextField changes
    func editedFamilyNameText() {
        validateFields()
    }
    
    func editedPasswordText() {
        validateFields()
    }
    
    func editedConfirmPasswordText() {
        validateFields()
    }
    
    // MARK: - Mode changes
    @IBAction func familyOptionChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // Create family mode
            sender.tintColor = UIColor(hex: "16D0C5")
            changeMode(mode: "create")
            
            // Show confirm pass & infoLabel
        } else {
            // Join family mode
            sender.tintColor = UIColor(hex: "7189FF")
            changeMode(mode: "join")
            
            // Hide confirm pass & infoLabel
        }
        validateFields()
    }
    
    func changeMode(mode: String) {
        
        let modeColor = (mode == "create") ? UIColor(hex: "16D0C5") : UIColor(hex: "7189FF")
        changeAllFieldColor(color: modeColor)
        actionButton.backgroundColor = modeColor
        
        if mode == "create" {
            animateFieldChange(show: true)
            actionButton.setTitle("Create", for: .normal)
        } else {
            animateFieldChange(show: false)
            actionButton.setTitle("Join", for: .normal)
        }
    }
    
    func changeAllFieldColor(color: UIColor) {
        familyNameTextField.selectedTitleColor = color
        familyNameTextField.selectedLineColor = color
        familyNameTextField.tintColor = color
        
        passwordTextField.selectedTitleColor = color
        passwordTextField.selectedLineColor = color
        passwordTextField.tintColor = color
        
        confirmPasswordTextField.selectedTitleColor = color
        confirmPasswordTextField.selectedLineColor = color
        confirmPasswordTextField.tintColor = color
    }
    
    func animateFieldChange(show: Bool) {
        if show {
            confirmPasswordTextField.isHidden = false
            infoLabel.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.confirmPasswordTextField.alpha = 1
                self.infoLabel.alpha = 1
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.confirmPasswordTextField.alpha = 0
                self.infoLabel.alpha = 0
            }, completion: { (complete) in
                self.confirmPasswordTextField.isHidden = true
                self.infoLabel.isHidden = true
            })
        }
    }

    @IBAction func actionButtonPressed(_ sender: UIButton) {
        HUD.show(.progress)
        
        // Try creating / joining family in Firebase
        let groupName = familyNameTextField.text!
        let password = passwordTextField.text!
        
        if familyControl.selectedSegmentIndex == 0 {
            createGroup(groupId: groupName, password: password)
            
        } else {
            joinGroup(groupId: groupName, password: password)
        }
    }
    
    func createGroup(groupId: String, password: String) {
        FirebaseManager.createNewFamilyGroup(groupId, password: password) { (error, ref) in
            if let error = error {
                HUD.hide()
                print("Error creating group: ", error.localizedDescription)
                self.showErrorMessage(error: error)
            } else {
                print("Created new group")
                NewProfile.sharedInstance.resetModel()
                
                // Get groupId for model
                AYNModel.sharedInstance.groupId = groupId
                
                HUD.flash(.success, delay: 0, completion: { (success) in
                    self.showMainView()
                })
            }
        }
    }
    
    func joinGroup(groupId: String, password: String) {
        FirebaseManager.joinFamilyGroup(groupId, password: password) { (error, ref) in
            if let error = error {
                HUD.hide()
                print("Error joining group: ", error.localizedDescription)
                self.showErrorMessage(error: error)
            } else {
                print("Joined group")
                NewProfile.sharedInstance.resetModel()
                
                // Get groupId for model
                AYNModel.sharedInstance.groupId = groupId
                
                HUD.flash(.success, delay: 0, completion: { (success) in
                    self.showMainView()
                })
            }
        }
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
            self.familyNameTextField.layoutIfNeeded()
            self.passwordTextField.layoutIfNeeded()
            self.confirmPasswordTextField.layoutIfNeeded()
        })
        
        if show {
            // Change constraints here
            actionButtonBottomConstraint.constant = changeInHeight
        } else {
            // Reset constraints here
            actionButtonBottomConstraint.constant = 0
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
    
    // MARK: - Validation
    func validateFields() {
        if familyControl.selectedSegmentIndex == 0 {
            // Create mode
            let fieldsFilled = !(familyNameTextField.text?.isEmpty)! && !(passwordTextField.text?.isEmpty)! && !(confirmPasswordTextField.text?.isEmpty)!
            let passwordsMatch = passwordTextField.text == confirmPasswordTextField.text
            enableActionButton(enable: fieldsFilled && passwordsMatch )

        } else {
            // Join mode
            let fieldsFilled = !(familyNameTextField.text?.isEmpty)! && !(passwordTextField.text?.isEmpty)!
            enableActionButton(enable: fieldsFilled)
        }
    }
    
    func enableActionButton(enable: Bool) {
        actionButton.isEnabled = enable
        actionButton.alpha = enable ? 1 : 0.6
    }
    
    // MARK: - Cancel signup
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        showWarning()
    }
    
    func showWarning() {
        let alert = UIAlertController(title: "Unsaved Changes", message: "Progress will not be saved", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { (action) in
            self.cancelSignup()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func cancelSignup() {
        // Delete partial user profile
        NewProfile.sharedInstance.resetModel()
        
        Answers.logCustomEvent(withName: "Cancel sign up", customAttributes: ["step": "FamilyVC"])
        
        if let user = Auth.auth().currentUser {
            user.delete(completion: { (error) in
                if let error = error {
                    print("Error while deleting account: \(error.localizedDescription)")
                } else {
                    print("FamilyVC: Account deleted")
                    self.dismiss(animated: true, completion: nil)
                }
            })
        }
    }
    
    // MARK: - Handle errors
    func showErrorMessage(error: Error) {
        var errorMessage = ""
        
        switch error._code {
        case 00001:
            errorMessage = "Group name already in use"
        case 00003:
            errorMessage = "Incorrect password"
        case 00004:
            errorMessage = "Group does not exist"
        default:
            break
        }
        
        if !errorMessage.isEmpty {
            let alert = UIAlertController(title: "Something went wrong", message: errorMessage, preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alert.addAction(okayAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Transitions
    func showMainView() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController: UITabBarController = storyboard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
        tabBarController.selectedIndex = 1
        
        DispatchQueue.main.async {
            self.present(tabBarController, animated: true, completion: nil)
        }
    }
}
