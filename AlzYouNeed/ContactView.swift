//
//  ContactView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

@IBDesignable class ContactView: UIView {

    var view: UIView!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var contactImageView: UIImageView!
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var rightButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        
        addSubview(view)
        
        contactImageView.layer.cornerRadius = contactImageView.frame.size.width / 2
        contactImageView.layer.masksToBounds = false
        contactImageView.clipsToBounds = true
        
        leftButton.layer.cornerRadius = leftButton.frame.size.width / 2
        rightButton.layer.cornerRadius = rightButton.frame.size.width / 2
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "ContactView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    func setImageWithPath(path: String) {
        let image = loadImageFromPath(path)
        if image != nil {
            print("Successfully set contactImageView")
            contactImageView.image = image
        }
    }
    
    func loadImageFromPath(path: String) -> UIImage? {
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
//        let docsDir = dirPaths[0] as String
        let docsDir = "\(dirPaths[0] as String)/"
        
        print("New docs directory path: \(docsDir)")
        
        let completePath = "\(docsDir)\(path)"
        print("Complete path: \(completePath)")
        
        let image = UIImage(contentsOfFile: completePath)
        
        if image == nil {
            print("missing image at: \(path)")
        }
        else {
            print("loading image from path: \(path)")
        }
        return image
    }

}
