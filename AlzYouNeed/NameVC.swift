//
//  NameVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/19/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

class NameVC: UIViewController, UITextFieldDelegate {

    @IBOutlet var nameTextField: SkyFloatingLabelTextField!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var nextButtonBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(NameVC.keyboardWillShow(sender:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NameVC.keyboardWillHide(sender:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        validateField()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: -- Setup view
    func setupView() {
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationController?.navigationBar.barTintColor = UIColor(hex: "4392F1")
        
        setupNameTextField()
    }
    
    func setupNameTextField() {
        nameTextField.font = UIFont(name: "OpenSans", size: 20)
        nameTextField.placeholder = "First name"
        nameTextField.title = "Name"
        nameTextField.textColor = UIColor.black
        nameTextField.tintColor = UIColor(hex: "7189FF")
        nameTextField.lineColor = UIColor.lightGray
        
        nameTextField.selectedTitleColor = UIColor(hex: "7189FF")
        nameTextField.selectedLineColor = UIColor(hex: "7189FF")
        
        nameTextField.delegate = self
        nameTextField.addTarget(self, action:#selector(NameVC.editedNameText), for:UIControlEvents.editingChanged)
        nameTextField.autocorrectionType = UITextAutocorrectionType.no
        nameTextField.autocapitalizationType = UITextAutocapitalizationType.words
    }
    
    // MARK: -- Adjusting keyboard
    func adjustingKeyboardHeight(show: Bool, notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.uintValue
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (keyboardFrame.height) //* (show ? 1 : -1)
        
        UIView.performWithoutAnimation({
            self.nameTextField.layoutIfNeeded()
        })
        
        if show {
            // Change constraints here
            nextButtonBottomConstraint.constant = changeInHeight
        } else {
            // Reset constraints here
            nextButtonBottomConstraint.constant = 0
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
    
    // MARK: -- Onboarding progression
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        // Save name and present next VC
        presentNextVC()
    }
    
    func presentNextVC() {
        print("Present familyStepVC")
        // Present next VC
        self.performSegue(withIdentifier: "nameToFamily", sender: self)
    }
    
    // MARK: -- Validation
    func validateField() {
        enableActionButton(enable: !(nameTextField.text?.isEmpty)!)
    }
    
    func enableActionButton(enable: Bool) {
        nextButton.isEnabled = enable
        nextButton.alpha = enable ? 1 : 0.6
    }
    
    // MARK: -- TextField changes
    func editedNameText() {
        validateField()
    }
    
    // MARK: -- Cancel signup
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        // TODO: Delete partial user profile
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "loginNav") as! UINavigationController
        self.present(onboardingVC, animated: true, completion: nil)
    }
}
