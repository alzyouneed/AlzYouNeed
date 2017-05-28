//
//  UpdateProfileTVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/27/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit
import PKHUD
import SkyFloatingLabelTextField
import Firebase
import FBSDKLoginKit
import GoogleSignIn

class UpdateProfileTVC: UITableViewController, UINavigationControllerDelegate {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var notificationCell: UITableViewCell!
    
    // For user reauth
    var emailTextField: UITextField!
    var passwordTextField: UITextField!
    
    var authListener: FIRAuthStateDidChangeListenerHandle?
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupAuthListener()
        setupNameLabel()
        self.navigationController?.navigationBar.tintColor = UIColor(hex: "7189FF")
        UIApplication.shared.statusBarStyle = .default
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let authListener = authListener {
            FIRAuth.auth()?.removeStateDidChangeListener(authListener)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupView() {
        setupUserImageView()
        setupNameLabel()
        imagePicker.delegate = self
        setupNotificationCell()
    }
    
    func setupUserImageView() {
        userImageView.layer.masksToBounds = false
        userImageView.layer.cornerRadius = self.userImageView.frame.height/2
        userImageView.clipsToBounds = true
//        userImageView.layer.borderWidth = 2
//        userImageView.layer.borderColor = UIColor.white.cgColor
//        userImageView.layer.borderColor = UIColor(hex: "7189FF").cgColor
        
        if let userImage = AYNModel.sharedInstance.userImage {
            userImageView.image = userImage
        }
    }
    
    func setupNameLabel() {
        if let user = FIRAuth.auth()?.currentUser {
            self.nameLabel.text = user.displayName?.components(separatedBy: " ").first
        }
    }
    
    func setupNotificationCell() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UpdateProfileTVC.notificationCellTapped))
        notificationCell.addGestureRecognizer(tap)
    }

    @IBAction func changePicturePressed(_ sender: UIButton) {
        showPhotoOptions()
    }
    
    @IBAction func deleteAccountButtonPressed(_ sender: UIButton) {
        showDeleteAccountWarning()
    }
    
    func notificationCellTapped() {
        print("tapped")
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    
    func showDeleteAccountWarning() {
        let alertController = UIAlertController(title: "Delete Account", message: "This cannot be undone", preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.deleteAccount()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func deleteAccount() {
        let user = FIRAuth.auth()?.currentUser
        
        user?.delete { error in
            if let error = error {
                print("Error deleting user: ", error.localizedDescription)
                let errorCode = FIRAuthErrorCode(rawValue: error._code)!
                if errorCode == FIRAuthErrorCode.errorCodeInvalidUserToken || errorCode == FIRAuthErrorCode.errorCodeRequiresRecentLogin {
                    self.showReAuthOptions()
                }
            } else {
                print("Account deleted")
                AYNModel.sharedInstance.resetModel()
                UserDefaultsManager.reset()
            }
        }
    }
    
    // MARK: - Authentication
    func showReAuthOptions() {
        let authOptions = UIAlertController(title: "Sign in to Continue", message: "Select your sign-in method to complete this action", preferredStyle: .actionSheet)
        
        let facebookOption = UIAlertAction(title: "Facebook", style: .default) { (action) in
            self.reAuthUser(provider: "Facebook", email: nil, password: nil)
        }
        let googleOption = UIAlertAction(title: "Google", style: .default) { (action) in
            self.reAuthUser(provider: "Google", email: nil, password: nil)
        }
        let emailOption = UIAlertAction(title: "Email", style: .default) { (action) in
            self.showEmailLogin()
        }
        let cancelOption = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        authOptions.addAction(facebookOption)
        authOptions.addAction(googleOption)
        authOptions.addAction(emailOption)
        authOptions.addAction(cancelOption)
        
        self.present(authOptions, animated: true, completion: nil)
    }
    
    func showEmailLogin() {
        let emailAlert = UIAlertController(title: "Email Sign-in", message: "Login using your Email and Password to continue", preferredStyle: .alert)
        
        emailAlert.addTextField { (textField) in
            textField.placeholder = "Email address"
            textField.keyboardType = UIKeyboardType.emailAddress
            self.emailTextField = textField
        }
        emailAlert.addTextField { (textField) in
            textField.placeholder = "Password"
            self.passwordTextField = textField
        }
        
        let loginAction = UIAlertAction(title: "Sign in", style: .default) { (action) in
            if let email = self.emailTextField.text, let password = self.passwordTextField.text {
                self.reAuthUser(provider: "Email", email: email, password: password)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        emailAlert.addAction(loginAction)
        emailAlert.addAction(cancelAction)
        
        self.present(emailAlert, animated: true, completion: nil)
    }
    
    func reAuthUser(provider: String, email: String?, password: String?) {
        let user = FIRAuth.auth()?.currentUser
        var credential: FIRAuthCredential? = nil
        
        if provider == "Facebook" {
            credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        } else if provider == "Google" {
            if let authentication = GIDSignIn.sharedInstance().currentUser.authentication {
                credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            }
        } else if provider == "Email" {
            if let email = email, let password = password {
                credential = FIREmailPasswordAuthProvider.credential(withEmail: email, password: password)
            }
        }
        
        if credential != nil {
            // Prompt the user to re-provide their sign-in credentials
            user?.reauthenticate(with: credential!) { error in
                if let error = error {
                    print("Error reauthenticating user: ", error.localizedDescription)
                    HUD.flash(.error)
                } else {
                    print("Reauthenticated user")
                    HUD.flash(.label("Signed in"), delay: 0, completion: { (complete) in
                        // User re-authenticated.
                        self.deleteAccount()
                    })
                }
            }
        }
    }
    
    func setupAuthListener() {
        authListener = FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if user != nil {
                // User still signed in
            } else {
                print("UpdateProfileTVC: No user signed in")
                self.presentOnboardingVC()
            }
        })
    }

    // MARK: - Navigation
    func presentOnboardingVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "loginNav") as! UINavigationController
        self.present(onboardingVC, animated: true, completion: nil)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeName" {
            if let destVC: UpdateActionVC = segue.destination as? UpdateActionVC {
                destVC.type = "changeName"
            }
        } else if segue.identifier == "changePassword" {
            if let destVC: UpdateActionVC = segue.destination as? UpdateActionVC {
                destVC.type = "changePassword"
            }
        }
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}

// MARK: - UIImagePickerController Delegate
extension UpdateProfileTVC: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            HUD.show(.progress)
            print("Selected image -- uploading")
            FirebaseManager.updateUserImage(image: pickedImage, completionHandler: { (error) in
                if let error = error {
                    HUD.flash(.error)
                    print("Error uploading image: ", error.localizedDescription)
                } else {
                    HUD.flash(.success)
                    print("Updated user image")
                    self.userImageView.image = pickedImage
                    AYNModel.sharedInstance.userImage = pickedImage
                }
            })
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func showPhotoOptions() {
        let photoSheet = UIAlertController(title: nil, message: "Select a source", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Take photo", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                print("Selecting from Camera")
                self.imagePicker.allowsEditing = true
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
        let libraryAction = UIAlertAction(title: "Browse photo library", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                print("Selecting from Photo Library")
                self.imagePicker.allowsEditing = true
                self.imagePicker.sourceType = .photoLibrary
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        photoSheet.addAction(cameraAction)
        photoSheet.addAction(libraryAction)
        photoSheet.addAction(cancelAction)
        
        present(photoSheet, animated: true, completion: nil)
    }
}
