//
//  MethodsVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/19/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FontAwesome_swift
import FBSDKLoginKit

class MethodsVC: UIViewController, GIDSignInUIDelegate {
    
    @IBOutlet var facebookButton: UIButton!
    @IBOutlet var googleButton: UIButton!
    @IBOutlet var emailButton: UIButton!
    
    var authListener: FIRAuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        GIDSignIn.sharedInstance().uiDelegate = self
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        authListener = FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if let user = user {
                print("MethodsVC: User signed in")
                
                let firstName = (user.displayName?.components(separatedBy: " ").first)!
                let photoURL = (user.photoURL?.absoluteString)!
                
                // Save to NewProfile
                NewProfile.sharedInstance.name = firstName
                NewProfile.sharedInstance.photoURL = photoURL
                
                // Save user
                FirebaseManager.updateUser(updates: NewProfile.sharedInstance.asDict() as NSDictionary, completionHandler: { (error) in
                    if let error = error {
                        print("Error updating user: ", error.localizedDescription)
                    } else {
                        print("Updated user")
                        self.presentNextVC()
                    }
                })
            } else {
                print("MethodsVC: No user signed in")
            }
        })
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupView() {
        setupEmailButton()
        setupGoogleButton()
        setupFacebookButton()
        
        setupNavBar()
        
        UIApplication.shared.statusBarStyle = .default
        
        // Notified from AppDelegate -- authListener can do this
//        NotificationCenter.default.addObserver(self, selector: #selector(MethodsVC.presentNextVC), name: NSNotification.Name(rawValue: signInNotificationKey), object: nil)
    }
    
    func setupEmailButton() {
        let emailIcon = NSMutableAttributedString(string: "\(String.fontAwesomeIcon(name: .envelope))", attributes: [NSFontAttributeName: UIFont.fontAwesome(ofSize: 22)])

        emailButton.setAttributedTitle(emailIcon, for: .normal)
        emailButton.tintColor = UIColor.white
        emailButton.backgroundColor = UIColor(hex: "7189FF")
        emailButton.layer.cornerRadius = 5
        emailButton.layer.shadowColor = UIColor.black.cgColor
        emailButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        emailButton.layer.shadowOpacity = 0.5
        emailButton.layer.shadowRadius = 1
        emailButton.layer.masksToBounds = false
    }
    
    func setupGoogleButton() {
        let googleIcon = NSMutableAttributedString(string: "\(String.fontAwesomeIcon(name: .google))", attributes: [NSFontAttributeName: UIFont.fontAwesome(ofSize: 22)])
        
        googleButton.setAttributedTitle(googleIcon, for: .normal)
        googleButton.tintColor = UIColor.white
        googleButton.backgroundColor = UIColor(hex: "7189FF")
        googleButton.layer.cornerRadius = 5
        googleButton.layer.shadowColor = UIColor.black.cgColor
        googleButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        googleButton.layer.shadowOpacity = 0.5
        googleButton.layer.shadowRadius = 1
        googleButton.layer.masksToBounds = false
    }
    
    func setupFacebookButton() {
        let facebookIcon = NSMutableAttributedString(string: "\(String.fontAwesomeIcon(name: .facebook))", attributes: [NSFontAttributeName: UIFont.fontAwesome(ofSize: 22)])

        facebookButton.setAttributedTitle(facebookIcon, for: .normal)
        facebookButton.tintColor = UIColor.white
        facebookButton.backgroundColor = UIColor(hex: "7189FF")
        facebookButton.layer.cornerRadius = 5
        facebookButton.layer.shadowColor = UIColor.black.cgColor
        facebookButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        facebookButton.layer.shadowOpacity = 0.5
        facebookButton.layer.shadowRadius = 1
        facebookButton.layer.masksToBounds = false
    }
    
    func setupNavBar() {
        self.navigationController?.navigationBar.barTintColor = UIColor(hex: "FFFFFF")
        self.navigationController?.navigationBar.tintColor = UIColor(hex: "7189FF")
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor(hex: "7189FF"), NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 20)!]
    }

    func presentNextVC() {
        print("Present familyStepVC")
        // Present next VC
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "methodsToFamily", sender: self)
        }
    }

    // MARK: - Facebook signup
    @IBAction func facebookButtonPressed(_ sender: Any) {
        loginWithFacebook()
    }
    
    func loginWithFacebook() {
        FBSDKLoginManager().logIn(withReadPermissions: ["email", "public_profile"], from: self) { (result, error) in
            if error != nil {
                print("Error with custom Facebook login")
            } else {
                if let result = result, let resultToken = result.token, let resultTokenString = resultToken.tokenString {
                    if let credential = FIRFacebookAuthProvider.credential(withAccessToken: resultTokenString) as FIRAuthCredential? {
                        
                        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
                            if let error = error {
                                print("Error signing in with Facebook: \(error.localizedDescription)")
                                return
                            }
                            print("Signed in with Facebook")
                        })
                    }
                } else {
                    print("Unable to login with Facebook")
                }
            }
        }
    }
    
    // MARK: - Google signup
    @IBAction func googleButtonPressed(_ sender: Any) {
        loginWithGoogle()
    }
    
    func loginWithGoogle() {
        GIDSignIn.sharedInstance().signIn()
    }
    
    // MARK: - Cancel signup
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        // Delete partial user profile
        NewProfile.sharedInstance.resetModel()
        
        self.dismiss(animated: true, completion: nil)
    }

}
