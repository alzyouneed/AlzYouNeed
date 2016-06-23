//
//  NewUserViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class NewUserViewController: UIViewController {
    
    // MARK: - UI Elements
    
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var nameValidateTextFieldView: validateTextFieldView!
    @IBOutlet var phoneNumberValidateTextFieldView: validateTextFieldView!
    @IBOutlet var emailValidateTextFieldView: validateTextFieldView!
    @IBOutlet var passwordValidateTextFieldView: validateTextFieldView!
    @IBOutlet var confirmPasswordValidateTextField: validateTextFieldView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
