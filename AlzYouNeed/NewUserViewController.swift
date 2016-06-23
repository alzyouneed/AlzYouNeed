//
//  NewUserViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class NewUserViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    
    let imagePicker = UIImagePickerController()
    
    // MARK: - UI Elements
    
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var nameValidateTextFieldView: validateTextFieldView!
    @IBOutlet var phoneNumberValidateTextFieldView: validateTextFieldView!
    @IBOutlet var emailValidateTextFieldView: validateTextFieldView!
    @IBOutlet var passwordValidateTextFieldView: validateTextFieldView!
    @IBOutlet var confirmPasswordValidateTextFieldView: validateTextFieldView!

    @IBOutlet var addPhotoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        
//        uploadPicture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    // MARK: - Firebase
//    
//    func uploadPicture() {
//        let storage = FIRStorage.storage()
//        let storageRef = storage.reference()
//        
//        //        let pictureRef = storageRef.child("test.jpg")
//        //        let pictureImagesRef = storageRef.child("images/test.jpg")
//        
//        let data = UIImageJPEGRepresentation(UIImage(named: "validEntry")!, 1)
//        let imageRef = storageRef.child("images/test.jpg")
//        
//        let uploadTask = imageRef.putData(data!, metadata: nil) { (metadata, error) in
//            if (error != nil) {
//                print("Error occurred while uploading picture: \(error)")
//            }
//            else {
//                print("Successfully uploaded picture at URL: \(metadata!.downloadURL)")
//            }
//        }
//    }
    
    func signUp() {
        if validFields() {
            // Try to sign up
        }
    }
    
    @IBAction func signUpUser(sender: UIButton) {
        signUp()
    }
    
    func configureView() {
        self.nameValidateTextFieldView.nameMode()
        self.phoneNumberValidateTextFieldView.phoneNumberMode()
        self.emailValidateTextFieldView.emailMode()
        self.passwordValidateTextFieldView.passwordMode(false)
        self.confirmPasswordValidateTextFieldView.passwordMode(true)
        
        // Set delegates
        self.nameValidateTextFieldView.textField.delegate = self
        self.phoneNumberValidateTextFieldView.textField.delegate = self
        self.emailValidateTextFieldView.textField.delegate = self
        self.passwordValidateTextFieldView.textField.delegate = self
        self.confirmPasswordValidateTextFieldView.textField.delegate = self
        
        self.nameValidateTextFieldView.textField.addTarget(self, action: #selector(NewUserViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.phoneNumberValidateTextFieldView.textField.addTarget(self, action: #selector(NewUserViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.emailValidateTextFieldView.textField.addTarget(self, action: #selector(NewUserViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.passwordValidateTextFieldView.textField.addTarget(self, action: #selector(NewUserViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.confirmPasswordValidateTextFieldView.textField.addTarget(self, action: #selector(NewUserViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        self.imagePicker.delegate = self
        self.userImageView.layer.masksToBounds = true
        self.userImageView.layer.cornerRadius = self.userImageView.frame.height/2
        self.userImageView.clipsToBounds = true
    }

    // MARK: - Validation
    func validFields() -> Bool {
        return validateName() && validatePhoneNumber() && validateEmail() && validatePassword() && validateConfirmPassword()
    }
    
    func validateName() -> Bool {
        let valid = !nameValidateTextFieldView.textField.text!.isEmpty
        if valid {
            nameValidateTextFieldView.isValid(true)
            return true
        }
        else {
            print("Name field empty")
            nameValidateTextFieldView.isValid(false)
            return false
        }
    }
    
    func validatePhoneNumber() -> Bool {
//        let PHONE_REGEX = "^\\d{3}-\\d{3}-\\d{4}$"
        // Supports phone number entry without hyphens
        let PHONE_REGEX = "^\\d{3}\\d{3}\\d{4}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let valid = phoneTest.evaluateWithObject(phoneNumberValidateTextFieldView.textField.text!)
        if valid {
            phoneNumberValidateTextFieldView.isValid(true)
            return true
        }
        else {
            print("Invalid phone number")
            phoneNumberValidateTextFieldView.isValid(false)
            return false
        }
    }
    
    func validateEmail() -> Bool {
        // Check empty
        if emailValidateTextFieldView.textField.text!.isEmpty {
            print("Email field empty")
            emailValidateTextFieldView.isValid(false)
            return false
        }
        else {
            // Check valid
            let userEmailAddress = emailValidateTextFieldView.textField.text
            let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
            let valid = NSPredicate(format: "SELF MATCHES %@", regex).evaluateWithObject(userEmailAddress)
            
            // For debugging
            if valid {
                emailValidateTextFieldView.isValid(true)
                return true
            }
            else {
                print("Invalid email")
                emailValidateTextFieldView.isValid(false)
                return false
            }
        }
    }
    
    func validatePassword() -> Bool {
        if passwordValidateTextFieldView.textField.text!.isEmpty {
            print("Password field empty")
            passwordValidateTextFieldView.isValid(false)
            return false
        }
        
        if passwordValidateTextFieldView.textField.text?.characters.count < 6 {
            print("Password not long enough")
            passwordValidateTextFieldView.isValid(false)
            return false
        }
        
        passwordValidateTextFieldView.isValid(true)
        return true
    }
    
    func validateConfirmPassword() -> Bool {
        if confirmPasswordValidateTextFieldView.textField.text!.isEmpty {
            print("Confirm password field empty")
            confirmPasswordValidateTextFieldView.isValid(false)
            return false
        }
        
        let passwordText = passwordValidateTextFieldView.textField.text
        let confirmPasswordText = confirmPasswordValidateTextFieldView.textField.text
        let passwordsMatch = passwordText == confirmPasswordText
        
        if passwordsMatch {
            confirmPasswordValidateTextFieldView.isValid(true)
            return true
        }
        else {
            print("Passwords do not match")
            confirmPasswordValidateTextFieldView.isValid(false)
            return false
        }
    }
    
    // MARK: - UIImagePickerController
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
//            self.userImageView.contentMode = .ScaleAspectFit
            self.userImageView.image = pickedImage
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
    
    @IBAction func addPhoto(sender: AnyObject) {
        selectPhoto()
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        let tag = textField.superview!.superview!.tag
        switch tag {
        case 0:
            if !nameValidateTextFieldView.textField.text!.isEmpty {
                phoneNumberValidateTextFieldView.textField.becomeFirstResponder()
            }
        case 1:
            if !phoneNumberValidateTextFieldView.textField.text!.isEmpty {
                emailValidateTextFieldView.textField.becomeFirstResponder()
            }
        case 2:
            if !emailValidateTextFieldView.textField.text!.isEmpty {
                passwordValidateTextFieldView.textField.becomeFirstResponder()
            }
        case 3:
            if !passwordValidateTextFieldView.textField.text!.isEmpty {
                confirmPasswordValidateTextFieldView.textField.becomeFirstResponder()
            }
        case 4:
            if !confirmPasswordValidateTextFieldView.textField.text!.isEmpty {
                self.view.endEditing(true)
                signUp()
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
        // Email textField
        case 2:
            validateEmail()
        // Password textField
        case 3:
            validatePassword()
        // Confirm password textField
        case 4:
            validateConfirmPassword()
        default:
            break
        }
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
