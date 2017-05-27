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
 import PKHUD
import Crashlytics
import SkyFloatingLabelTextField
import FBSDKLoginKit
import GoogleSignIn

class OnboardingViewController: UIViewController, UITextFieldDelegate, GIDSignInUIDelegate {
    
    var loginModeStatus = false
    var isAnimating = false
    var emailModeStatus = false
    
    @IBOutlet var signupButton: UIButton!
    @IBOutlet var loginButton: UIButton!
    
    @IBOutlet var facebookOptionButton: UIButton!
    @IBOutlet var googleOptionButton: UIButton!
    @IBOutlet var emailOptionButton: UIButton!
    @IBOutlet var loginOptionsBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet var passwordTextField: SkyFloatingLabelTextField!
    @IBOutlet var loginButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var appNameLabel: UILabel!
    @IBOutlet var logoImageTopConstraint: NSLayoutConstraint!
    @IBOutlet var appNameLabelTopConstraint: NSLayoutConstraint!
    
    // MARK: - Popover View Properties
    var errorPopoverView: popoverView!
    var shadowView: UIView!
    
    // MARK - Background Video Properties
    var player: AVPlayer?
    
    var authListener: FIRAuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
        
        // Configure video once
        configureBackgroundVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // TODO: Background Video
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        // Pause video as VC changes
        if player != nil {
            player?.pause()
        }

        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        setupAuthListener()
        
        // Try to play video as VC appears
        if player != nil {
            player?.play()
        }
        
        setupViews()
        
        
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingViewController.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
        logoImageView.alpha = 0
        appNameLabel.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showTitleView(show: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let authListener = authListener {
            FIRAuth.auth()?.removeStateDidChangeListener(authListener)
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func signUp() {
        presentOnboardingVC()
    }
    
    func presentOnboardingVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "onboardingNav") as! UINavigationController
        self.present(onboardingVC, animated: true, completion: nil)
    }
    
    // MARK: - Transitions
    func showMainView() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController: UITabBarController = storyboard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
        tabBarController.selectedIndex = 1
        
