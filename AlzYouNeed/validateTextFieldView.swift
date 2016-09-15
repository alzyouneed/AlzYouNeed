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
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        addSubview(view)
        
        textField.delegate = self
//        textField.textColor = UIColor.whiteColor()
        textField.textColor = stormCloud
        imageView.isHidden = true
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "validateTextFieldView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    // MARK: - Configure View
    
    func emailMode() {
        textField.placeholder = "Email"
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.spellCheckingType = UITextSpellCheckingType.no
        textField.keyboardType = UIKeyboardType.emailAddress
        textField.returnKeyType = UIReturnKeyType.next
        textField.isSecureTextEntry = false
    }
    
    func passwordMode(_ confirmPassword: Bool) {
        textField.placeholder = "Password"
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.spellCheckingType = UITextSpellCheckingType.no
        textField.keyboardType = UIKeyboardType.asciiCapable
        textField.returnKeyType = UIReturnKeyType.next
        textField.isSecureTextEntry = true
        
        if confirmPassword {
            textField.placeholder = "Confirm password"
            textField.returnKeyType = UIReturnKeyType.done
        }
    }
    
    func familyIdMode() {
        textField.placeholder = "Family ID"
        textField.autocapitalizationType = UITextAutocapitalizationType.words
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.spellCheckingType = UITextSpellCheckingType.no
        textField.keyboardType = UIKeyboardType.asciiCapable
        textField.returnKeyType = UIReturnKeyType.next
        textField.isSecureTextEntry = false
    }
    
    func phoneNumberMode() {
        textField.placeholder = "Phone Number"
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.spellCheckingType = UITextSpellCheckingType.no
        textField.keyboardType = UIKeyboardType.numberPad
        textField.returnKeyType = UIReturnKeyType.next
        textField.isSecureTextEntry = false
    }
    
    func nameMode() {
        textField.placeholder = "Full Name"
        textField.autocapitalizationType = UITextAutocapitalizationType.words
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.spellCheckingType = UITextSpellCheckingType.no
        textField.keyboardType = UIKeyboardType.asciiCapable
        textField.returnKeyType = UIReturnKeyType.next
        textField.isSecureTextEntry = false
    }
    
    func isValid(_ valid: Bool) {
        imageView.image = UIImage(named: "validEntry")
        
        switch valid {
        case true:
            if imageView.isHidden {
                imageView.isHidden = false
                imageView.alpha = 0
                
                UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                    self.imageView.alpha = 1
                    }, completion: { (completed) in
                })
            }
        case false:
            UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                self.imageView.alpha = 0
                }, completion: { (completed) in
                    self.imageView.isHidden = true
            })
        }
    }

}
