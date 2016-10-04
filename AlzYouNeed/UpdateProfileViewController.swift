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
// import PKHUD

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
        
        if AYNModel.sharedInstance.currentUser != nil {
            self.userName = AYNModel.sharedInstance.currentUser?.object(forKey: "name") as! String
            self.userPhoneNumber = AYNModel.sharedInstance.currentUser?.object(forKey: "phoneNumber") as! String
            self.userPhotoUrl = AYNModel.sharedInstance.currentUser?.object(forKey: "photoUrl") as! String
            
            self.configureView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(UpdateProfileViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UpdateProfileViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        self.nameVTFView.nameMode()
        self.phoneNumberVTFView.phoneNumberMode()
        
        DispatchQueue.main.async { 
            self.nameVTFView.textField.placeholder = self.userName
            self.phoneNumberVTFView.textField.placeholder = self.userPhoneNumber
        }
        
        self.nameVTFView.textField.delegate = self
        self.phoneNumberVTFView.textField.delegate = self
        
        self.nameVTFView.textField.addTarget(self, action: #selector(UpdateProfileViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        self.phoneNumberVTFView.textField.addTarget(self, action: #selector(UpdateProfileViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        
        configureImagePicker()
        configureProfileImage(userPhotoUrl)
        _ = updatesToSave()
    }
    
    func configureProfileImage(_ photoUrl: String) {
        if photoUrl.hasPrefix("gs://") {
            FIRStorage.storage().reference(forURL: photoUrl).data(withMaxSize: INT64_MAX, completion: { (data, error) in
                if let error = error {
                    // Error
                    print("Error downloading user profile image: \(error.localizedDescription)")
                    return
                }
                // Success
                DispatchQueue.main.async(execute: {
                    self.profileImageView.image = UIImage(data: data!)
                })
            })
        } else if let url = URL(string: photoUrl), let data = try? Data(contentsOf: url) {
            DispatchQueue.main.async(execute: {
                self.profileImageView.image = UIImage(data: data)
            })
        }
    }
    
    func configureImagePicker() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height/2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = slateBlue.cgColor
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UpdateUserViewController.selectPhoto(_:)))
        tap.numberOfTapsRequired = 1
        profileImageView.addGestureRecognizer(tap)
        print("configured image picker")
    }
    
    @IBAction func updateProfile(_ sender: UIButton) {
        if updatesToSave() {
            // Update profile and return to previous VC
            print("Updates to save")
            var updates = [String: NSObject]()
            
            
            // Remove if no updates
            if nameUpdate() {
                updates["name"] = nameVTFView.textField.text! as NSObject?
            }
            if phoneNumberUpdate() {
                updates["phoneNumber"] = phoneNumberVTFView.textField.text! as NSObject?
            }
            if profileImageUpdated {
                var imageData = Data()
                if let profileImage = profileImageView.image {
                    imageData = UIImageJPEGRepresentation(profileImage, 0.1)!
                }
                updates["profileImage"] = imageData as NSObject?
            }
            
            // Show progress view
            // HUD.show(.Progress)

            FirebaseManager.updateUser(updates as NSDictionary, completionHandler: { (error) in
                if error == nil {
                    // Updated user -- Return to previous VC
                    //HUD.flash(.Success, delay: 0, completion: { (success) in
                        print("Profile updated -- returning to VC")
                        self.view.endEditing(true)
                        AYNModel.sharedInstance.profileWasUpdated = true
                        _ = self.navigationController?.popToRootViewController(animated: true)
                    //})
                } else {
                    // Error
                    //HUD.flash(.Error, delay: 0, completion: { (success) in
                        print("Error updating user")
                    //})
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
        let valid = phoneTest.evaluate(with: phoneNumberVTFView.textField.text!)
        if valid {
            phoneNumberVTFView.isValid(true)
            return true
        }
        else {
            phoneNumberVTFView.isValid(false)
            return false
        }
    }
    
    func enableUpdateButton(_ enable: Bool) {
        if enable {
           updateButton.alpha = 1
            updateButton.isEnabled = true
        }
        else {
            updateButton.alpha = 0.5
            updateButton.isEnabled = false
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldDidChange(_ textField: UITextField) {
        let tag = textField.superview!.superview!.tag
        
        switch tag {
        // Name textField
        case 0:
            _ = validateName()
        // Phone number textField
        case 1:
            _ = validatePhoneNumber()
        default:
            break
        }
        
        _ = updatesToSave()
    }
    
    // MARK: - Keyboard
    func adjustingKeyboardHeight(_ show: Bool, notification: Notification) {
        let userInfo = (notification as NSNotification).userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.uintValue 
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (keyboardFrame.height) //* (show ? 1 : -1)
        
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
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShow(_ sender: Notification) {
        adjustingKeyboardHeight(true, notification: sender)
    }
    
    func keyboardWillHide(_ sender: Notification) {
        adjustingKeyboardHeight(false, notification: sender)
    }
    
    // MARK: - UIImagePickerController Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profileImageView.image = pickedImage
            profileImageUpdated = true
            _ = updatesToSave()
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func selectPhoto(_ tap: UITapGestureRecognizer) {
        print("Select photo")
        self.imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.imagePicker.sourceType = .camera
        }
        else {
            self.imagePicker.sourceType = .photoLibrary
        }
        
        present(imagePicker, animated: true, completion: nil)
    }

}
