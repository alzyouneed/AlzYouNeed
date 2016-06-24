//
//  FamilySignupViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class FamilySignupViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    
    var newFamily = true
    
    // MARK: - UI Elements
    
    
    @IBOutlet var familyIdVTFView: validateTextFieldView!
    @IBOutlet var passwordVTFView: validateTextFieldView!
    @IBOutlet var confirmPasswordVTFView: validateTextFieldView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Firebase
    func createNewFamily(familyId: String, password: String) {
        if newFamily {
            if let user = FIRAuth.auth()?.currentUser {
                print("Saving new family to realtime DB")
                let databaseRef = FIRDatabase.database().reference()
                
                // Add current user as first family member
                self.getUserPatientStatus({ (patientStatus) in
                    let familyToSave = ["password": password, "members":[user.uid: ["name":user.displayName!, "admin": "true", "patient": patientStatus]]]
                    
                    // Update current user and new family
                    let childUpdates = ["/users/\(user.uid)/familyId": familyId, "/users/\(user.uid)/completedSignup": "true", "/families/\(familyId)": familyToSave]
                    databaseRef.updateChildValues(childUpdates as [NSObject : AnyObject])
                    
                    // Signup Complete
                    self.view.endEditing(true)
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            }
        }
    }
    
    func joinFamily(familyId: String, password: String) {
        if let user = FIRAuth.auth()?.currentUser {
            
            getFamilyPassword(familyId, completionHandler: { (familyPassword) -> Void in
                if familyPassword == password {
                    print("Joining family: \(familyId)")
                    
                    let databaseRef = FIRDatabase.database().reference()
                    
                    self.getUserPatientStatus({ (patientStatus) in
                        let userToAdd = ["name":user.displayName!, "admin": "false", "patient": patientStatus]
                        
                        // Update current user and new family
                        let childUpdates = ["/users/\(user.uid)/familyId": familyId, "/users/\(user.uid)/completedSignup": "true"]
                        databaseRef.updateChildValues(childUpdates as [NSObject : AnyObject])
                        databaseRef.child("families").child(familyId).child("members").child(user.uid).setValue(userToAdd)
                        
                        // Signup Complete
                        self.view.endEditing(true)
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                }
                else {
                   print("Incorrect password to join family: \(familyId)")
                }
            })
        }
    }
    
    @IBAction func createOrJoinFamily(sender: UIButton) {
        // Create family
        if newFamily {
            createNewFamily(familyIdVTFView.textField.text!, password: passwordVTFView.textField.text!)
        }
        // Join family
        else {
            joinFamily(familyIdVTFView.textField.text!, password: passwordVTFView.textField.text!)
        }
    }
    
    func getUserPatientStatus(completionHandler:(String)->()){
        var status = "false"
        
        let userId = FIRAuth.auth()?.currentUser?.uid
        let databaseRef = FIRDatabase.database().reference()
        
        databaseRef.child("users").child(userId!).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let patientStatus = snapshot.value!["patient"] as? String {
                status = patientStatus
                completionHandler(status)
            }
        }) { (error) in
            completionHandler(status)
            print(error.localizedDescription)
        }
    }
    
    // Retrieve password to family group for comparison
    func getFamilyPassword(familyId: String, completionHandler:(String)->()){
        var familyPassword = ""
        
        let databaseRef = FIRDatabase.database().reference()
        
        databaseRef.child("families").child(familyId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let password = snapshot.value!["password"] as? String {
                familyPassword = password
                completionHandler(familyPassword)
            }
        }) { (error) in
            completionHandler(familyPassword)
            print(error.localizedDescription)
        }
    }
    
    func configureView() {
        if newFamily {
            confirmPasswordVTFView.hidden = false
        }
        else {
            confirmPasswordVTFView.hidden = true
        }
        configureTextFieldViews()
    }
    
    func configureTextFieldViews() {
        self.familyIdVTFView.familyIdMode()
        self.passwordVTFView.passwordMode(false)
        self.confirmPasswordVTFView.passwordMode(true)
        
        //        self.passwordVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        //        self.confirmPasswordVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        //        let tag = textField.superview!.superview!.tag
        //        switch tag {
        //        case 0:
        //            if !emailValidateTextFieldView.textField.text!.isEmpty {
        //                passwordValidateTextFieldView.textField.becomeFirstResponder()
        //            }
        //        case 1:
        //            if !passwordValidateTextFieldView.textField.text!.isEmpty {
        //                confirmPasswordValidateTextFieldView.textField.becomeFirstResponder()
        //            }
        //        case 2:
        //            if !confirmPasswordValidateTextFieldView.textField.text!.isEmpty {
        //                signUpUser()
        //            }
        //        default:
        //            break
        //        }
        return true
    }
    
    func textFieldDidChange(textField: UITextField) {
        //        let tag = textField.superview!.superview!.tag
        //
        //        switch tag {
        //        // Email textField
        //        case 0:
        //            validateEmail()
        //        // Password textField
        //        case 1:
        //            validatePassword()
        //        // Confirm password textField
        //        case 2:
        //            validateConfirmPassword()
        //        default:
        //            break
        //        }
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