        DispatchQueue.main.async {
            self.present(tabBarController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Validation
    func validateFields() {
        if !(emailTextField.text?.isEmpty)! && !(passwordTextField.text?.isEmpty)! {
            enableSignup(enable: true)
        } else {
            enableSignup(enable: false)
        }
    }
    
    func editedEmailText() {
        validateFields()
    }
    
    func editedPasswordText() {
        validateFields()
    }
    
    func enableSignup(enable: Bool) {
        if emailModeStatus {
            signupButton.isEnabled = enable
            signupButton.alpha = enable ? 1 : 0.6
        }
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
            self.emailTextField.layoutIfNeeded()
            self.passwordTextField.layoutIfNeeded()
        })
        
        if show {
            self.loginButtonBottomConstraint.constant = changeInHeight + 12.5
        }
        else {
            self.loginButtonBottomConstraint.constant = 50
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
//                self.passwordVTFView.textField.becomeFirstResponder()
        })
    }
    
    // MARK: - Background Video
    func configureBackgroundVideo() {
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
    
    // MARK: - Signup & Login
    @IBAction func signupButtonPressed(_ sender: Any) {
        if emailModeStatus {
            // Try to login user via email
            loginWithEmail()
        } else {
            presentOnboardingVC()
        }
    }

    @IBAction func loginButtonPressed(_ sender: Any) {
        if emailModeStatus {
            emailMode()
        } else {
            loginMode()
        }
    }
    
    // MARK: - Setup views
    func setupViews() {
        UIApplication.shared.statusBarStyle = .lightContent
        
        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingViewController.googleSignInFailed), name: NSNotification.Name(rawValue: googleSignInFailedKey), object: nil)
        
        self.view.bringSubview(toFront: logoImageView)
        self.view.bringSubview(toFront: appNameLabel)
        
        setupSignupButton()
        setupLoginButton()
        
        setupFacebookOptionButton()
        setupGoogleOptionButton()
        setupEmailOptionButton()
        
        setupEmailTextField()
        setupPasswordTextField()
    }
    
    func setupSignupButton() {
        signupButton.layer.cornerRadius = 5
        signupButton.layer.shadowColor = UIColor.black.cgColor
        signupButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        signupButton.layer.shadowOpacity = 0.5
        signupButton.layer.shadowRadius = 1
        signupButton.layer.masksToBounds = false
        self.view.bringSubview(toFront: signupButton)
    }
    
    func setupLoginButton() {
        loginButton.layer.cornerRadius = 5
        loginButton.layer.shadowColor = UIColor.black.cgColor
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        loginButton.layer.shadowOpacity = 0.5
        loginButton.layer.shadowRadius = 1
        loginButton.layer.masksToBounds = false
        self.view.bringSubview(toFront: loginButton)
    }
    
    func setupFacebookOptionButton() {
        facebookOptionButton.isHidden = true
        facebookOptionButton.layer.cornerRadius = facebookOptionButton.frame.width/2
        
        let facebookIcon = NSMutableAttributedString(string: "\(String.fontAwesomeIcon(name: .facebook))", attributes: [NSFontAttributeName: UIFont.fontAwesome(ofSize: 18)])
        facebookOptionButton.setAttributedTitle(facebookIcon, for: .normal)
        facebookOptionButton.tintColor = UIColor(hex: "7189FF")
        facebookOptionButton.layer.cornerRadius = 5
        facebookOptionButton.layer.shadowColor = UIColor.black.cgColor
        facebookOptionButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        facebookOptionButton.layer.shadowOpacity = 0.5
        facebookOptionButton.layer.shadowRadius = 1
        facebookOptionButton.layer.masksToBounds = false
        self.view.bringSubview(toFront: facebookOptionButton)
    }
    
    func setupGoogleOptionButton() {
        googleOptionButton.isHidden = true
        googleOptionButton.layer.cornerRadius = googleOptionButton.frame.width/2
        
        let googleIcon = NSMutableAttributedString(string: "\(String.fontAwesomeIcon(name: .google))", attributes: [NSFontAttributeName: UIFont.fontAwesome(ofSize: 18)])
        googleOptionButton.setAttributedTitle(googleIcon, for: .normal)
        googleOptionButton.tintColor = UIColor(hex: "7189FF")
        googleOptionButton.layer.cornerRadius = 5
        googleOptionButton.layer.shadowColor = UIColor.black.cgColor
        googleOptionButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        googleOptionButton.layer.shadowOpacity = 0.5
        googleOptionButton.layer.shadowRadius = 1
        googleOptionButton.layer.masksToBounds = false
        self.view.bringSubview(toFront: googleOptionButton)
    }
    
    func setupEmailOptionButton() {
        emailOptionButton.isHidden = true
        emailOptionButton.layer.cornerRadius = emailOptionButton.frame.width/2
        
        let emailIcon = NSMutableAttributedString(string: "\(String.fontAwesomeIcon(name: .envelope))", attributes: [NSFontAttributeName: UIFont.fontAwesome(ofSize: 18)])
        emailOptionButton.setAttributedTitle(emailIcon, for: .normal)
        emailOptionButton.tintColor = UIColor(hex: "7189FF")
        emailOptionButton.layer.cornerRadius = 5
        emailOptionButton.layer.shadowColor = UIColor.black.cgColor
        emailOptionButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        emailOptionButton.layer.shadowOpacity = 0.5
        emailOptionButton.layer.shadowRadius = 1
        emailOptionButton.layer.masksToBounds = false
        self.view.bringSubview(toFront: emailOptionButton)
    }
    
    func setupEmailTextField() {
        emailTextField.font = UIFont(name: "OpenSans", size: 20)
        emailTextField.placeholder = "Email address"
        emailTextField.title = "Email"
        emailTextField.textColor = UIColor.white
        emailTextField.tintColor = UIColor(hex: "7d80da")
        emailTextField.lineColor = UIColor.lightGray

        emailTextField.selectedTitleColor = UIColor.white
        emailTextField.selectedLineColor = UIColor.white
        
        emailTextField.errorColor = UIColor(hex: "EF3054")
        emailTextField.delegate = self
        emailTextField.addTarget(self, action:#selector(OnboardingViewController.editedEmailText), for:UIControlEvents.editingChanged)
        
        emailTextField.returnKeyType = UIReturnKeyType.next
        emailTextField.keyboardType = UIKeyboardType.emailAddress
        emailTextField.autocorrectionType = UITextAutocorrectionType.no
        self.view.bringSubview(toFront: emailTextField)
    }
    
    func setupPasswordTextField() {
        passwordTextField.font = UIFont(name: "OpenSans", size: 20)
        passwordTextField.placeholder = "Password"
        passwordTextField.title = "Password"
        passwordTextField.textColor = UIColor.white
        passwordTextField.tintColor = UIColor(hex: "7d80da")
        passwordTextField.lineColor = UIColor.lightGray
        
        passwordTextField.selectedTitleColor = UIColor.white
        passwordTextField.selectedLineColor = UIColor.white
        
        passwordTextField.delegate = self
        passwordTextField.addTarget(self, action:#selector(OnboardingViewController.editedPasswordText), for:UIControlEvents.editingChanged)
        
        passwordTextField.returnKeyType = UIReturnKeyType.done
        passwordTextField.autocorrectionType = UITextAutocorrectionType.no
        self.view.bringSubview(toFront: passwordTextField)
    }
    
    func setupAuthListener() {
        authListener = FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if user != nil {
                print("OnboardingVC: User signed in")
                    
                HUD.flash(.success, delay: 0, completion: { (success) in
                    // Present next VC
                    self.showMainView()
                })
            } else {
                print("OnboardingVC: No user signed in")
            }
        })
    }
    
    func setupNavBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        let tag = textField.tag
        switch tag {
        case 0:
            if !emailTextField.text!.isEmpty {
                self.passwordTextField.becomeFirstResponder()
            }
        case 1:
            // Try to login user via email
            if signupButton.isEnabled {
              loginWithEmail()
            }
        default:
            break
        }
        return true
    }
    
    // MARK: - Animations
    func loginMode() {
        if !isAnimating {
            self.isAnimating = true
            
            if !loginModeStatus {
                loginModeStatus = true
                
                // Show options
                showLoginOptions(show: true)
                
                // Change log in button to cancel
                changeLoginButton(mode: "Cancel")

                // Hide sign up button
                UIView.animate(withDuration: 0.2, animations: {
                    self.signupButton.alpha = 0
                }, completion: { (complete) in
                    self.signupButton.isHidden = true
                    self.isAnimating = false
                })
            } else {
                loginModeStatus = false
                
                // Hide options
                showLoginOptions(show: false)
                
                // Change log in button to log in
                changeLoginButton(mode: "Log in")
                
                // Show sign up button
                signupButton.isHidden = false
                UIView.animate(withDuration: 0.2, animations: {
                    self.signupButton.alpha = 1
                }, completion: { (complete) in
                    self.isAnimating = false
                })
            }
        }
    }
    
    func emailMode() {
        if !isAnimating {
            
            if !emailModeStatus {
                self.isAnimating = true
                emailModeStatus = true
                
                // Hide logo and title
                showTitleView(show: false)
                
                // Hide option buttons
                showOptionButtons(show: false)
                
                // Change sign up button
                changeSignupButton(mode: "Login")
                
                // Show email fields
                showEmailFields(show: true)
                
                // Show sign up button
                signupButton.isHidden = false
                UIView.animate(withDuration: 0.2, animations: {
                    self.signupButton.alpha = 0.7
                }, completion: { (complete) in
                    self.isAnimating = false
                    self.signupButton.isEnabled = false
                })
            } else {
                emailModeStatus = false
                loginModeStatus = false
                
                // Show logo and title
                showTitleView(show: true)
                
                // Change sign up button
                changeSignupButton(mode: "Sign up")
                self.signupButton.isEnabled = true
                self.signupButton.alpha = 1
                
                // Hide email fields
                showEmailFields(show: false)
                
                // Change login button
                changeLoginButton(mode: "Log in")
            }
        }
    }
    
    // MARK: Helper functions
    func showOptionButtons(show: Bool) {
        facebookOptionButton.isHidden = !show
        googleOptionButton.isHidden = !show
        emailOptionButton.isHidden = !show
    }
    
    func showLoginOptions(show: Bool) {
        if show {
            showOptionButtons(show: true)
            
            self.loginOptionsBottomConstraint.constant = 20
            self.view.layoutIfNeeded()
            self.loginOptionsBottomConstraint.constant = 40
            
            UIView.animate(withDuration: 0.2, animations: {
                self.changeOptionButtonsAlpha(alpha: 1)
                self.view.layoutIfNeeded()
            }, completion: { (complete) in
            })
        } else {
            self.loginOptionsBottomConstraint.constant = 20
            
            UIView.animate(withDuration: 0.2, animations: {
                self.changeOptionButtonsAlpha(alpha: 0)
                self.view.layoutIfNeeded()
            }, completion: { (complete) in
                self.showOptionButtons(show: false)
            })
        }
    }
    
    func changeOptionButtonsAlpha(alpha: CGFloat) {
        facebookOptionButton.alpha = alpha
        googleOptionButton.alpha = alpha
        emailOptionButton.alpha = alpha
    }
    
    func showEmailFields(show: Bool) {
        if show {
            self.emailTextField.isHidden = false
            self.emailTextField.alpha = 0
            self.passwordTextField.isHidden = false
            self.passwordTextField.alpha = 0
            
            UIView.animate(withDuration: 0.2, animations: {
                self.emailTextField.alpha = 1
                self.passwordTextField.alpha = 1
                
            }, completion: { (complete) in
                self.emailModeStatus = true
            })
            
        } else {
            self.view.endEditing(true)
            UIView.animate(withDuration: 0.2, animations: {
                self.emailTextField.alpha = 0
                self.passwordTextField.alpha = 0
                
            }, completion: { (complete) in
                self.emailTextField.isHidden = true
                self.passwordTextField.isHidden = true
                
                // Clear text fields
                self.emailTextField.text = ""
                self.passwordTextField.text = ""
                
                self.emailModeStatus = false
            })
        }
    }
    
    func showTitleView(show: Bool) {
        if show {
            self.logoImageTopConstraint.constant = 50
            self.appNameLabelTopConstraint.constant = 8
            self.view.layoutIfNeeded()
            self.logoImageTopConstraint.constant = 75
            self.appNameLabelTopConstraint.constant = 16
            
            UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.logoImageView.alpha = 0.9
                self.view.layoutIfNeeded()
            }) { (completed) in
            }
            UIView.animate(withDuration: 0.2, delay: 0.1, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.appNameLabel.alpha = 1
            }) { (completed) in
            }
        } else {
            self.logoImageTopConstraint.constant = 50
            self.appNameLabelTopConstraint.constant = 8
            
            UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.appNameLabel.alpha = 0
            }) { (completed) in
            }
            UIView.animate(withDuration: 0.2, delay: 0.1, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.logoImageView.alpha = 0
                self.view.layoutIfNeeded()
            }) { (completed) in
            }
        }
    }
    
    func changeLoginButton(mode: String) {
        let title = (mode == "Log in") ? "Log in" : "Cancel"
        let titleColor = (mode == "Log in") ? UIColor(hex: "7189FF") : UIColor.white
        let backgroundColor = (mode == "Log in") ? UIColor.white : UIColor(hex: "FF6978")
        
        UIView.performWithoutAnimation {
            self.loginButton.setTitle(title, for: .normal)
            self.loginButton.layoutIfNeeded()
        }
        loginButton.setTitleColor(titleColor, for: .normal)
        loginButton.backgroundColor = backgroundColor
    }
    
    func changeSignupButton(mode: String) {
        let title = (mode == "Sign up") ? "Sign up" : "Login"
        
        UIView.performWithoutAnimation {
            self.signupButton.setTitle(title, for: .normal)
            self.signupButton.layoutIfNeeded()
        }
    }
    
    // MARK: - Login Options
    @IBAction func facebookOptionButtonPressed(_ sender: UIButton) {
        HUD.show(.progress)
        
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if let error = error {
                HUD.hide()
                print("Error signing in with Facebook: ", error.localizedDescription)
            } else {
                print("Signed in with Facebook")
            }
        })
    }
    
    @IBAction func googleOptionButtonPressed(_ sender: UIButton) {
        HUD.show(.progress)
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func emailOptionButtonPressed(_ sender: UIButton) {
        emailMode()
    }
    
    func loginWithEmail() {
        HUD.show(.progress)
        if let email = emailTextField.text, let password = passwordTextField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                if let error = error {
                    print("Error signing in with Email: ", error.localizedDescription)
                    HUD.hide()
                    self.showErrorMessage(error: error)

                } else {
                    print("Signed in with Email")
                }
            })
        }
    }
    
    // MARK: - Handle errors
    func showErrorMessage(error: Error) {
        let errorCode = FIRAuthErrorCode(rawValue: error._code)!
        var errorMessage = ""
        
        switch errorCode {
        case .errorCodeInvalidEmail:
            errorMessage = "Email address is invalid"
        case .errorCodeNetworkError:
            errorMessage = "Network error. Please try again."
        case .errorCodeUserNotFound:
            errorMessage = "No account found"
        case .errorCodeWrongPassword:
            errorMessage = "Incorrect password"
        default:
            break
        }
        
        if !errorMessage.isEmpty {
            let alert = UIAlertController(title: "Something went wrong", message: errorMessage, preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alert.addAction(okayAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func googleSignInFailed() {
        HUD.hide()
    }
}
