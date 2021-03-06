//
//  ContactView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import FontAwesome_swift

@IBDesignable class ContactView: UIView {

    // MARK: - Properties
    
    var view: UIView!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var contactImageView: UIImageView!
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var rightButton: UIButton!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var adminImageView: UIImageView!
    @IBOutlet var stackView: UIStackView!
    
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
        
        contactImageView.layer.cornerRadius = contactImageView.frame.size.width / 2
        contactImageView.layer.masksToBounds = false
        contactImageView.clipsToBounds = true
        contactImageView.layer.borderWidth = 2
        contactImageView.layer.borderColor = UIColor.white.cgColor
//        contactImageView.layer.borderColor = stormCloud.CGColor
        
        leftButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 25)
        leftButton.setTitle(String.fontAwesomeIcon(name: .phone), for: .normal)
        leftButton.layer.cornerRadius = leftButton.frame.size.width / 2
        leftButton.layer.masksToBounds = false
        leftButton.clipsToBounds = true
        leftButton.layer.borderWidth = 2
        leftButton.layer.borderColor = UIColor.white.cgColor
        
        rightButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 25)
        rightButton.setTitle(String.fontAwesomeIcon(name: .comment), for: .normal)
        rightButton.layer.cornerRadius = rightButton.frame.size.width / 2
        rightButton.layer.masksToBounds = false
        rightButton.clipsToBounds = true
        rightButton.layer.borderWidth = 2
        rightButton.layer.borderColor = UIColor.white.cgColor
        
        backgroundView.clipsToBounds = true
        backgroundView.layer.cornerRadius = 5
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "ContactView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    // Adjust button size on touch
    @IBAction func buttonTouchEnded(_ sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 1, y: 1)
    }
    
    @IBAction func buttonTouchStarted(_ sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
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

    func singleButton(_ button: String) {
        if button == "left" {
            stackView.removeArrangedSubview(rightButton)
            rightButton.isHidden = true
        }
        else {
            stackView.removeArrangedSubview(leftButton)
            leftButton.isHidden = true
        }
    }
    
    /*
    func setImageWithPath(path: String) {
        let image = loadImageFromPath(path)
        if path != "" && image != nil {
//            print("Successfully set contactImageView \n")
            contactImageView.image = image
        }
    }
    
    func loadImageFromPath(path: String) -> UIImage? {
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir = "\(dirPaths[0] as String)/" // Document directory
        
//        print("New docs directory path: \(docsDir)")
        
        let completePath = "\(docsDir)\(path)"
//        print("Complete path: \(completePath)")
        
        let image = UIImage(contentsOfFile: completePath)
        
        if image == nil {
            print("missing image at: \(path)")
        }
        else {
//            print("loading image from path: \(path)")
        }
        return image
    }
    */

}
