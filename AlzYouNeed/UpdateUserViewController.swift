//
//  UpdateUserViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
// import PKHUD

class UpdateUserViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - UI Elements
    @IBOutlet var nameVTFView: validateTextFieldView!
    @IBOutlet var phoneNumberVTFView: validateTextFieldView!
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var addPhotoButton: UIButton!
    @IBOutlet var patientSwitch: UISwitch!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var cancelButton: UIBarButtonItem!
    
    @IBOutlet var profileImageView: UIImageView!
    let imagePicker = UIImagePickerController()
    @IBOutlet var addPhotoLabel: UILabel!
    
    // MARK: - Properties
    var stepCompleted = false
    @IBOutlet var nextButtonBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.presentTransparentNavBar()
        
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(UpdateUserViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UpdateUserViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.nameVTFView.textField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.5, animations: {
            self.progressView.setProgress(0.25, animated: true)
        }) 
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureView() {
        self.navigationItem.hidesBackButton = true

        self.nameVTFView.nameMode()
        self.phoneNumberVTFView.phoneNumberMode()
        
        self.nameVTFView.textField.delegate = self
        self.phoneNumberVTFView.textField.delegate = self
        
        self.nameVTFView.textField.addTarget(self, action: #selector(UpdateUserViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        self.phoneNumberVTFView.textField.addTarget(self, action: #selector(UpdateUserViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

        self.addPhotoButton.layer.cornerRadius = self.addPhotoButton.frame.height/2
        
        signUpButtonEnabled()
        configureImagePicker()
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
    
    func signUpButtonEnabled() {
        if validFields() {
            signUpButton.isEnabled = true
            signUpButton.alpha = 1
        }
        else {
            signUpButton.isEnabled = false
            signUpButton.alpha = 0.5
        }
    }
    
    func signUpButtonEnabled(_ enabled: Bool) {
        if enabled {
            signUpButton.isEnabled = true
            signUpButton.alpha = 1
        }
        else {
            signUpButton.isEnabled = false
            signUpButton.alpha = 0.5
        }
    }

    // MARK: - UIImagePickerController Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profileImageView.image = pickedImage
            self.addPhotoLabel.isHidden = true
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
    
    @IBAction func addPhoto(_ sender: UIBarButtonItem) {
//        selectPhoto()
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
        
//        let PHONE_REGEX = "(?\\d{3})?\\s\\d{3}-\\d{4}$"

        // Supports phone number entry without hyphens
        let PHONE_REGEX = "^\\d{3}\\d{3}\\d{4}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let valid = phoneTest.evaluate(with: phoneNumberVTFView.textField.text!)
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
            
            // Disable interface to avoid extra interaction
            interfaceEnabled(false)
            
            // Show progress view
            // HUD.show(.Progress)
            
            guard let name = nameVTFView.textField.text , !name.isEmpty, let phoneNumber = phoneNumberVTFView.textField.text , !phoneNumber.isEmpty else {
                return
            }
            
//            let updates = ["name": self.nameVTFView.textField.text!, "phoneNumber": self.phoneNumberVTFView.textField.text!, "patientStatus":self.patientStatus(), "avatarId": self.selectionView.avatarId(), "completedSignup": "familySetup"]
            
            var imageData = Data()
            if let profileImage = profileImageView.image {
                imageData = UIImageJPEGRepresentation(profileImage, 0.1)!
            }
            
            let updates = ["name": self.nameVTFView.textField.text!, "phoneNumber": self.phoneNumberVTFView.textField.text!, "patient":self.patientStatus(), "completedSignup": "familySetup", "profileImage": imageData] as [String : Any]
            
            FirebaseManager.updateUser(updates as NSDictionary, completionHandler: { (error) in
                if error != nil {
                    // Failed to update user
                    // HUD.hide({ (success) in
                        self.interfaceEnabled(true)
                    // })
                }
                else {
                    // Updated user
                    // HUD.flash(.Success, delay: 0, completion: { (success) in
                        self.stepCompleted = true
                        self.view.endEditing(true)
                        self.performSegue(withIdentifier: "relation", sender: self)
                    // })
                }
            })
        }
    }
    
    func patientStatus() -> String {
        if patientSwitch.isOn {
            return "true"
        }
        else {
            return "false"
        }
    }
    
    @IBAction func completeSetup(_ sender: UIButton) {
        if validFields() {
            if let cancelButton = (self.navigationItem.rightBarButtonItems?.first) {
                cancelButton.isEnabled = false
            }
            updateUserAccount()
        }
    }
    
    @IBAction func cancelOnboarding(_ sender: UIBarButtonItem) {
        cancelAccountCreation()
    }
    
    func cancelAccountCreation() {
        
        let alertController = UIAlertController(title: "Cancel Signup", message: "All progress will be lost", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { (action) in
            self.deleteUser()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func deleteUser() {
        FirebaseManager.deleteCurrentUser { (error) in
            if error != nil {
                // Error deleting user
            }
            else {
                // Successfully deleted user
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "onboardingNav") as! UINavigationController
                self.present(onboardingVC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
        
        signUpButtonEnabled()
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
            self.nextButtonBottomConstraint.constant = changeInHeight
        }
        else {
            self.nextButtonBottomConstraint.constant = 0
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
    
    // MARK: - Interface Enable / Disable
    func interfaceEnabled(_ enabled: Bool) {
        signUpButtonEnabled(enabled)
        nameVTFView.textField.isUserInteractionEnabled = enabled
        phoneNumberVTFView.textField.isUserInteractionEnabled = enabled
        patientSwitch.isUserInteractionEnabled = enabled
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "relation" {
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
