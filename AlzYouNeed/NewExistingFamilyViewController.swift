//
//  NewExistingFamilyViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class NewExistingFamilyViewController: UIViewController {
    
    @IBOutlet var newFamilyButton: UIButton!
    @IBOutlet var existingFamilyButton: UIButton!
    
    @IBOutlet var progressView: UIProgressView!
    
    @IBOutlet var cancelButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.5, animations: {
            self.progressView.setProgress(0.75, animated: true)
        }) 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func configureView() {
        self.navigationItem.hidesBackButton = true
    }
    
    @IBAction func cancelOnboarding(_ sender: UIBarButtonItem) {
        cancelAccountCreation()
    }
    
    // MARK: - Firebase
    func cancelAccountCreation() {
        
        let alertController = UIAlertController(title: "Cancel Signup", message: "All progress will be lost", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { (action) in
            self.deleteUser()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func deleteUser() {
        FirebaseManager.deleteCurrentUser { (error) in
            if error != nil {
                // Error deleting user
            }
            else {
                // Successfully deleted user
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "onboardingNav") as! UINavigationController
                self.present(onboardingVC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let destinationVC = segue.destination as? FamilySignupViewController {
            // New family
           // if (sender as AnyObject).tag == 0 {
            if (sender as AnyObject?)?.tag == 0 {
               // if let senderObject = sender as? AnyObject {
                   // if senderObject.tag == 0 {
                        destinationVC.newFamily = true
                    //}
               // }
               // destinationVC.newFamily = true
                
            }
            // Existing family
            else {
                destinationVC.newFamily = false
            }
        }
        
    }
 

}
