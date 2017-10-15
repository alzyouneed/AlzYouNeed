//
//  RemindersViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/9/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import MessageUI
// import PKHUD

class RemindersViewController: UIViewController, UITableViewDelegate, ReminderTableViewCellDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource {

    @IBOutlet var remindersTableView: UITableView!
    @IBOutlet var reminderSegmentedControl: UISegmentedControl!
    @IBOutlet var addReminderTableButton: UIButton!
    
    let databaseRef = Database.database().reference()
    var addReminderHandle: UInt?
    var removeReminderHandle: UInt?
    
    var badgeCount = 0
    
    // Class-scope for valueChanged function
    let datePickerView: UIDatePicker = UIDatePicker()
    var dateTF: UITextField!
    var repeatsTF: UITextField!
    let repeatPickerView: UIPickerView! = UIPickerView()
//    let repeatOptions = ["None", "Hourly", "Daily", "Weekly"]
//    let repeatOptions = ["No", "Yes"]
    
//    var delegate: ReminderViewControllerDelegate?
    // TESTING ONLY
//    let repeatOptions = ["None", "Hourly", "Daily", "Weekly", "Minute"]
    let repeatOptions = ["None", "Minute", "Daily", "Weekly"]
    
    var alertBeforeTF: UITextField!
    let alertBeforePickerView: UIPickerView! = UIPickerView()
    // TESTING ONLY
//    let alertOptions = ["None", "1 minute before", "15 minutes before", "1 hour before", "1 day before"]
    let alertOptions = ["None", "15 minutes before", "1 hour before", "1 day before"]
    
    @IBOutlet var emergencyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        checkTutorialStatus()
        
        remindersTableView.estimatedRowHeight = 100
        remindersTableView.rowHeight = UITableViewAutomaticDimension
        
        configureEmergencyButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        
        AYNModel.sharedInstance.remindersArr.removeAll()
        self.remindersTableView.reloadData()
        
