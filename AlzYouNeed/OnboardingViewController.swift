//
//  OnboardingViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/16/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
// import PKHUD

class OnboardingViewController: UIViewController, UITextFieldDelegate {
    
    var loginMode = false
    
    @IBOutlet var emailVTFView: validateTextFieldView!
    @IBOutlet var passwordVTFView: validateTextFieldView!
    
    @IBOutlet var loginButtons: loginButtonsView!
    @IBOutlet var loginButtonsBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var appNameLabel: UILabel!
    @IBOutlet var logoImageTopConstraint: NSLayoutConstraint!
    @IBOutlet var appNameLabelTopConstraint: NSLayoutConstraint!
    
    // MARK: - Popover View Properties
    var errorPopoverView: popoverView!
    var shadowView: UIView!
    
    // MARK - Background Video Properties
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureView() {
        self.emailVTFView.emailMode()
        self.passwordVTFView.passwordMode(false)
        
        // Configure text color for dark background
        self.emailVTFView.textField.textColor = UIColor.white
        self.emailVTFView.textField.tintColor = UIColor.white
        self.passwordVTFView.textField.textColor = UIColor.white
        self.passwordVTFView.textField.tintColor = UIColor.white
        
        self.emailVTFView.textField.delegate = self
        self.passwordVTFView.textField.delegate = self

        loginButtons.leftButton.addTarget(self, action: #selector(OnboardingViewController.leftButtonAction(_:)), for: UIControlEvents.touchUpInside)
        loginButtons.rightButton.addTarget(self, action: #selector(OnboardingViewController.rightButtonAction(_:)), for: UIControlEvents.touchUpInside)
        
        // // TODO: Background Video
        configureBackgroundVideo()
//        emailVTFView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        self.view.bringSubview(toFront: emailVTFView)
        self.view.bringSubview(toFront: passwordVTFView)
        self.view.bringSubview(toFront: loginButtons)
        self.view.bringSubview(toFront: logoImageView)
        self.view.bringSubview(toFront: appNameLabel)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // TODO: Background Video
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated);
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // TODO: Background Video
        configureView()
        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingViewController.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
        logoImageView.alpha = 0
        appNameLabel.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loginButtons.resetState()
        showTitleView()
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func signUp() {
//        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let createUserVC: CreateUserViewController = storyboard.instantiateViewController(withIdentifier: "createUserVC") as! CreateUserViewController
//        self.navigationController?.pushViewController(createUserVC, animated: true)
        
        presentOnboardingVC()
    }
    
    func presentOnboardingVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        //        let storyboard: UIStoryboard = UIStoryboard(name: "OnboardingInitial", bundle: nil)
        let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "onboardingNav") as! UINavigationController
//        self.navigationController?.present(onboardingVC, animated: true, completion: nil)
//        self.present
        self.present(onboardingVC, animated: true, completion: nil)
    }
    
    func loginUser() {
        if !loginMode {
            showLoginView()
        }
        else {
            if validateLogin() {
                
                // Show progress view
                // HUD.show(.Progress)
                
                FIRAuth.auth()?.signIn(withEmail: emailVTFView.textField.text!, password: passwordVTFView.textField.text!, completion: { (user, error) in
                    if error == nil {
                        print("Login successful")
                        // HUD.flash(.Success, delay: 0, completion: { (success) in
                            self.view.endEditing(true)
                            AYNModel.sharedInstance.resetModel()
                            self.dismiss(animated: true, completion: nil)
                        // })
                    }
                    else {
                        print(error!)
                        // HUD.hide({ (success) in
                            self.showPopoverView(error! as NSError)
                        // })
                    }
                })
            }
        }
    }
    
    func leftButtonAction(_ sender: UIButton) {
        switch sender.currentTitle! {
        case "Sign up":
            signUp()
        case "Cancel":
            hideLoginView()
            self.view.endEditing(true)
        default:
            break
        }
    }
    
    func rightButtonAction(_ sender: UIButton) {
        switch sender.currentTitle! {
        case "Login":
            loginUser()
        default:
            break
        }
    }
    
    // MARK: - Validation
    func validateLogin() -> Bool {
        if emailVTFView.textField.text!.isEmpty {
            print("Missing email")
            return false
        }
        if passwordVTFView.textField.text!.isEmpty {
            print("Missing password")
            return false
        }
        return true
    }
    
