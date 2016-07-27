//
//  UpdateProfileViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/29/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import PKHUD

class UpdateProfileViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - UI Elements
    @IBOutlet var profileImageView: UIImageView!
    let imagePicker = UIImagePickerController()
    @IBOutlet var nameVTFView: validateTextFieldView!
    @IBOutlet var phoneNumberVTFView: validateTextFieldView!
    @IBOutlet var updateButton: UIButton!
    
    var userName: String!
    var userPhoneNumber: String!
    var userPhotoUrl: String!
    var profileImageUpdated = false
    
    // MARK: - Properties
    @IBOutlet var updateButtonBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.tabBarController?.tabBar.hidden = true
        
        FirebaseManager.getCurrentUser { (userDict, error) in
            if error == nil {
                if let userDict = userDict {
                    self.userName = userDict.objectForKey("name") as! String
                    self.userPhoneNumber = userDict.objectForKey("phoneNumber") as! String
                    self.userPhotoUrl = userDict.objectForKey("photoUrl") as! String
                    
                    self.configureView()
                }
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UpdateProfileViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UpdateProfileViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        self.nameVTFView.nameMode()
        self.phoneNumberVTFView.phoneNumberMode()
        
        dispatch_async(dispatch_get_main_queue()) { 
            self.nameVTFView.textField.placeholder = self.userName
            self.phoneNumberVTFView.textField.placeholder = self.userPhoneNumber
        }
        
        self.nameVTFView.textField.delegate = self
        self.phoneNumberVTFView.textField.delegate = self
        
        self.nameVTFView.textField.addTarget(self, action: #selector(UpdateProfileViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.phoneNumberVTFView.textField.addTarget(self, action: #selector(UpdateProfileViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        configureImagePicker()
        configureProfileImage(userPhotoUrl)
        updatesToSave()
    }
    
    func configureProfileImage(photoUrl: String) {
        if photoUrl.hasPrefix("gs://") {
            FIRStorage.storage().referenceForURL(photoUrl).dataWithMaxSize(INT64_MAX, completion: { (data, error) in
                if let error = error {
                    // Error
                    print("Error downloading user profile image: \(error.localizedDescription)")
                    return
                }
                // Success
                dispatch_async(dispatch_get_main_queue(), {
                    self.profileImageView.image = UIImage(data: data!)
                })
            })
        } else if let url = NSURL(string: photoUrl), data = NSData(contentsOfURL: url) {
            dispatch_async(dispatch_get_main_queue(), {
                self.profileImageView.image = UIImage(data: data)
            })
        }
    }
    
    func configureImagePicker() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height/2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = slateBlue.CGColor
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UpdateUserViewController.selectPhoto(_:)))
        tap.numberOfTapsRequired = 1
        profileImageView.addGestureRecognizer(tap)
        print("configured image picker")
    }
    
    @IBAction func updateProfile(sender: UIButton) {
        if updatesToSave() {
            // Update profile and return to previous VC
            print("Updates to save")
            var updates = [String: NSObject]()
            
            
            // Remove if no updates
            if nameUpdate() {
                updates["name"] = nameVTFView.textField.text!
            }
            if phoneNumberUpdate() {
                updates["phoneNumber"] = phoneNumberVTFView.textField.text!
            }
            if profileImageUpdated {
                var imageData = NSData()
                if let profileImage = profileImageView.image {
                    imageData = UIImageJPEGRepresentation(profileImage, 0.1)!
                }
                updates["profileImage"] = imageData
            }
            
            // Show progress view
            HUD.show(.Progress)

            FirebaseManager.updateUser(updates, completionHandler: { (error) in
                if error == nil {
                    // Updated user -- Return to previous VC
                    HUD.flash(.Success, delay: 0, completion: { (success) in
                        print("Profile updated -- returning to VC")
                        self.view.endEditing(true)
                        AYNModel.sharedInstance.profileWasUpdated = true
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    })
                } else {
                    // Error
                    HUD.flash(.Error, delay: 0, completion: { (success) in
                        print("Error updating user")
                    })
                }
            })
            
        }
        else {
            print("No updates to save")
        }
    }
    
    // MARK: - Updates
    func updatesToSave() -> Bool {
        if nameUpdate() || phoneNumberUpdate() || profileImageUpdated {
            enableUpdateButton(true)
            return true
        }
        enableUpdateButton(false)
        return false
    }
    
    // Check for change in name
    func nameUpdate() -> Bool {
        if nameVTFView.textField.text != userName && validateName() {
            return true
        }
        return false
    }
    
    // Check for change in phone number
    func phoneNumberUpdate() -> Bool {
        if phoneNumberVTFView.textField.text != userPhoneNumber && validatePhoneNumber() {
            return true
        }
        return false
    }
    
    // MARK: - Validation
    func validateName() -> Bool {
        let valid = !nameVTFView.textField.text!.isEmpty
        if valid {
            nameVTFView.isValid(true)
            return true
        }
        else {
            nameVTFView.isValid(false)
            return false
        }
    }
    
    func validatePhoneNumber() -> Bool {
        let PHONE_REGEX = "^\\d{3}\\d{3}\\d{4}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let valid = phoneTest.evaluateWithObject(phoneNumberVTFView.textField.text!)
        if valid {
            phoneNumberVTFView.isValid(true)
            return true
        }
        else {
            phoneNumberVTFView.isValid(false)
            return false
        }
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
    
    // MARK: - UITextFieldDelegate
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
        
        updatesToSave()
    }
    
    // MARK: - Keyboard
    func adjustingKeyboardHeight(show: Bool, notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.unsignedLongValue ?? UIViewAnimationOptions.CurveEaseInOut.rawValue
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (CGRectGetHeight(keyboardFrame)) //* (show ? 1 : -1)
        
        UIView.performWithoutAnimation({
            self.nameVTFView.layoutIfNeeded()
            self.phoneNumberVTFView.layoutIfNeeded()
        })
        
        if show {
            self.updateButtonBottomConstraint.constant = changeInHeight
        }
        else {
            self.updateButtonBottomConstraint.constant = 0
        }
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShow(sender: NSNotification) {
        adjustingKeyboardHeight(true, notification: sender)
    }
    
    func keyboardWillHide(sender: NSNotification) {
        adjustingKeyboardHeight(false, notification: sender)
    }
    
    // MARK: - UIImagePickerController Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profileImageView.image = pickedImage
            profileImageUpdated = true
            updatesToSave()
        }
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func selectPhoto(tap: UITapGestureRecognizer) {
        print("Select photo")
        self.imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .PhotoLibrary
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            self.imagePicker.sourceType = .Camera
        }
        else {
            self.imagePicker.sourceType = .PhotoLibrary
        }
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }

}
