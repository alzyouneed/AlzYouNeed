//
//  UpdateUserViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class UpdateUserViewController: UIViewController, UITextFieldDelegate {

    // MARK: - UI Elements
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var nameVTFView: validateTextFieldView!
    @IBOutlet var phoneNumberVTFView: validateTextFieldView!
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var addPhotoButton: UIButton!
    @IBOutlet var patientSwitch: UISwitch!
    
    @IBOutlet var avatarImageView: UIImageView!
    
    @IBOutlet var selectionView: avatarSelectionView!
    
    // MARK: - Properties
    var stepCompleted = false
    @IBOutlet var nextButtonBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UpdateUserViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UpdateUserViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        self.nameVTFView.textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
//    override func  preferredStatusBarStyle() -> UIStatusBarStyle {
//        return UIStatusBarStyle.LightContent
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureView() {
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(UpdateUserViewController.cancelAccountCreation(_:)))
        
        self.nameVTFView.nameMode()
        self.phoneNumberVTFView.phoneNumberMode()
        
        self.nameVTFView.textField.delegate = self
        self.phoneNumberVTFView.textField.delegate = self
        
        self.nameVTFView.textField.addTarget(self, action: #selector(UpdateUserViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.phoneNumberVTFView.textField.addTarget(self, action: #selector(UpdateUserViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
//        self.imagePicker.delegate = self
        self.addPhotoButton.layer.cornerRadius = self.addPhotoButton.frame.height/2
        
        signUpButtonEnabled()
    }
    
    func signUpButtonEnabled() {
        if validFields() {
            signUpButton.enabled = true
            signUpButton.alpha = 1
        }
        else {
            signUpButton.enabled = false
            signUpButton.alpha = 0.5
        }
    }
    
    func signUpButtonEnabled(enabled: Bool) {
        if enabled {
            signUpButton.enabled = true
            signUpButton.alpha = 1
        }
        else {
            signUpButton.enabled = false
            signUpButton.alpha = 0.5
        }
    }

    // MARK: - UIImagePickerController Delegate
    /*
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            dispatch_async(dispatch_get_main_queue(), { 
                self.userImageView.image = pickedImage
            })
//            self.userImageView.image = pickedImage
//            addPhotoButton.hidden = true
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func selectPhoto() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func addPhoto(sender: UIButton) {
        selectPhoto()
    }
    */
    
    // MARK: - Validation
    func validFields() -> Bool {
        return validateName() && validatePhoneNumber()
    }
    
    func validateName() -> Bool {
        let valid = !nameVTFView.textField.text!.isEmpty
        if valid {
            nameVTFView.isValid(true)
            return true
        }
        else {
//            print("Name field empty")
            nameVTFView.isValid(false)
            return false
        }
    }
    
    func validatePhoneNumber() -> Bool {
        
//        let PHONE_REGEX = "(?\\d{3})?\\s\\d{3}-\\d{4}$"

        // Supports phone number entry without hyphens
        let PHONE_REGEX = "^\\d{3}\\d{3}\\d{4}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let valid = phoneTest.evaluateWithObject(phoneNumberVTFView.textField.text!)
        if valid {
            phoneNumberVTFView.isValid(true)
            return true
        }
        else {
//            print("Invalid phone number")
            phoneNumberVTFView.isValid(false)
            return false
        }
    }
    
    // MARK: - Firebase
    func updateUserAccount() {
        if validFields() {
            
            // Disable button to avoid multiple taps
            signUpButtonEnabled(false)
            
            let updates = ["name": self.nameVTFView.textField.text!, "phoneNumber": self.phoneNumberVTFView.textField.text!, "patientStatus":self.patientStatus(), "avatarId": self.selectionView.avatarId(), "completedSignup": "familySetup"]
            
            FirebaseManager.updateUser(updates, completionHandler: { (error) in
                if error != nil {
                    // Failed to update user
                    self.signUpButtonEnabled(true)
                }
                else {
                    // Updated user
                    self.stepCompleted = true
                    self.performSegueWithIdentifier("familyStage", sender: self)
                }
            })
        }
    }
    
    func patientStatus() -> String {
        if patientSwitch.on {
            return "true"
        }
        else {
            return "false"
        }
    }
    
    @IBAction func completeSetup(sender: UIButton) {
        if validFields() {
            if let cancelButton = (self.navigationItem.rightBarButtonItems?.first) {
                cancelButton.enabled = false
            }
            updateUserAccount()
            self.view.endEditing(true)
        }
    }
    
    func cancelAccountCreation(sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "Cancel Signup", message: "All progress will be lost", preferredStyle: .ActionSheet)
        let confirmAction = UIAlertAction(title: "Confirm", style: .Destructive) { (action) in
            self.deleteUser()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func deleteUser() {
        FirebaseManager.deleteCurrentUser { (error) in
            if error != nil {
                // Error deleting user
            }
            else {
                // Successfully deleted user
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let onboardingVC: UINavigationController = storyboard.instantiateViewControllerWithIdentifier("onboardingNav") as! UINavigationController
                self.presentViewController(onboardingVC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        let tag = textField.superview!.superview!.tag
        switch tag {
        case 0:
            if validateName() {
                phoneNumberVTFView.textField.becomeFirstResponder()
            }
        case 1:
            if validatePhoneNumber() {
                updateUserAccount()
            }
        default:
            break
        }
        return true
    }
    
    func textFieldDidChange(textField: UITextField) {
        let tag = textField.superview!.superview!.tag
        
        switch tag {
        // Name textField
        case 0:
            validateName()
        // Phone number textField
        case 1:
            validatePhoneNumber()
        default:
            break
        }
        
        signUpButtonEnabled()
    }
    
    // MARK: - Keyboard
    func adjustingKeyboardHeight(show: Bool, notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        let changeInHeight = (CGRectGetHeight(keyboardFrame)) //* (show ? 1 : -1)
        
        if show {
            UIView.animateWithDuration(animationDuration) {
                self.nextButtonBottomConstraint.constant = changeInHeight
            }
        }
        else {
            UIView.animateWithDuration(animationDuration) {
                self.nextButtonBottomConstraint.constant = 0
            }
        }
    }
    
    func keyboardWillShow(sender: NSNotification) {
        adjustingKeyboardHeight(true, notification: sender)
    }
    
    func keyboardWillHide(sender: NSNotification) {
        adjustingKeyboardHeight(false, notification: sender)
    }
    
//    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
//        let tag = textField.superview!.superview!.tag
//        
//        if (tag == 1)
//        {
//            let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
//            let components = newString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
//            
//            let decimalString = components.joinWithSeparator("") as NSString
//            let length = decimalString.length
//            let hasLeadingOne = length > 0 && decimalString.characterAtIndex(0) == (1 as unichar)
//            
//            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11
//            {
//                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
//                
//                return (newLength > 10) ? false : true
//            }
//            var index = 0 as Int
//            let formattedString = NSMutableString()
//            
//            if hasLeadingOne
//            {
//                formattedString.appendString("1 ")
//                index += 1
//            }
//            if (length - index) > 3
//            {
//                let areaCode = decimalString.substringWithRange(NSMakeRange(index, 3))
//                formattedString.appendFormat("(%@)", areaCode)
//                index += 3
//            }
//            if length - index > 3
//            {
//                let prefix = decimalString.substringWithRange(NSMakeRange(index, 3))
//                formattedString.appendFormat("%@-", prefix)
//                index += 3
//            }
//            
//            let remainder = decimalString.substringFromIndex(index)
//            formattedString.appendString(remainder)
//            textField.text = formattedString as String
//            return false
//        }
//        else
//        {
//            return true
//        }
//    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "familyStage" {
            return stepCompleted
        }
        return false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
