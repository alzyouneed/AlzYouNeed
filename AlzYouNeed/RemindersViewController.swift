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
    @IBOutlet var completedButton: UIButton!
    
    let databaseRef = FIRDatabase.database().reference()
    var familyId: String!
    
    // Class-scope for valueChanged function
    var dateTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        
        AYNModel.sharedInstance.remindersArr.removeAll()
        self.remindersTableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        registerLocalNotifications()
        addRemindersObservers()
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
//        var dateTF: UITextField!
        
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
        alert.addTextFieldWithConfigurationHandler { (dateTextField) in
            dateTextField.placeholder = "Due Date"
            let datePickerView: UIDatePicker = UIDatePicker()
            datePickerView.datePickerMode = UIDatePickerMode.DateAndTime
            dateTextField.inputView = datePickerView
            datePickerView.addTarget(self, action: #selector(RemindersViewController.datePickerValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
            self.dateTF = dateTextField
        }
        
        let confirmAction = UIAlertAction(title: "Create", style: .Default) { (action) in
            if !titleTF.text!.isEmpty && !self.dateTF.text!.isEmpty {
                // Store date as number (time interval)
                let now = NSDate().timeIntervalSince1970
                
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "MMMM d, yyyy, h:mm a"
                let dueDate = dateFormatter.dateFromString(self.dateTF.text!)?.timeIntervalSince1970
                let newReminder = ["title":titleTF.text!, "description":descriptionTF.text! ?? "", "createdDate":now.description, "dueDate":dueDate!.description]
                
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
        return AYNModel.sharedInstance.remindersArr.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:ReminderTableViewCell = tableView.dequeueReusableCellWithIdentifier("reminderCell")! as! ReminderTableViewCell
        
        let reminder = AYNModel.sharedInstance.remindersArr[indexPath.row]
        cell.delegate = self
        cell.titleLabel.text = reminder.title
        
        // Format readable date
        let date = NSDate(timeIntervalSince1970: Double(reminder.dueDate)!)
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMMM d, h:mm a"
        cell.dateLabel.text = "Due \(dateFormatter.stringFromDate(date))"
        cell.descriptionLabel.text = reminder.reminderDescription
    
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let reminder = AYNModel.sharedInstance.remindersArr[indexPath.row]
            FirebaseManager.deleteFamilyReminder(reminder.id, completionHandler: { (error, newDatabaseRef) in
                if error == nil {
                    // Observers catch deletion and properly update data source array and UI
                    self.cancelLocalNotification(reminder.id)
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
                    self.databaseRef.child("families").child(userFamilyId).child("reminders").queryOrderedByChild("dueDate").observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in

                        if let reminderDict = snapshot.value! as? NSDictionary {
                            if let newReminder = Reminder(reminderId: snapshot.key, reminderDict: reminderDict) {
                                print("New reminder in RTDB")
                                
                                AYNModel.sharedInstance.remindersArr.append(newReminder)
                                
                                // Schedule local notifications
                                if let dueDate = NSDate(timeIntervalSince1970: Double(newReminder.dueDate)!) as NSDate? {
                                    let now = NSDate()
                                    // Check that date has not passed
                                    if !dueDate.earlierDate(now).isEqualToDate(dueDate) {
                                        self.scheduleLocalNotification(snapshot.key, reminder: reminderDict)
                                    }
                                    else {
                                        print("Reminder due date has passed -- skipping")
                                    }
                                }

                                self.remindersTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: AYNModel.sharedInstance.remindersArr.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                                self.updateTabBadge()
                            }
                        }
                    })
                    
                    self.databaseRef.child("families").child(userFamilyId).child("reminders").observeEventType(FIRDataEventType.ChildRemoved, withBlock: { (snapshot) in
                        if let reminderId = snapshot.key as String? {
                            if let index = self.getIndex(reminderId) {
                                print("Removing reminder in RTDB")
                                
                                AYNModel.sharedInstance.remindersArr.removeAtIndex(index)
                                
                                // Cancel any local notifications
                                self.cancelLocalNotification(reminderId)

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
        
        if AYNModel.sharedInstance.remindersArr.count == 0 {
            tabItem.badgeValue = nil
        }
        else {
            tabItem.badgeValue = "\(AYNModel.sharedInstance.remindersArr.count)"
        }
    }
    
    // MARK: - Reminders Array
    func getIndex(id: String) -> Int? {
        for (index, reminder) in AYNModel.sharedInstance.remindersArr.enumerate() {
            if reminder.id == id {
                return index
            }
        }
        return nil
    }
    
    // MARK: - Reminder Actions
    func cellButtonTapped(cell: ReminderTableViewCell) {
        let indexPath = self.remindersTableView.indexPathForRowAtPoint(cell.center)!
        if let completedReminder = AYNModel.sharedInstance.remindersArr[indexPath.row] as Reminder? {
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
        let completeRemindersVC: CompleteRemindersViewController = storyboard.instantiateViewControllerWithIdentifier("completedReminders") as! CompleteRemindersViewController
        
        // Hide tab bar in updateProfileVC
        completeRemindersVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(completeRemindersVC, animated: true)
    }
    
    // MARK: - Configuration
    func configureView() {
        // tableView
        remindersTableView.delegate = self
        remindersTableView.rowHeight = UITableViewAutomaticDimension
        remindersTableView.estimatedRowHeight = 99
        
        // completedButton
        completedButton.layer.cornerRadius = completedButton.frame.height/2
    }
    
    // MARK: - Date Picker
    func datePickerValueChanged(sender: UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        dateTF.text = dateFormatter.stringFromDate(sender.date)
    }
    
    // MARK: - Push Notifications
    func registerLocalNotifications() {
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    }
    
    func scheduleLocalNotification(reminderId: String, reminder: NSDictionary) {
        // Check if have permission to schedule push notifications
        guard let settings = UIApplication.sharedApplication().currentUserNotificationSettings() else { return }
        
        // Permission denied
        if settings.types == .None {
            let alertController = UIAlertController(title: "Tip", message: "Enable push notifications to be reminded of future tasks", preferredStyle: .Alert)
            let enableAction = UIAlertAction(title: "Enable", style: .Default, handler: { (action) in
                if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(appSettings)
                }
            })
            let cancelAction = UIAlertAction(title: "No thanks", style: .Cancel, handler: nil)
            alertController.addAction(enableAction)
            alertController.addAction(cancelAction)
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        // Check for existing notification for reminder
        if let scheduledNotifications: [UILocalNotification]? = UIApplication.sharedApplication().scheduledLocalNotifications {
            for notification in scheduledNotifications! {
                if let userInfo = notification.userInfo {
                    if let existingReminderId = userInfo["reminderId"] as? String {
                        if existingReminderId == reminderId {
                            print("Local notification already exists")
                            return
                        }
                    }
                }
            }
        }
        
        // Permission granted & Notification does not already exist
        print("Scheduling local notification")
        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSince1970: NSTimeInterval(reminder["dueDate"] as! String)!)
        notification.alertBody = "Reminder: \(reminder["title"]!)"
        notification.alertAction = "View"
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = ["reminderId": reminderId]
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func cancelLocalNotification(reminderId: String) {
        let scheduledNotifications: [UILocalNotification]? = UIApplication.sharedApplication().scheduledLocalNotifications
        guard scheduledNotifications != nil else { return }
        
        for notification in scheduledNotifications! {
            if let userInfo = notification.userInfo {
                if let existingReminderId = userInfo["reminderId"] as? String {
                    if existingReminderId == reminderId {
                        print("Cancelling local notification")
                        UIApplication.sharedApplication().cancelLocalNotification(notification)
                        break
                    }
                }
            }
        }
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
