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
    @IBOutlet var dateLabel: UILabel!
    
    
    // MARK: - Constraints
    // To switch layout based on user type
    
    // Recipient
    @IBOutlet var profileImageLeadingConstraintRecipient: NSLayoutConstraint!
    @IBOutlet var chatBubbleLeadingConstraintRecipient: NSLayoutConstraint!
    @IBOutlet var chatBubbleTrailingConstraintRecipient: NSLayoutConstraint!
    @IBOutlet var nameLabelLeadingConstraintRecipient: NSLayoutConstraint!
    @IBOutlet var messageLabelLeadingConstraintRecipient: NSLayoutConstraint!
    @IBOutlet var dateLabelLeadingConstraintRecipient: NSLayoutConstraint!
    @IBOutlet var dateLabelTrailingConstraintRecipient: NSLayoutConstraint!
    
    // Current user (sender)
    @IBOutlet var profileImageTrailingConstraintSender: NSLayoutConstraint!
    @IBOutlet var chatBubbleLeadingConstraintSender: NSLayoutConstraint!
    @IBOutlet var chatBubbleTrailingConstraintSender: NSLayoutConstraint!
    
    
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
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = stormCloud.CGColor

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
            messageLabel.textColor = UIColor.whiteColor()
//            configureConstraints(true)
            case "receiver":
            chatBubbleView.backgroundColor = columbiaBlue
            messageLabel.textColor = UIColor.blackColor()
//            configureConstraints(false)
        default:
            break
        }
    }
    
    func configureConstraints(currentUser: Bool) {
        // Configure recipient constraints
        profileImageLeadingConstraintRecipient.active = !currentUser
        chatBubbleLeadingConstraintRecipient.active = !currentUser
        chatBubbleTrailingConstraintRecipient.active = !currentUser
        nameLabelLeadingConstraintRecipient.active = !currentUser
        messageLabelLeadingConstraintRecipient.active = !currentUser
        dateLabelLeadingConstraintRecipient.active = !currentUser
        dateLabelTrailingConstraintRecipient.active = !currentUser
        
        // Configure sender (current user) constraints
        profileImageTrailingConstraintSender.active = currentUser
        profileImageTrailingConstraintSender.constant = profileImageLeadingConstraintRecipient.constant
        
        chatBubbleLeadingConstraintSender.active = currentUser
        chatBubbleLeadingConstraintSender.constant = chatBubbleTrailingConstraintRecipient.constant
        
        chatBubbleTrailingConstraintSender.active = currentUser
        chatBubbleTrailingConstraintSender.constant = -chatBubbleLeadingConstraintRecipient.constant
        
        
        
        nameLabel.hidden = currentUser
        dateLabel.hidden = currentUser
    }

}
