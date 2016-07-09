//
//  RemindersViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/9/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class RemindersViewController: UIViewController, UITableViewDelegate {

    @IBOutlet var remindersTableView: UITableView!
    var reminders: [Reminder] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        remindersTableView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        loadReminders()
    }
    
    func loadReminders() {
        reminders.removeAll()
        
        FirebaseManager.getFamilyReminders { (error, reminders) in
            if let reminders = reminders {
                print("Reminders: \(reminders)")
                self.reminders = reminders
                
                dispatch_async(dispatch_get_main_queue(), { 
                    self.remindersTableView.reloadData()
                })
                
            }
        }
    }
    
    @IBAction func newReminder(sender: UIBarButtonItem) {
        createReminder()
    }
    
    func createReminder() {
        let alert = UIAlertController(title: "New Reminder", message: nil, preferredStyle: .Alert)
        var titleTF: UITextField!
        var descriptionTF: UITextField!
        
        alert.addTextFieldWithConfigurationHandler { (titleTextField) in
            titleTextField.placeholder = "Task"
            titleTextField.autocapitalizationType = UITextAutocapitalizationType.Sentences
            titleTF = titleTextField
        }
        alert.addTextFieldWithConfigurationHandler { (descriptionTextField) in
            descriptionTextField.placeholder = "Notes"
            descriptionTextField.autocapitalizationType = UITextAutocapitalizationType.Sentences
            descriptionTF = descriptionTextField
        }
        
        let confirmAction = UIAlertAction(title: "Create", style: .Default) { (action) in
            if !titleTF.text!.isEmpty && !descriptionTF.text!.isEmpty {
                let now = NSDate()
                let newReminder = Reminder(reminderTitle: titleTF.text!, reminderDescription: descriptionTF.text!, reminderDueDate: now.description)
                
                FirebaseManager.createFamilyReminder(newReminder, completionHandler: { (error, newDatabaseRef) in
                    if error == nil {
                        self.loadReminders()
                    }
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
        }
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("reminderCell")! as UITableViewCell
        let reminder = reminders[indexPath.row]
        
        cell.textLabel?.text = reminder.title
        cell.detailTextLabel!.text = reminder.reminderDescription
        
        return cell
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
