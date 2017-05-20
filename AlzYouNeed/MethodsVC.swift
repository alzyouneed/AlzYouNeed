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

class MethodsVC: UIViewController, GIDSignInUIDelegate, FBSDKLoginButtonDelegate {
    
    @IBOutlet var googleButton: GIDSignInButton!
    @IBOutlet var emailButton: UIButton!
    @IBOutlet var facebookButton: FBSDKLoginButton!

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
        let buttonText = String.fontAwesomeIcon(name: .envelope) + "  Email"
        emailButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 18)
        emailButton.setTitle(buttonText, for: .normal)
        emailButton.layer.cornerRadius = 5
        emailButton.layer.shadowColor = UIColor.black.cgColor
        emailButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        emailButton.layer.shadowOpacity = 0.5
        emailButton.layer.shadowRadius = 1
        emailButton.layer.masksToBounds = false
    }
    
    func setupGoogleButton() {
        googleButton.style = GIDSignInButtonStyle.standard
    }
    
    func setupFacebookButton() {
        facebookButton.delegate = self
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
    
    // TODO: Move this to
    // MARK: -- Facebook signup
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if let error = error {
                print("Error signing in with Facebook: \(error.localizedDescription)")
                return
            }
            let firstName = (user?.displayName?.components(separatedBy: " ").first)!
            let photoURL = (user?.photoURL?.absoluteString)!
//            print("Signing in with Facebook: name= \(firstName) --photoURL= \(photoURL) ")
            
            // Save to NewProfile
            NewProfile.sharedInstance.name = firstName
            NewProfile.sharedInstance.photoURL = photoURL
            
            self.presentNextVC()
        })

    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        // ...
    }
    
    // MARK: -- Cancel signup
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        // TODO: Delete partial user profile
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "loginNav") as! UINavigationController
        self.present(onboardingVC, animated: true, completion: nil)
    }
    

}
