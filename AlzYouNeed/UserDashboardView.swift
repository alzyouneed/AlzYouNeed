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
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        addSubview(view)
        
        self.userImageView.layer.masksToBounds = false
        self.userImageView.layer.cornerRadius = self.userImageView.frame.height/2
        self.userImageView.clipsToBounds = true
        self.userImageView.layer.borderWidth = 2
        self.userImageView.layer.borderColor = UIColor.white.cgColor
        self.userImageView.alpha = 0
        
        self.userImageView.layer.shadowColor = UIColor.black.cgColor
        self.userImageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.userImageView.layer.shadowOpacity = 0.2
        self.userImageView.layer.shadowRadius = 1
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "UserDashboardView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    func setImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.userImageView.image = image
            UIView.animate(withDuration: 0.25, animations: {
                self.userImageView.alpha = 1
            })
        }
    }
    
    func specialUser(_ type: String) {
        switch type {
        case "admin":
            self.adminImageView.image = UIImage(named: "adminIcon")
            self.adminImageView.isHidden = false
        case "patient":
            self.adminImageView.image = UIImage(named: "patientIcon")
            self.adminImageView.isHidden = false
        case "none":
            self.adminImageView.image = UIImage()
            self.adminImageView.isHidden = true
        default:
            break
        }
    }
}
