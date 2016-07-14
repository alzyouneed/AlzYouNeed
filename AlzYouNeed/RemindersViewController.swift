//
//  RemindersViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/9/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class RemindersViewController: UIViewController, UITableViewDelegate, ReminderTableViewCellDelegate {

    @IBOutlet var remindersTableView: UITableView!

    var reminders = AYNModel.sharedInstance.remindersArr
    
    let databaseRef = FIRDatabase.database().reference()
    var familyId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        remindersTableView.delegate = self
        remindersTableView.rowHeight = UITableViewAutomaticDimension
        remindersTableView.estimatedRowHeight = 66
    }
    
    override func viewWillAppear(animated: Bool) {
        self.reminders.removeAll()
        self.remindersTableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        addRemindersObservers()
//        resetTabBadges()
    }
    
    override func viewDidDisappear(animated: Bool) {
        // Remove Firebase observers
        removeRemindersObservers()
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
            titleTextField.autocorrectionType = UITextAutocorrectionType.Yes
            titleTF = titleTextField
        }
        alert.addTextFieldWithConfigurationHandler { (descriptionTextField) in
            descriptionTextField.placeholder = "Notes"
            descriptionTextField.autocapitalizationType = UITextAutocapitalizationType.Sentences
            descriptionTextField.autocorrectionType = UITextAutocorrectionType.Yes
            descriptionTF = descriptionTextField
        }
        
        let confirmAction = UIAlertAction(title: "Create", style: .Default) { (action) in
            if !titleTF.text!.isEmpty {
                let now = NSDate()
                let newReminder = ["title":titleTF.text!, "description":descriptionTF.text! ?? "", "dueDate":now.description]
//                let newReminder = Reminder(reminderTitle: titleTF.text!, reminderDescription: descriptionTF.text! ?? "", reminderDueDate: now.description)
                
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

        cell.delegate = self
        cell.titleLabel.text = reminder.title
        cell.descriptionLabel.text = reminder.reminderDescription
    
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let reminder = reminders[indexPath.row]
            FirebaseManager.deleteFamilyReminder(reminder.id, completionHandler: { (error, newDatabaseRef) in
                if error == nil {
                    // Observers catch deletion and properly update data source array and UI
                }
            })
        }
        else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
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
                            if let newReminder = Reminder(reminderId: snapshot.key, reminderDict: reminderDict) {
                                print("New reminder in RTDB")
                                self.reminders.append(newReminder)
                                self.remindersTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.reminders.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                                self.updateTabBadge()
                            }
                        }
                    })
                    
                    self.databaseRef.child("families").child(userFamilyId).child("reminders").observeEventType(FIRDataEventType.ChildRemoved, withBlock: { (snapshot) in
                        if let reminderId = snapshot.key as String? {
                            if let index = self.getIndex(reminderId) {
                                print("Removing reminder in RTDB")
                                self.reminders.removeAtIndex(index)
                                self.remindersTableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                                self.updateTabBadge()
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
    
    // MARK: - Tab bar
    func resetTabBadges() {
        let tabArray = tabBarController!.tabBar.items as NSArray!
        let tabItem = tabArray.objectAtIndex(2) as! UITabBarItem
        tabItem.badgeValue = nil
    }
    
    func updateTabBadge() {
        let tabArray = tabBarController!.tabBar.items as NSArray!
        let tabItem = tabArray.objectAtIndex(2) as! UITabBarItem
        
        if reminders.count == 0 {
            tabItem.badgeValue = nil
        }
        else {
            tabItem.badgeValue = "\(reminders.count)"
        }
    }
    
    // MARK: - Reminders Array
    func getIndex(id: String) -> Int? {
        for (index, reminder) in reminders.enumerate() {
            if reminder.id == id {
                return index
            }
        }
        return nil
    }
    
    // MARK: - Reminder Actions
    func cellButtonTapped(cell: ReminderTableViewCell) {
        let indexPath = self.remindersTableView.indexPathForRowAtPoint(cell.center)!
        if let completedReminder = reminders[indexPath.row] as Reminder? {
            FirebaseManager.completeFamilyReminder(completedReminder, completionHandler: { (error, newDatabaseRef) in
                if error == nil {
                    // Success
                }
            })
        }
    }
    
    // MARK: - Present different VC's
    @IBAction func showCompletedReminders(sender: UIButton) {
        presentCompletedRemindersVC()
    }
    
    func presentCompletedRemindersVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let completeRemindersVC: CompleteRemindersTableViewController = storyboard.instantiateViewControllerWithIdentifier("completedReminders") as! CompleteRemindersTableViewController
        
        // Hide tab bar in updateProfileVC
        completeRemindersVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(completeRemindersVC, animated: true)
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
