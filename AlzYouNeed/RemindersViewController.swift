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
    let databaseRef = FIRDatabase.database().reference()
    var familyId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        remindersTableView.delegate = self
        remindersTableView.rowHeight = UITableViewAutomaticDimension
        remindersTableView.estimatedRowHeight = 60
    }
    
    override func viewWillAppear(animated: Bool) {
        self.reminders.removeAll()
        self.remindersTableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        addRemindersObservers()
//        loadReminders()
    }
    
    override func viewDidDisappear(animated: Bool) {
        // Remove Firebase observers
        removeRemindersObservers()
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
            if !titleTF.text!.isEmpty {
                let now = NSDate()
                let newReminder = Reminder(reminderTitle: titleTF.text!, reminderDescription: descriptionTF.text! ?? "", reminderDueDate: now.description)
                
                FirebaseManager.createFamilyReminder(newReminder, completionHandler: { (error, newDatabaseRef) in
                    if error == nil {
                        // Success
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
        let cell:ReminderTableViewCell = tableView.dequeueReusableCellWithIdentifier("reminderCell")! as! ReminderTableViewCell
        let reminder = reminders[indexPath.row]
        
        cell.titleLabel.text = reminder.title
        cell.descriptionLabel.text = reminder.reminderDescription
        
//        cell.textLabel?.text = reminder.title
//        cell.detailTextLabel!.text = reminder.reminderDescription
        
        return cell
    }
    
    // MARK: - Firebase Observers
    func addRemindersObservers() {
        print("Adding Firebase observers")
        FirebaseManager.getCurrentUser { (userDict, error) in
            if error == nil {
                if let userFamilyId = userDict?.valueForKey("familyId") as? String {
                    self.familyId = userFamilyId
                    self.databaseRef.child("families").child(userFamilyId).child("reminders").observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in
                        if let reminderDict = snapshot.value! as? NSDictionary {
                            if let newReminder = Reminder(reminderDict: reminderDict) {
                                print("New reminder in RTDB")
                                self.reminders.append(newReminder)
                                self.remindersTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.reminders.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                            }
                        }
                    })
                    
                    self.databaseRef.child("families").child(userFamilyId).child("reminders").observeEventType(FIRDataEventType.ChildRemoved, withBlock: { (snapshot) in
                        if let reminderDict = snapshot.value! as? NSDictionary {
                            if let reminderTitle = reminderDict.valueForKey("title") as? String {
                                // TODO: Change removal logic -- Check for ID
                                for (index,reminder) in self.reminders.enumerate() {
                                    if reminder.title == reminderTitle {
                                        print("Removing reminder in RTDB")
                                        self.reminders.removeAtIndex(index)
                                        self.remindersTableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                                    }
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    func removeRemindersObservers() {
        print("Removing Firebase observers")
        self.databaseRef.child("families").child(familyId).child("reminders").removeAllObservers()
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
