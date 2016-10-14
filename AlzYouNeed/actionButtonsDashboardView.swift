//
//  actionButtonsDashboardView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/18/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

@IBDesignable class actionButtonsDashboardView: UIView {
    // MARK: - Properties
    
    var view: UIView!
    
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var rightButton: UIButton!
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
        
        leftButton.layer.cornerRadius = 10
        rightButton.layer.cornerRadius = 10
        
        leftButton.backgroundColor = caribbeanGreen
        leftButton.setTitle("Notepad", for: .normal)
        
        rightButton.backgroundColor = sunsetOrange
        rightButton.setTitle("Emergency", for: .normal)
    }
    
    // TODO: Update later to add functionality
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
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "actionButtonsDashboardView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    // Adjust button size on touch
    @IBAction func buttonTouchEnded(_ sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 1, y: 1)
    }
    
    @IBAction func buttonTouchStarted(_ sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
    }

}
