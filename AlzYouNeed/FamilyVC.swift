//
//  FamilyVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/19/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit

class FamilyVC: UIViewController {
    
    @IBOutlet var createFamilyButton: UIButton!
    @IBOutlet var joinFamilyButton: UIButton!
    @IBOutlet var fieldsView: UIView!
    @IBOutlet var familyControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupView() {
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        setupCreateFamilyButton()
        setupJoinFamilyButton()
    }
    
    func setupCreateFamilyButton() {
        let buttonText = String.fontAwesomeIcon(name: .plus) + "  Create Family"
        createFamilyButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 18)
        createFamilyButton.setTitle(buttonText, for: .normal)
        createFamilyButton.layer.cornerRadius = 5
        createFamilyButton.layer.shadowColor = UIColor.black.cgColor
        createFamilyButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        createFamilyButton.layer.shadowOpacity = 0.5
        createFamilyButton.layer.shadowRadius = 1
        createFamilyButton.layer.masksToBounds = false
    }
    
    func setupJoinFamilyButton() {
        let buttonText = String.fontAwesomeIcon(name: .group) + "  Join Family"
        joinFamilyButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 18)
        joinFamilyButton.setTitle(buttonText, for: .normal)
        joinFamilyButton.layer.cornerRadius = 5
        joinFamilyButton.layer.shadowColor = UIColor.black.cgColor
        joinFamilyButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        joinFamilyButton.layer.shadowOpacity = 0.5
        joinFamilyButton.layer.shadowRadius = 1
        joinFamilyButton.layer.masksToBounds = false
    }
    
    @IBAction func familyOptionChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            sender.tintColor = UIColor(hex: "16D0C5")
        } else {
            sender.tintColor = UIColor(hex: "7189FF")
        }
    }

}