        checkPhoneNumbersExist()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        registerLocalNotifications()
        addRemindersObservers()
        getCompletedFamilyReminders()
        // Reset badge count
        badgeCount = 0
        updateTabBadge()
    }

    override func viewDidDisappear(_ animated: Bool) {
        // Remove Firebase observers
        removeRemindersObservers()
    }
    
    @IBAction func newReminder(_ sender: UIBarButtonItem) {
        createReminder()
    }
    @IBAction func addReminder(_ sender: UIButton) {
        createReminder()
    }

    func createReminder() {
        let alert = UIAlertController(title: "New Reminder", message: nil, preferredStyle: .alert)
        var titleTF: UITextField!
        var descriptionTF: UITextField!
        repeatPickerView.delegate = self
        repeatPickerView.dataSource = self
        repeatPickerView.tag = 0
        
        alertBeforePickerView.delegate = self
        alertBeforePickerView.dataSource = self
        alertBeforePickerView.tag = 1
        
        alert.addTextField { (titleTextField) in
            titleTextField.placeholder = "Remind me to..."
            titleTextField.autocapitalizationType = UITextAutocapitalizationType.sentences
            titleTextField.autocorrectionType = UITextAutocorrectionType.yes
            titleTF = titleTextField
        }
        alert.addTextField { (descriptionTextField) in
            descriptionTextField.placeholder = "Notes (e.g. Why, Where, Who)"
            descriptionTextField.autocapitalizationType = UITextAutocapitalizationType.sentences
            descriptionTextField.autocorrectionType = UITextAutocorrectionType.yes
            descriptionTF = descriptionTextField
        }
        alert.addTextField { (dateTextField) in
            dateTextField.placeholder = "Due Date"
//            let datePickerView: UIDatePicker = UIDatePicker()
            self.datePickerView.datePickerMode = UIDatePickerMode.dateAndTime
            dateTextField.inputView = self.datePickerView
            self.datePickerView.addTarget(self, action: #selector(RemindersViewController.datePickerValueChanged(_:)), for: UIControlEvents.valueChanged)
            self.dateTF = dateTextField
        }
        alert.addTextField { (alertBeforeTextField) in
            alertBeforeTextField.text = "Alert: None"
            alertBeforeTextField.inputView = self.alertBeforePickerView
            self.alertBeforeTF = alertBeforeTextField
        }
        alert.addTextField { (repeatsTextField) in
//            repeatsTextField.text = "Repeats - No"
            repeatsTextField.text = "Repeats None"
            repeatsTextField.inputView = self.repeatPickerView
            self.repeatsTF = repeatsTextField
        }
        
        let confirmAction = UIAlertAction(title: "Create", style: .default) { (action) in
            if !titleTF.text!.isEmpty && !self.dateTF.text!.isEmpty {
                // Store date as number (time interval)
                let now = Date().timeIntervalSince1970
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM d, yyyy, h:mm a"
                let dueDate = dateFormatter.date(from: self.dateTF.text!)?.timeIntervalSince1970
                
                // Time interval in seconds
                var alertBeforeInterval = TimeInterval(0)
                switch self.alertBeforeTF.text! {
                   case "Alert: None":
                        alertBeforeInterval = TimeInterval(0)
                    case "Alert: 1 minute before":
                        alertBeforeInterval = TimeInterval(60)
                    case "Alert: 15 minutes before":
                        alertBeforeInterval = TimeInterval(15 * 60)
                    case "Alert: 1 hour before":
                        alertBeforeInterval = TimeInterval(60 * 60)
                    case "Alert: 1 day before":
                        alertBeforeInterval = TimeInterval(24 * 60 * 60)
                default:
                    break
                }
                
                var newReminder = ["title":titleTF.text!, "description":descriptionTF.text! , "createdDate":now.description, "dueDate":dueDate!.description, "alertBeforeInterval":"\(alertBeforeInterval)"]
                
//                let repeatsTFText = self.repeatsTF.text?.components(separatedBy: " - ")[1]
                let repeatsTFText = self.repeatsTF.text?.components(separatedBy: " ")[1]
                
                if let repeatOption = repeatsTFText as String? {
                    newReminder["repeats"] = repeatOption
                }
                
                FirebaseManager.createFamilyReminder(newReminder as NSDictionary, completionHandler: { (error, newDatabaseRef) in
                    if error == nil {
                        // Success
                    }
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if reminderSegmentedControl.selectedSegmentIndex == 0 {
            // Incomplete reminders
            return AYNModel.sharedInstance.remindersArr.count
        } else {
            // Completed reminders
            return AYNModel.sharedInstance.completedRemindersArr.count
        }
        
//        return AYNModel.sharedInstance.remindersArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:ReminderTableViewCell = tableView.dequeueReusableCell(withIdentifier: "reminderCell")! as! ReminderTableViewCell
//        let cell:ReminderTableViewCell = tableView.dequeueReusableCell(withIdentifier: "reminderCell", for: indexPath) as! ReminderTableViewCell
        
        if reminderSegmentedControl.selectedSegmentIndex == 0 {
            let reminder = AYNModel.sharedInstance.remindersArr[(indexPath as NSIndexPath).row]
            cell.delegate = self
            cell.titleLabel.text = reminder.title
            
            // Format readable date
            let date = Date(timeIntervalSince1970: Double(reminder.dueDate)!)
            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "MMMM d, h:mm a"
//            cell.dateLabel.text = "Due \(dateFormatter.string(from: date))"
//            cell.descriptionLabel.text = reminder.reminderDescription
            
            cell.completedButton.isHidden = false
            
            if reminder.repeats != "None" {
//            if reminder.repeats == "Yes" {
                cell.repeatsLabel.text = "Repeats \(reminder.repeats!)"
//                cell.repeatsLabel.text = "Repeats"
                cell.repeatsLabel.isHidden = false
                dateFormatter.dateFormat = "h:mm a"
                cell.dateLabel.text = "Due \(dateFormatter.string(from: date))"
                cell.descriptionLabel.text = reminder.reminderDescription
            } else {
                cell.repeatsLabel.isHidden = true
                dateFormatter.dateFormat = "MMMM d, h:mm a"
                cell.dateLabel.text = "Due \(dateFormatter.string(from: date))"
                cell.descriptionLabel.text = reminder.reminderDescription
            }
            cell.isUserInteractionEnabled = true
        } else {
            let reminder = AYNModel.sharedInstance.completedRemindersArr[(indexPath as NSIndexPath).row]
            cell.delegate = self
            cell.titleLabel.text = reminder.title
            
            // Format readable date
            let date = Date(timeIntervalSince1970: Double(reminder.completedDate)!)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, h:mm a"
            cell.dateLabel.text = "Completed \(dateFormatter.string(from: date))"
            cell.descriptionLabel.text = reminder.reminderDescription
            
            cell.repeatsLabel.isHidden = true
            cell.completedButton.isHidden = true
            cell.isUserInteractionEnabled = false
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // Only allow editing if incomplete reminders
        if reminderSegmentedControl.selectedSegmentIndex == 0 {
            
            if editingStyle == .delete {
                let reminder = AYNModel.sharedInstance.remindersArr[(indexPath as NSIndexPath).row]
                FirebaseManager.deleteFamilyReminder(reminder.id, completionHandler: { (error, newDatabaseRef) in
                    if error == nil {
                        // Observers catch deletion and properly update data source array and UI
                        self.cancelLocalNotification(reminder.id)
                        
                        // Adjust badge count
                        if self.badgeCount > 0 {
                            DispatchQueue.main.async(execute: {
                                self.badgeCount -= 1
                                self.updateTabBadge()
                            })
                        }
                    }
                })
            }
            else if editingStyle == .insert {
                // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
            }
        }
    }
    
    // MARK: - Firebase Observers
    func addRemindersObservers() {
        print("Adding Firebase observers")
        
        if let groupId = AYNModel.sharedInstance.groupId {
            addReminderHandle = self.databaseRef.child(GroupPath).child(groupId).child("reminders").queryOrdered(byChild: "dueDate").observe(DataEventType.childAdded, with: { (snapshot) in
                if let reminderDict = snapshot.value! as? NSDictionary {
                    if let newReminder = Reminder(reminderId: snapshot.key, reminderDict: reminderDict) {
                        print("New reminder in RTDB")
                        
                        AYNModel.sharedInstance.remindersArr.append(newReminder)
                        
                        // Schedule local notifications
                        if let dueDate = Date(timeIntervalSince1970: Double(newReminder.dueDate)!) as Date? {
                            let now = Date()
                            let calendar = Calendar.current
                            // Check that date has not passed
                            if calendar.compare(dueDate, to: now, toGranularity: .second) == .orderedDescending || newReminder.repeats != "None" {
                                self.scheduleLocalNotification(snapshot.key, reminder: reminderDict)
                            }
                            else {
                                print("Reminder due date has passed -- skipping")
                            }
                        }
                        
                        self.remindersTableView.insertRows(at: [IndexPath(row: AYNModel.sharedInstance.remindersArr.count-1, section: 0)], with: UITableViewRowAnimation.automatic)
                        //                            self.updateTabBadge()
                    }
                }
            })
            removeReminderHandle = self.databaseRef.child(GroupPath).child(groupId).child("reminders").observe(DataEventType.childRemoved, with: { (snapshot) in
                if let reminderId = snapshot.key as String? {
                    if let index = self.getIndex(reminderId) {
                        print("Removing reminder in RTDB")
                        
                        AYNModel.sharedInstance.remindersArr.remove(at: index)
                        
                        // Cancel any local notifications
                        self.cancelLocalNotification(reminderId)
                        
                        self.remindersTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
                        self.updateTabBadge()
                    }
                }
            })
        }
    }
    
    func removeRemindersObservers() {
        if let groupId = AYNModel.sharedInstance.groupId {
            if addReminderHandle != nil {
                self.databaseRef.child(GroupPath).child(groupId).child("reminders").removeObserver(withHandle: addReminderHandle!)
                addReminderHandle = nil
                print("Removed addedReminderHandle")
            }
            if removeReminderHandle != nil {
                self.databaseRef.child(GroupPath).child(groupId).child("reminders").removeObserver(withHandle: removeReminderHandle!)
                removeReminderHandle = nil
                print("Removed removeReminderHandle")
            }
        }
    }
    
    // MARK: - Tab bar
    func resetTabBadges() {
        let tabArray = tabBarController!.tabBar.items as NSArray!
        let tabItem = tabArray?.object(at: 2) as! UITabBarItem
        tabItem.badgeValue = nil
    }
    
    func updateTabBadge() {
        let tabArray = tabBarController!.tabBar.items as NSArray!
        let tabItem = tabArray?.object(at: 2) as! UITabBarItem
        
        if badgeCount > 0 {
            tabItem.badgeValue = "\(badgeCount)"
        } else {
            tabItem.badgeValue = nil
        }
        
//        if AYNModel.sharedInstance.remindersArr.count == 0 {
//            tabItem.badgeValue = nil
//        }
//        else {
////            tabItem.badgeValue = "\(AYNModel.sharedInstance.remindersArr.count)"
//            tabItem.badgeValue = "\(badgeCount)"
//        }
    }
    
    // MARK: - Reminders Array
    func getIndex(_ id: String) -> Int? {
        for (index, reminder) in AYNModel.sharedInstance.remindersArr.enumerated() {
            if reminder.id == id {
                return index
            }
        }
        return nil
    }
    
    // MARK: - Reminder Actions
    func cellButtonTapped(_ cell: ReminderTableViewCell) {
        if reminderSegmentedControl.selectedSegmentIndex == 0 {
            let indexPath = self.remindersTableView.indexPathForRow(at: cell.center)!
            if let completedReminder = AYNModel.sharedInstance.remindersArr[(indexPath as NSIndexPath).row] as Reminder? {
                confirmCompleteReminder(completedReminder)
            }
        }
    }
    
    func confirmCompleteReminder(_ completedReminder: Reminder) {
        let alertController = UIAlertController(title: "Are you sure you're done?", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Yes!", style: .default) { (action) in
            FirebaseManager.completeFamilyReminder(completedReminder, completionHandler: { (error, newDatabaseRef) in
                if error == nil {
                    // Success
                    // HUD.flash(.Success)
                    
                    // Adjust badge count
                    if self.badgeCount > 0 {
                        DispatchQueue.main.async(execute: {
                            self.badgeCount -= 1
                            self.updateTabBadge()
                        })
                    }
                    
                    // Update complete reminders arr
                    self.getCompletedFamilyReminders()
                    
                    // Check if repeating to reschedule
//                    print("Completed reminder repeats:", completedReminder.repeats)
                    if completedReminder.repeats != "None" {
//                    if completedReminder.repeats == "Yes" {
                        FirebaseManager.createFamilyReminder(completedReminder.asDict() as NSDictionary, completionHandler: { (error, databaseRef) in
                            if error != nil {
                                print("Error rescheduling repeated reminder:", error!)
                            } else {
                                print("Rescheduled repeated reminder")
                            }
                        })
                    }

                }
            })
        }
        let cancelAction = UIAlertAction(title: "Nope", style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Configuration
    func configureView() {
        // tableView
        remindersTableView.delegate = self
        remindersTableView.rowHeight = UITableViewAutomaticDimension
        remindersTableView.estimatedRowHeight = 99
        
        // completedButton
//        completedButton.layer.cornerRadius = completedButton.frame.height/2
    }
    
    // MARK: - Date Picker
    func datePickerValueChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateTF.text = dateFormatter.string(from: sender.date)
    }
    
    // MARK: - Push Notifications
    func registerLocalNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if error != nil {
                print("Error requesting push notification auth:", error!)
            } else {
                if granted {
                    print("Push notification auth granted")
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("Push notification auth denied")
                }
            }
        }
//        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func scheduleLocalNotification(_ reminderId: String, reminder: NSDictionary) {
        if UIApplication.shared.isRegisteredForRemoteNotifications {
            var reminderScheduled = false
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                for notification in requests {
                    // Notification exists
                    if notification.identifier == reminderId || notification.identifier == "\(reminderId).alertBefore" {
                        print("Local notification already pending:", notification.identifier)
                        reminderScheduled = true
                    }
                }
                
                // Stops scheduling if already pending
                guard case reminderScheduled = false else {return}
                
                let content = UNMutableNotificationContent()
                content.title = "Reminder"
                content.body = reminder.value(forKey: "title") as! String
                content.sound = UNNotificationSound.default()
                content.categoryIdentifier = "reminderCategory"
                
                let dueDateInterval = TimeInterval(reminder.value(forKey: "dueDate") as! String)!
                let date = Date(timeIntervalSince1970: dueDateInterval)
                let calendar = Calendar.current
                var dateComponents = DateComponents()
                
                var alertBeforeDate:Date? = nil
                var alertBeforeDateComponents: DateComponents? = nil
                var alertInterval: TimeInterval? = nil
                if let alertBeforeInterval = TimeInterval((reminder.value(forKey: "alertBeforeInterval") as? String)!) {
                    if alertBeforeInterval != 0.0 {
                        alertBeforeDate = Date(timeIntervalSince1970: dueDateInterval - alertBeforeInterval)
                        alertInterval = alertBeforeInterval
                    }
                }
                
                // Check if reminder should repeat
                var shouldRepeat = false
                
                if let repeatOption = reminder["repeats"] as? String {
                    switch repeatOption {
                    case "None":
                        shouldRepeat = false
                    case "Minute":
                        shouldRepeat = true
                        dateComponents = calendar.dateComponents([.second], from: date)
                        if alertBeforeDate != nil {
                            alertBeforeDateComponents = calendar.dateComponents([.second], from: alertBeforeDate!)
                        }
                    case "Hourly":
                        shouldRepeat = true
                        // Only look at minute to repeat each hour
                        dateComponents = calendar.dateComponents([.minute], from: date)
                        if alertBeforeDate != nil {
                            alertBeforeDateComponents = calendar.dateComponents([.minute], from: alertBeforeDate!)
                        }
                    case "Daily":
                        shouldRepeat = true
                        // Only look at minute, hour to repeat each day
                        dateComponents = calendar.dateComponents([.minute, .hour], from: date)
                        if alertBeforeDate != nil {
                            alertBeforeDateComponents = calendar.dateComponents([.minute, .hour], from: alertBeforeDate!)
                        }
                    case "Weekly":
                        shouldRepeat = true
                        // Only look at minute, hour, day to repeat each week
                        dateComponents = calendar.dateComponents([.minute, .hour, .day], from: date)
                        if alertBeforeDate != nil {
                            alertBeforeDateComponents = calendar.dateComponents([.minute, .hour, .day], from: alertBeforeDate!)
                        }
                    default:
                        break
                    }
                }
                
                if !shouldRepeat {
                    dateComponents = calendar.dateComponents([.second, .minute, .hour, .day], from: date)
                    if alertBeforeDate != nil {
                        alertBeforeDateComponents = calendar.dateComponents([.second, .minute, .hour, .day], from: alertBeforeDate!)
                    }
                }
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: shouldRepeat)
                let request = UNNotificationRequest(identifier: reminderId, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
                    if error != nil {
                        print("Error adding push notification request:", error!)
                    } else {
                        
                        print("Push notification request added")
                        
                        // Add additional reminder if alertBeforeInterval > 0.0 -- TODO: Change repeats value
                        if alertBeforeDateComponents != nil {
                            // Don't allow snooze
                            content.categoryIdentifier = ""
                            
                            // Modify notification message
                            if alertInterval != nil {
                                switch alertInterval! {
                                    case TimeInterval(60):
                                        content.body = "\(content.body) in 1 minute"
                                    case TimeInterval(15 * 60):
                                        content.body = "\(content.body) in 15 minutes"
                                    case TimeInterval(60 * 60):
                                        content.body = "\(content.body) in 1 hour"
                                    case TimeInterval(24 * 60 * 60):
                                        content.body = "\(content.body) in 1 day"
                                default:
                                    break
                                }
                            }
                            
                            let alertBeforeTrigger = UNCalendarNotificationTrigger(dateMatching: alertBeforeDateComponents!, repeats: false)
                            let alertBeforeRequest = UNNotificationRequest(identifier: "\(reminderId).alertBefore", content: content, trigger: alertBeforeTrigger)
                            UNUserNotificationCenter.current().add(alertBeforeRequest, withCompletionHandler: { (error) in
                                if error != nil {
                                    print("Error adding alertBefore request:", error!)
                                } else {
                                    print("alertBefore request added")
                                }
                            })
                        }
                        
                        DispatchQueue.main.async(execute: {
                            self.badgeCount += 1
                            self.updateTabBadge()
                        })

                        if shouldRepeat {
                            print("Time before next trigger: \(Date().timeIntervalSince(trigger.nextTriggerDate()!)) seconds --OR-- \(Date().timeIntervalSince(trigger.nextTriggerDate()!)/60) minutes")
                        }
                    }
                })
            })
        } else {
            // Notifications disabled -- check if showed warning
            if !UserDefaultsManager.getReminderWarningStatus() {
                UserDefaultsManager.setReminderWarningStatus(status: true)
                let alertController = UIAlertController(title: "Tip", message: "Enable notifications to be reminded of items on your to-do list", preferredStyle: .alert)
                let enableAction = UIAlertAction(title: "Enable", style: .default, handler: { (action) in
                    if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                        UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                    }
                })
                let cancelAction = UIAlertAction(title: "No thanks", style: .cancel, handler: nil)
                alertController.addAction(enableAction)
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func cancelLocalNotification(_ reminderId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId, "\(reminderId).alertBefore"])
    }
    
    // MARK: - UIPickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return repeatOptions.count
        } else {
            return alertOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return repeatOptions[row]
        } else {
            return alertOptions[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 {
            repeatsTF.text = "Repeats \(repeatOptions[row])"
        } else {
            alertBeforeTF.text = "Alert: \(alertOptions[row])"
        }
    }
    
    // MARK: Tutorial
    func checkTutorialStatus() {
        if let reminderTutorialCompleted = UserDefaultsManager.getTutorialCompletion(tutorial: Tutorials.reminders.rawValue) as String? {
            if reminderTutorialCompleted == "false" {
                showTutorial()
            } else {
                print("Reminder tutorial completed")
            }
        }
    }
    
    func showTutorial() {
        let alertController = UIAlertController(title: "Tutorial", message: "Create and manage all family reminders here!", preferredStyle: .alert)
        
        let completeAction = UIAlertAction(title: "Got it!", style: .default) { (action) in
            UserDefaultsManager.completeTutorial(tutorial: "reminders")
        }
        
        alertController.addAction(completeAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Segmented Control
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // Show To do's
//            print("Show incomplete reminders")
            addReminderTableButton.isHidden = false
        } else if sender.selectedSegmentIndex == 1 {
            // Show completed reminders
//            print("Show completed reminders")
            addReminderTableButton.isHidden = true
        }
        remindersTableView.reloadData()
    }
}

