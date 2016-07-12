//
//  UserDashboardView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/16/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

@IBDesignable class UserDashboardView: UIView {

    // MARK: - Properties
    
    var view: UIView!
    
    @IBOutlet var userImageView: UIImageView!
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
        
        leftButton.layer.cornerRadius = leftButton.frame.size.width * 0.1
        rightButton.layer.cornerRadius = rightButton.frame.size.width * 0.1
        
        self.userImageView.layer.masksToBounds = true
        self.userImageView.layer.cornerRadius = self.userImageView.frame.height/2
        self.userImageView.clipsToBounds = true
        self.userImageView.layer.borderWidth = 2
        self.userImageView.layer.borderColor = UIColor.whiteColor().CGColor
        self.userImageView.alpha = 0
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "UserDashboardView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    func setImage(image: UIImage) {
        dispatch_async(dispatch_get_main_queue()) {
            self.userImageView.image = image
            UIView.animateWithDuration(0.25, animations: {
                self.userImageView.alpha = 1
            })
        }
    }
    

}
