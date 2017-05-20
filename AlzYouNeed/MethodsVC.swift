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

class MethodsVC: UIViewController, GIDSignInUIDelegate {
    
    @IBOutlet var googleButton: GIDSignInButton!
    @IBOutlet var emailButton: UIButton!

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
        
        self.navigationController?.navigationBar.barTintColor = UIColor(hex: "4392F1")
        
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
        googleButton.style = GIDSignInButtonStyle.wide
    }

    func presentNextVC() {
        print("Present familyStepVC")
        // Present next VC
        self.performSegue(withIdentifier: "methodsToFamily", sender: self)
    }

}
