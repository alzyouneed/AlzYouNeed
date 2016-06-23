//
//  validateTextFieldView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/20/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

@IBDesignable class validateTextFieldView: UIView, UITextFieldDelegate {

    // MARK: - Properties
    
    var view: UIView!
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var imageView: UIImageView!
    
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
        
        textField.delegate = self
//        textField.textColor = UIColor.whiteColor()
        textField.textColor = UIColor.blackColor()
        imageView.hidden = true
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "validateTextFieldView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    // MARK: - Configure View
    
    func emailMode() {
        textField.placeholder = "Email"
        textField.autocapitalizationType = UITextAutocapitalizationType.None
        textField.autocorrectionType = UITextAutocorrectionType.No
        textField.spellCheckingType = UITextSpellCheckingType.No
        textField.keyboardType = UIKeyboardType.EmailAddress
        textField.returnKeyType = UIReturnKeyType.Next
        textField.secureTextEntry = false
    }
    
    func passwordMode(confirmPassword: Bool) {
        textField.placeholder = "Password"
        textField.autocapitalizationType = UITextAutocapitalizationType.None
        textField.autocorrectionType = UITextAutocorrectionType.No
        textField.spellCheckingType = UITextSpellCheckingType.No
        textField.keyboardType = UIKeyboardType.Default
        textField.returnKeyType = UIReturnKeyType.Next
        textField.secureTextEntry = true
        
        if confirmPassword {
            textField.placeholder = "Confirm password"
            textField.returnKeyType = UIReturnKeyType.Done
        }
    }
    
    func familyIdMode() {
        textField.placeholder = "Family ID"
        textField.autocapitalizationType = UITextAutocapitalizationType.None
        textField.autocorrectionType = UITextAutocorrectionType.No
        textField.spellCheckingType = UITextSpellCheckingType.No
        textField.keyboardType = UIKeyboardType.Default
        textField.returnKeyType = UIReturnKeyType.Next
        textField.secureTextEntry = false
    }
    
    func phoneNumberMode() {
        textField.placeholder = "Phone Number"
        textField.autocapitalizationType = UITextAutocapitalizationType.None
        textField.autocorrectionType = UITextAutocorrectionType.No
        textField.spellCheckingType = UITextSpellCheckingType.No
        textField.keyboardType = UIKeyboardType.PhonePad
        textField.returnKeyType = UIReturnKeyType.Next
        textField.secureTextEntry = false
    }
    
    func nameMode() {
        textField.placeholder = "Full Name"
        textField.autocapitalizationType = UITextAutocapitalizationType.Words
        textField.autocorrectionType = UITextAutocorrectionType.No
        textField.spellCheckingType = UITextSpellCheckingType.No
        textField.keyboardType = UIKeyboardType.Default
        textField.returnKeyType = UIReturnKeyType.Next
        textField.secureTextEntry = false
    }
    
    func isValid(valid: Bool) {
        imageView.image = UIImage(named: "validEntry")
        
        switch valid {
        case true:
            if imageView.hidden {
                imageView.hidden = false
                imageView.alpha = 0
                
                UIView.animateWithDuration(0.25, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    self.imageView.alpha = 1
                    }, completion: { (completed) in
                })
            }
        case false:
            UIView.animateWithDuration(0.25, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.imageView.alpha = 0
                }, completion: { (completed) in
                    self.imageView.hidden = true
            })
        }
    }

}
