//
//  UpdateUserViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class UpdateUserViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - UI Elements
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var nameVTFView: validateTextFieldView!
    @IBOutlet var phoneNumberVTFView: validateTextFieldView!
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var addPhotoButton: UIButton!
    
    // MARK: - Properties
    let imagePicker = UIImagePickerController()
    var stepCompleted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }

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
        
        self.imagePicker.delegate = self
        self.userImageView.layer.masksToBounds = true
        self.userImageView.layer.cornerRadius = self.userImageView.frame.height/2
        self.userImageView.clipsToBounds = true
        self.userImageView.layer.borderWidth = 2
        self.userImageView.layer.borderColor = UIColor.grayColor().CGColor
        
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
        // let PHONE_REGEX = "^\\d{3}-\\d{3}-\\d{4}$"
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
            FirebaseManager.updateUserDisplayName(nameVTFView.textField.text!, completionHandler: { (error) in
                if error != nil {
                    // Failed to update display name
                    self.signUpButtonEnabled(true)
                }
                else {
                    FirebaseManager.saveUserToRealTimeDatabase(self.nameVTFView.textField.text!, phoneNumber: self.phoneNumberVTFView.textField.text!, completionHandler: { (error, newDatabaseRef) in
                        if error != nil {
                            // Failed to save to realTime database
                            self.signUpButtonEnabled(true)
                        }
                        else {
                            
                            if let userImage = self.userImageView.image {
                                FirebaseManager.uploadPictureToDatabase(userImage, completionHandler: { (metadata, error) in
                                    if error != nil {
                                        // Error uploading picture
                                        self.signUpButtonEnabled(true)
                                    }
                                    else {
                                        if metadata != nil {
                                            // Picture uploaded successfully
                                            self.stepCompleted = true
                                            self.performSegueWithIdentifier("familyStage", sender: self)
                                        }
                                    }
                                })
                            }
                        }
                    })
                }
            })
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
    
    func uploadPicture() {
        if let userImage = userImageView.image {
            FirebaseManager.uploadPictureToDatabase(userImage, completionHandler: { (metadata, error) in
                if error != nil {
                    // Error uploading picture
                }
                else {
                    if metadata != nil {
                        // Picture uploaded successfully
                        self.stepCompleted = true
                        
                        // STILL NEEDS WORK -- Currently performs segue twice
                        self.performSegueWithIdentifier("familyStage", sender: self)
                    }
                }
            })
        }
    }
    
    func deletePictureFromDatabase() {
        FirebaseManager.deletePictureFromDatabase { (error) in
            if error != nil {
                // Failed to delete picture from database
            }
            else {
                // Successfully deleted picture from database
            }
        }
    }
    
    func saveUserToRealTimeDatabase() {
        FirebaseManager.saveUserToRealTimeDatabase(nameVTFView.textField.text!, phoneNumber: phoneNumberVTFView.textField.text!) { (error, newDatabaseRef) in
            if error != nil {
                // Error saving user to realTime database
            }
            else {
                // Successfully saved user to realTime database
            }
        }
    }
    
    func cancelAccountCreation(sender: UIBarButtonItem) {
        FirebaseManager.deleteCurrentUser { (error) in
            if error != nil {
                // Error deleting current user
            }
            else {
                // Successfully deleted current user
                self.performSegueWithIdentifier("startOver", sender: self)
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
