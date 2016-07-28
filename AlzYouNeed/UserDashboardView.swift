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
    
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var familyGroupLabel: UILabel!
    @IBOutlet var separatorView: UIView!
    @IBOutlet var adminImageView: UIImageView!
    
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
        
        self.userImageView.layer.masksToBounds = true
        self.userImageView.layer.cornerRadius = self.userImageView.frame.height/2
        self.userImageView.clipsToBounds = true
        self.userImageView.layer.borderWidth = 2
        self.userImageView.layer.borderColor = ivory.CGColor
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
    
    func isAdmin(admin: Bool) {
        if admin {
            self.adminImageView.hidden = false
        }
        else {
            self.adminImageView.hidden = true
        }
    }
    
    /*
    MARK: - TODO
    func configureView() {
        
    }
    */
    

}
