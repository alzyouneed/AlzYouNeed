//
//  NotepadViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 10/3/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class NotepadViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.barTintColor = UIColor(red: 136/255, green: 132/255, blue: 255/255, alpha: 1)
//        
//        FirebaseManager.saveFamilyNote(_changes: "Testing") { (error) in
//            
//        }
//        
//        FirebaseManager.getFamilyNote { (error, familyNote) in
//            print("Note:", familyNote)
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeNotepad(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveNote() {
        // Pull most current version of note (to avoid losing any changes from someone else)
        
        // Save changes
    }

}
