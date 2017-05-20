//
//  EmailVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/19/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

class EmailVC: UIViewController {

    @IBOutlet var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet var passwordTextField: SkyFloatingLabelTextField!
    @IBOutlet var nextButtonBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(EmailVC.keyboardWillShow(sender:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EmailVC.keyboardWillHide(sender:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupView() {
        setupEmailTextField()
        setupPasswordTextField()
    }
    
    func setupEmailTextField() {
        emailTextField.font = UIFont(name: "OpenSans", size: 20)
        emailTextField.placeholder = "Email"
        emailTextField.title = "Email"
        emailTextField.textColor = UIColor.black
        emailTextField.tintColor = UIColor(hex: "7d80da")
        emailTextField.lineColor = UIColor.lightGray
        
        emailTextField.selectedTitleColor = UIColor(hex: "7d80da")
        emailTextField.selectedLineColor = UIColor(hex: "7d80da")
    }
    
    func setupPasswordTextField() {
        passwordTextField.font = UIFont(name: "OpenSans", size: 20)
        passwordTextField.placeholder = "Password"
        passwordTextField.title = "Password"
        passwordTextField.textColor = UIColor.black
        passwordTextField.tintColor = UIColor(hex: "7d80da")
        passwordTextField.lineColor = UIColor.lightGray
        
        passwordTextField.selectedTitleColor = UIColor(hex: "7d80da")
        passwordTextField.selectedLineColor = UIColor(hex: "7d80da")
        
    }
    
    func adjustingKeyboardHeight(show: Bool, notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.uintValue
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (keyboardFrame.height) //* (show ? 1 : -1)
        
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

}
