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
    
    @IBOutlet var emailButton: UIButton!
    @IBOutlet var facebookButton: UIButton!
    @IBOutlet var googleButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        GIDSignIn.sharedInstance().uiDelegate = self
        setupView()
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(MethodsVC.presentNextVC), name: NSNotification.Name(rawValue: signInNotificationKey), object: nil)
    }
    
    func setupEmailButton() {
        let emailIcon = NSMutableAttributedString(string: "\(String.fontAwesomeIcon(name: .envelope))", attributes: [NSFontAttributeName: UIFont.fontAwesome(ofSize: 18)])
        let emailText = NSMutableAttributedString(string: "  Email", attributes: [NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 18)!])
        
        emailIcon.append(emailText)
        
        emailButton.setAttributedTitle(emailIcon, for: .normal)
        emailButton.tintColor = UIColor.white
        emailButton.layer.cornerRadius = 5
        emailButton.layer.shadowColor = UIColor.black.cgColor
        emailButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        emailButton.layer.shadowOpacity = 0.5
        emailButton.layer.shadowRadius = 1
        emailButton.layer.masksToBounds = false
    }
    
    func setupGoogleButton() {
        let googleIcon = NSMutableAttributedString(string: "\(String.fontAwesomeIcon(name: .google))", attributes: [NSFontAttributeName: UIFont.fontAwesome(ofSize: 18)])
        let googleText = NSMutableAttributedString(string: "  Google", attributes: [NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 18)!])
        
        googleIcon.append(googleText)
        
        googleButton.setAttributedTitle(googleIcon, for: .normal)
        googleButton.tintColor = UIColor.white
        googleButton.layer.cornerRadius = 5
        googleButton.layer.shadowColor = UIColor.black.cgColor
        googleButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        googleButton.layer.shadowOpacity = 0.5
        googleButton.layer.shadowRadius = 1
        googleButton.layer.masksToBounds = false
    }
    
    func setupFacebookButton() {
        let facebookIcon = NSMutableAttributedString(string: "\(String.fontAwesomeIcon(name: .facebookSquare))", attributes: [NSFontAttributeName: UIFont.fontAwesome(ofSize: 18)])
        let facebookText = NSMutableAttributedString(string: "  Facebook", attributes: [NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 18)!])
        
        facebookIcon.append(facebookText)
        
        facebookButton.setAttributedTitle(facebookIcon, for: .normal)
        facebookButton.tintColor = UIColor.white
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
        self.performSegue(withIdentifier: "methodsToFamily", sender: self)
    }
    
    // TODO: Move this to AppDelegate
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
                            let firstName = (user?.displayName?.components(separatedBy: " ").first)!
                            let photoURL = (user?.photoURL?.absoluteString)!
                            
                            // Save to NewProfile
                            NewProfile.sharedInstance.name = firstName
                            NewProfile.sharedInstance.photoURL = photoURL
                            
                            self.presentNextVC()
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
        // TODO: Delete partial user profile
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "loginNav") as! UINavigationController
        self.present(onboardingVC, animated: true, completion: nil)
    }
    

}
