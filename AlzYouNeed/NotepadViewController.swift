//
//  NotepadViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 10/3/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class NotepadViewController: UIViewController {

    @IBOutlet var noteTextView: UITextView!
    var originalNote = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.barTintColor = UIColor(red: 136/255, green: 132/255, blue: 255/255, alpha: 1)
        
        loadNote()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeNotepad(_ sender: UIBarButtonItem) {
        if noteTextView.text != originalNote {
            // Unsaved changes - warn user
            showChangesWarning()
        } else {
            // No changes - dismiss
            self.view.endEditing(true)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func saveNote(_dismissAfter: Bool) {
        if !noteTextView.text.isEmpty {
            FirebaseManager.saveFamilyNote(_changes: noteTextView.text) { (error) in
                if error != nil {
                    // Didn't save note
                } else {
                    // Saved note
                    if _dismissAfter {
                        self.view.endEditing(true)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func loadNote() {
        FirebaseManager.getFamilyNote { (error, familyNote) in
            if let familyNote = familyNote {
                self.noteTextView.text = familyNote
                self.originalNote = familyNote
                
                // Saved to UserDefaults to notify user to changes
                UserDefaultsManager.saveCurrentUserNotepad(_note: familyNote)
            }
        }
    }
    
    @IBAction func saveNoteAction(_ sender: UIBarButtonItem) {
        saveNote(_dismissAfter: false)
    }
    
    func showChangesWarning() {
        let alertController = UIAlertController(title: "Unsaved Changes", message: "All changes will be lost unless you save them", preferredStyle: .actionSheet)
        
        let closeAction = UIAlertAction(title: "Close without saving", style: .destructive) { (action) in
            self.view.endEditing(true)
            self.dismiss(animated: true, completion: nil)
        }
        let saveAction = UIAlertAction(title: "Save changes", style: .default) { (action) in
            self.saveNote(_dismissAfter: true)
        }

        alertController.addAction(closeAction)
        alertController.addAction(saveAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