    // MARK: - Login View
    func showLoginView() {
        if !loginMode {
            loginMode = true

            self.emailVTFView.isHidden = false
            self.passwordVTFView.isHidden = false

            self.emailVTFView.alpha = 0
            self.passwordVTFView.alpha = 0
            
            UIView.animate(withDuration: 0.4, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
                self.emailVTFView.alpha = 1
                self.passwordVTFView.alpha = 1
                
                self.logoImageView.alpha = 0
                self.appNameLabel.alpha = 0
                
            }) { (completed) in
                // Present keyboard
                self.emailVTFView.textField.becomeFirstResponder()
            }
        }
        else {
            hideLoginView()
        }
    }
    
    func hideLoginView() {
        if loginMode {

            self.resignFirstResponder()
            
            UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
                self.emailVTFView.alpha = 0
                self.passwordVTFView.alpha = 0
                
                self.logoImageView.alpha = 0.9
                self.appNameLabel.alpha = 1
                
            }) { (completed) in
                self.emailVTFView.textField.text = ""
                self.passwordVTFView.textField.text = ""
                
                self.emailVTFView.isHidden = true
                self.passwordVTFView.isHidden = true

                self.loginMode = false
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        let tag = textField.superview!.superview!.tag
        switch tag {
        case 0:
            if !emailVTFView.textField.text!.isEmpty {
                self.passwordVTFView.textField.becomeFirstResponder()
            }
        case 1:
            loginUser()
        default:
            break
        }
        return true
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
            self.emailVTFView.layoutIfNeeded()
            self.passwordVTFView.layoutIfNeeded()
        })
        
        if show {
            self.loginButtonsBottomConstraint.constant = changeInHeight
        }
        else {
            self.loginButtonsBottomConstraint.constant = 0
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
    
    // MARK: - Popover View
    func showPopoverView(_ error: NSError) {
        // Hide keyboard
        self.view.endEditing(true)
        
        // Configure view size
        errorPopoverView = popoverView(frame: CGRect(x: self.view.frame.width/2 - 100, y: self.view.frame.height/2 - 200, width: 200, height: 200))
        // Add popover message
        errorPopoverView.configureWithError(error)
        // Add target to hide view
        errorPopoverView.confirmButton.addTarget(self, action: #selector(OnboardingViewController.hidePopoverView(_:)), for: UIControlEvents.touchUpInside)
        
        // Configure shadow view
        shadowView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        shadowView.backgroundColor = UIColor.black
        
        self.view.addSubview(shadowView)
        self.view.addSubview(errorPopoverView)
        
        errorPopoverView.isHidden = false
        errorPopoverView.alpha = 0
        
        shadowView.isHidden = false
        shadowView.alpha = 0
        
        UIView.animate(withDuration: 0.35, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.errorPopoverView.alpha = 1
            self.shadowView.alpha = 0.2
            }, completion: { (completed) in
        })
    }
    
    func hidePopoverView(_ sender: UIButton) {
        UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.errorPopoverView.alpha = 0
            self.shadowView.alpha = 0
            }, completion: { (completed) in
                self.errorPopoverView.isHidden = true
                self.shadowView.isHidden = true
                
                self.errorPopoverView.removeFromSuperview()
                self.shadowView.removeFromSuperview()
                
                // Show keyboard again
                self.passwordVTFView.textField.becomeFirstResponder()
        })
    }
    
    // MARK: - Title View Animations
    func showTitleView() {
        self.logoImageTopConstraint.constant = 130
        self.appNameLabelTopConstraint.constant = 16
        self.view.layoutIfNeeded()
        self.logoImageTopConstraint.constant = 110
        self.appNameLabelTopConstraint.constant = 8
        
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.logoImageView.alpha = 0.9
            self.view.layoutIfNeeded()
            }) { (completed) in
        }
        UIView.animate(withDuration: 0.3, delay: 0.15, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.appNameLabel.alpha = 1
        }) { (completed) in
        }
    }
    
    // MARK: - TODO: Background Video
    func configureBackgroundVideo() {
//        let filePath = NSBundle.mainBundle().pathForResource("islandViewBW", ofType: "gif")
//        let gif = NSData(contentsOfFile: filePath!)
//        
//        let webViewBG = UIWebView(frame: self.view.frame)
//        webViewBG.loadData(gif!, MIMEType: "image/gif", textEncodingName: String(), baseURL: NSURL())
//        webViewBG.userInteractionEnabled = false
//        self.view.addSubview(webViewBG)
        
//        let movieFilePath = NSBundle.mainBundle().pathForResource("islandView3", ofType: "mp4")
        let movieFilePath = Bundle.main.path(forResource: "beach", ofType: "mp4")
        if let movieFilePath = movieFilePath {
            print("Configuring background video")
            player = AVPlayer(url: URL(fileURLWithPath: movieFilePath))
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.view.frame
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.view.layer.addSublayer(playerLayer)
            player?.actionAtItemEnd = .none
            player?.isMuted = true
            player?.seek(to: kCMTimeZero)
            player?.play()
        }
        
        let filter = UIView()
        filter.frame = self.view.frame
        filter.backgroundColor = UIColor.black
        filter.alpha = 0.4
        self.view.addSubview(filter)
    }
    
    func playerItemDidReachEnd() {
        player!.seek(to: kCMTimeZero)
    }

}
