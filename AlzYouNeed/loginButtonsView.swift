//
//  loginButtonsView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/5/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

@IBDesignable class loginButtonsView: UIView {

    // MARK: - Properties
    var view: UIView!
    var state = "normal"
    
    var leftButtonColor = UIColor(red: 194/255, green: 187/255, blue: 240/255, alpha: 1)
    var rightButtonColor = UIColor(red: 139/255, green: 149/255, blue: 201/255, alpha: 1)
    var redColor = UIColor(red: 239/255, green: 121/255, blue: 138/255, alpha: 1)
    
    // MARK: - UI Elements
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var rightButton: UIButton!
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    // MARK: - Setup
    
    func xibSetup() {
        view = loadViewFromNib()
        
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "loginButtonsView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    // MARK: - Configure View
    
    
    // MARK: - Actions
    @IBAction func leftButtonClicked(sender: UIButton) {
        switch state {
        case "normal":
            normalState()
        case "login":
            loginState()
        default:
            break
        }
    }
    @IBAction func rightButtonClicked(sender: UIButton) {
        switch state {
        case "normal":
            loginState()
        case "signup":
//            print("Cancelling sign up")
            state = "normal"
            normalState()
        case "login":
//            print("Cancelling login")
            state = "normal"
            normalState()
        default:
            break
        }
    }
    
    private func loginState() {
        if state != "login" {
            state = "login"
            leftButton.setTitle("Login", forState: UIControlState.Normal)
            leftButton.backgroundColor = leftButtonColor
            
            rightButton.setTitle("Cancel", forState: UIControlState.Normal)
            rightButton.backgroundColor = redColor
        }
        else {
//            print("Logging in")
        }
    }
    
    private func normalState() {
        leftButton.setTitle("Sign up", forState: UIControlState.Normal)
        leftButton.backgroundColor = leftButtonColor
        
        rightButton.setTitle("Login", forState: UIControlState.Normal)
        rightButton.backgroundColor = rightButtonColor
    }
    
    func resetState() {
        state = "normal"
        normalState()
    }

}
