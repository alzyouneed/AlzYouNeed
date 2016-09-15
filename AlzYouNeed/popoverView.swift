//
//  popoverView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/8/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

@IBDesignable class popoverView: UIView {

    // MARK: - Properties
    var view: UIView!
    var viewHidden = true
    
    // MARK: - UI Elements
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var confirmButton: UIButton!
    
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
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "popoverView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    // MARK: - Error Handling
    func configureWithError(_ error: NSError) {
        messageLabel.text = makeErrorReadable(error) ?? "Something went wrong"
    }
    
    func makeErrorReadable(_ error: NSError) -> String? {
        let code = error.code
        switch code {
        case 17007:
            // Email already in use
            return "That email is already being used"
        case 17009:
            // Invalid password
            return "That password didn't work"
        case 17010:
            // Try again later
            return "There were too many attempts. Please try again later"
        case 17011:
            // No matching user
            return "There is no account using that email"
        case 00001:
            // Family already exists
            return "A family with this name already exists"
        case 00003:
            // Incorrect family password
            return "That password didn't work"
        case 00004:
            // Family group does not exist
            return "A family with this name does not exist"
        default:
            return nil
        }
    }

}
