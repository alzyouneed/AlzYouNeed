//
//  FamilyVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/19/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit

class FamilyVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupView() {
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    

}
