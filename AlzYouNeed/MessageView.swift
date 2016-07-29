//
//  MessageView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/29/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

@IBDesignable class MessageView: UIView {

    // MARK: - Properties
    var view: UIView!
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var chatBubbleView: UIView!
    @IBOutlet var messageLabel: UILabel!
    
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
        
        chatBubbleView.layer.cornerRadius = 10
        profileImageView.layer.cornerRadius = profileImageView.frame.height/2
        profileImageView.layer.masksToBounds = true
        profileImageView.clipsToBounds = true
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "MessageView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    func userType(type: String) {
        switch type {
            case "sender":
            chatBubbleView.backgroundColor = caribbeanGreen
            case "receiver":
            chatBubbleView.backgroundColor = UIColor.lightGrayColor()
        default:
            break
        }
    }

}