// MARK: - Completed Reminders
extension RemindersViewController {
    func getCompletedFamilyReminders() {
        FirebaseManager.getCompletedFamilyReminders { (completedReminders, error) in
            if error == nil {
                // Success
                if let completedReminders = completedReminders {
                    AYNModel.sharedInstance.completedRemindersArr = completedReminders
                    
                    self.remindersTableView.reloadData()
                }
            }
        }
    }
}

extension RemindersViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result.rawValue {
        case MessageComposeResult.cancelled.rawValue:
            print("Message cancelled")
        case MessageComposeResult.failed.rawValue:
            print("Message failed")
        case MessageComposeResult.sent.rawValue:
            print("Message sent")
        default:
            break
        }
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Emergency button
extension RemindersViewController {
    func configureEmergencyButton() {
        print("Configuring emergency button")
        emergencyButton.backgroundColor = sunsetOrange
        emergencyButton.layer.cornerRadius = emergencyButton.frame.width/2
        emergencyButton.layer.shadowRadius = 1
        emergencyButton.layer.shadowColor = UIColor.black.cgColor
        emergencyButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        emergencyButton.layer.shadowOpacity = 0.5
        
        emergencyButton.addTarget(self, action: #selector(RemindersViewController.emergencyButtonPressed(_:)), for: [.touchUpInside, .touchDown])
        
        checkPhoneNumbersExist()
    }
    
    func checkPhoneNumbersExist() {
        self.emergencyButton.isHidden = AYNModel.sharedInstance.familyMemberNumbers.isEmpty ? true : false
        self.emergencyButton.isUserInteractionEnabled = AYNModel.sharedInstance.familyMemberNumbers.isEmpty ? false : true
    }
    
    func emergencyButtonPressed(_ sender: UIButton) {
        print("Emergency button pressed")
        let messageVC = MFMessageComposeViewController()
        messageVC.body = "EMERGENCY: I need help now!"
        messageVC.recipients = AYNModel.sharedInstance.familyMemberNumbers
        messageVC.messageComposeDelegate = self
        present(messageVC, animated: true, completion: nil)
    }
    
}
