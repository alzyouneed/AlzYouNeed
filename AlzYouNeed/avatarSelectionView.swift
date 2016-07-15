//
//  avatarSelectionView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/27/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

@IBDesignable class avatarSelectionView: UIView {

    // MARK: - UI Elements
    
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    
    // MARK: - Properties
    var view: UIView!
    
    let avatarImages = [UIImage(named: "avatarOne"), UIImage(named: "avatarTwo"), UIImage(named: "avatarThree"), UIImage(named: "avatarFour"), UIImage(named: "avatarFive")]
    var avatarImageIndex = 0
    
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
        
        self.userImageView.image = avatarImages[avatarImageIndex]
        self.userImageView.layer.masksToBounds = true
        self.userImageView.layer.cornerRadius = self.userImageView.frame.height/2
        self.userImageView.clipsToBounds = true
        self.userImageView.layer.borderWidth = 2
        self.userImageView.layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "avatarSelectionView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    @IBAction func selectImage(sender: UIButton) {
        // Previous button
        if sender.tag == 0 {
            if self.avatarImageIndex > 0 {
                self.avatarImageIndex -= 1
            }
            else {
                self.avatarImageIndex = 4
            }
            
            self.userImageView.image = self.avatarImages[self.avatarImageIndex]
        }
        // Next button
        else {
            if self.avatarImageIndex < 4 {
                self.avatarImageIndex += 1
            }
            else {
                self.avatarImageIndex = 0
            }
            
            self.userImageView.image = self.avatarImages[self.avatarImageIndex]
        }
    }
    
    func avatarId() -> String {
        switch avatarImageIndex {
        case 0:
            return "avatarOne"
        case 1:
            return "avatarTwo"
        case 2:
            return "avatarThree"
        case 3:
            return "avatarFour"
        case 4:
            return "avatarFive"
        default:
            return "avatarOne"
        }
    }
    
    func avatarIndex(image: String) -> Int {
        switch image {
        case "avatarOne":
            return 0
        case "avatarTwo":
            return 1
        case "avatarThree":
            return 2
        case "avatarFour":
            return 3
        case "avatarFive":
            return 4
        default:
            return 0
        }
    }
    
    // Adjust button size on touch
    @IBAction func buttonTouchEnded(sender: UIButton) {
        sender.transform = CGAffineTransformMakeScale(1, 1)
    }
    
    @IBAction func buttonTouchStarted(sender: UIButton) {
        sender.transform = CGAffineTransformMakeScale(0.9, 0.9)
    }
    
}
