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
    }
    
    func cancelAccountCreation(sender: UIBarButtonItem) {
        // Delete user
        let user = FIRAuth.auth()?.currentUser
        
        user?.deleteWithCompletion({ (error) in
            if let error = error {
                print("Error occurred while deleting account: \(error)")
            }
            else {
                print("Account deleted")
                self.performSegueWithIdentifier("startOver", sender: self)
            }
        })
        deletePictureFromDatabase()
//        self.performSegueWithIdentifier("startOver", sender: self)
    }

    // MARK: - UIImagePickerController Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            dispatch_async(dispatch_get_main_queue(), { 
                self.userImageView.image = pickedImage
            })
//            self.userImageView.image = pickedImage
            addPhotoButton.hidden = true
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
            print("Name field empty")
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
            print("Invalid phone number")
            phoneNumberVTFView.isValid(false)
            return false
        }
    }
    
    // MARK: - Firebase
    func updateUserAccount() {
        if validFields() {
            let user = FIRAuth.auth()?.currentUser
            uploadPicture()
            if let user = user {
                let changeRequest = user.profileChangeRequest()
                changeRequest.displayName = nameVTFView.textField.text
                changeRequest.commitChangesWithCompletion({ (error) in
                    if let error = error {
                        print("An error happened: \(error)")
                    }
                    else {
                        print("User display name updated successfully")
                        self.saveUserToRealTimeDatabase()
                        
                        self.stepCompleted = true
                        if self.shouldPerformSegueWithIdentifier("familyStage", sender: self) {
                            self.performSegueWithIdentifier("familyStage", sender: self)
                        }
//                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                })
            }
        }
    }
    
    func updateUserPhotoURL(url: String) {
        let user = FIRAuth.auth()?.currentUser
        if let user = user {
            let changeRequest = user.profileChangeRequest()
            changeRequest.photoURL = NSURL(string: url)
            
            changeRequest.commitChangesWithCompletion({ (error) in
                if let error = error {
                    print("An error happened: \(error)")
                }
                else {
                    print("User photo URL updated successfully")
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
        if let user = FIRAuth.auth()?.currentUser {
            if let userImage = userImageView.image {
                let storage = FIRStorage.storage()
                let storageRef = storage.reference()
                
                let data = UIImageJPEGRepresentation(userImage, 1)
                
                let imageRef = storageRef.child("userImages/\(user.uid)")
                
                let uploadTask = imageRef.putData(data!, metadata: nil) { (metadata, error) in
                    if (error != nil) {
                        print("Error occurred while uploading picture: \(error)")
                    }
                    else {
                        print("Successfully uploaded picture")
                        if let url = metadata!.downloadURL()?.absoluteString {
                            // Update photo URL
                            self.updateUserPhotoURL(url)
                        }
                    }
                }
                print("No image to upload")
            }
        }
    }
    
    func deletePictureFromDatabase() {
        if let user = FIRAuth.auth()?.currentUser {
            let storage = FIRStorage.storage()
            let storageRef = storage.reference()
        
            let userImageRef = storageRef.child("userImages/\(user.uid)")
            
            userImageRef.deleteWithCompletion({ (error) in
                if (error != nil) {
                    print("Error deleting file: \(error)")
                }
                else {
                    print("File deleted successfully")
                }
            })
        }
    }
    
    func saveUserToRealTimeDatabase() {
        if let user = FIRAuth.auth()?.currentUser {
            print("Saving user to realtime DB")
            
            let databaseRef = FIRDatabase.database().reference()
            
            let userToSave = ["name": nameVTFView.textField.text!, "email": "\(user.email!)", "phoneNumber": phoneNumberVTFView.textField.text!, "familyID": "", "patient": "false", "completedSignup": "false", "photoURL":""]
            
            databaseRef.child("users/\(user.uid)").setValue(userToSave)
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        let tag = textField.superview!.superview!.tag
        switch tag {
        case 0:
            if !nameVTFView.textField.text!.isEmpty {
                phoneNumberVTFView.textField.becomeFirstResponder()
            }
        case 1:
            if !phoneNumberVTFView.textField.text!.isEmpty {
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
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "familyStage" {
            if stepCompleted {
                return true
            }
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
