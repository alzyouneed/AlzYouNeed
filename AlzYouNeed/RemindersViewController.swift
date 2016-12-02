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
// import PKHUD

class RemindersViewController: UIViewController, UITableViewDelegate, ReminderTableViewCellDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet var remindersTableView: UITableView!
    @IBOutlet var reminderSegmentedControl: UISegmentedControl!
    @IBOutlet var addReminderTableButton: UIButton!
    
    let databaseRef = FIRDatabase.database().reference()
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
    let repeatOptions = ["None", "Hourly", "Daily", "Weekly", "Minute"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        checkTutorialStatus()
        
        remindersTableView.estimatedRowHeight = 100
        remindersTableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        
        AYNModel.sharedInstance.remindersArr.removeAll()
        self.remindersTableView.reloadData()
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
//                let dateFormatter = DateFormatter()
                // Handle repeating differently
//                if self.repeatsTF.text != "Repeats None" {
//                    dateFormatter.dateFormat = "h:mm a"
//                } else {
//                    dateFormatter.dateFormat = "MMMM d, yyyy, h:mm a"
//                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM d, yyyy, h:mm a"
                let dueDate = dateFormatter.date(from: self.dateTF.text!)?.timeIntervalSince1970
                
                var newReminder = ["title":titleTF.text!, "description":descriptionTF.text! , "createdDate":now.description, "dueDate":dueDate!.description]
                
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
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
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
    
    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
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
        if AYNModel.sharedInstance.currentUser != nil {
            if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
               addReminderHandle = self.databaseRef.child("families").child(userFamilyId).child("reminders").queryOrdered(byChild: "dueDate").observe(FIRDataEventType.childAdded, with: { (snapshot) in
                    if let reminderDict = snapshot.value! as? NSDictionary {
                        if let newReminder = Reminder(reminderId: snapshot.key, reminderDict: reminderDict) {
                            print("New reminder in RTDB")
                            
                            AYNModel.sharedInstance.remindersArr.append(newReminder)
                            
                            // Schedule local notifications
                            if let dueDate = Date(timeIntervalSince1970: Double(newReminder.dueDate)!) as Date? {
                                let now = Date()
                                // Check that date has not passed
//                                if (dueDate as NSDate).earlierDate(now) != dueDate {
                                    self.scheduleLocalNotification(snapshot.key, reminder: reminderDict)
//                                }
//                                else {
//                                    print("Reminder due date has passed -- skipping")
//                                }
                            }
                            
                            self.remindersTableView.insertRows(at: [IndexPath(row: AYNModel.sharedInstance.remindersArr.count-1, section: 0)], with: UITableViewRowAnimation.automatic)
//                            self.updateTabBadge()
                        }
                    }
                })
                removeReminderHandle = self.databaseRef.child("families").child(userFamilyId).child("reminders").observe(FIRDataEventType.childRemoved, with: { (snapshot) in
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

//                print("addReminderHandle: \(addReminderHandle) -- removeReminderHandle: \(removeReminderHandle)")
            }
        }
    }
    
    func removeRemindersObservers() {
//        print("Removing Firebase observers")
        if AYNModel.sharedInstance.currentUser != nil {
            if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                if addReminderHandle != nil {
                    self.databaseRef.child("families").child(userFamilyId).child("reminders").removeObserver(withHandle: addReminderHandle!)
                    addReminderHandle = nil
                    print("Removed addedReminderHandle")
                }
                if removeReminderHandle != nil {
                    self.databaseRef.child("families").child(userFamilyId).child("reminders").removeObserver(withHandle: removeReminderHandle!)
                    removeReminderHandle = nil
                    print("Removed removeReminderHandle")
                }
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
                    
                    // Check if repeating to reschedule
                    print("Completed reminder repeats:", completedReminder.repeats)
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
//        if !repeatsTF.text!.isEmpty {
//            if repeatsTF.text != "Repeats None" {
//                dateFormatter.timeStyle = DateFormatter.Style.short
//            } else {
//                dateFormatter.dateStyle = DateFormatter.Style.medium
//                dateFormatter.timeStyle = DateFormatter.Style.short
//            }
//        }
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
//                    let action = UNNotificationAction(identifier: "snooze", title: "Snooze", options: [])
//                    let category = UNNotificationCategory(identifier: "reminderCategory", actions: [action], intentIdentifiers: [], options: [])
//                    UNUserNotificationCenter.current().setNotificationCategories([category])
                } else {
                    print("Push notification auth denied")
                }
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func scheduleLocalNotification(_ reminderId: String, reminder: NSDictionary) {
        if UIApplication.shared.isRegisteredForRemoteNotifications {
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                for notification in requests {
                    // Notification exists
                    if notification.identifier == reminderId {
                        print("Local notification already pending")
                        return
                    }
                }
                // Notification does not exist
                let center = UNUserNotificationCenter.current()
                
                let content = UNMutableNotificationContent()
                content.title = "Reminder"
                content.body = reminder.value(forKey: "title") as! String
                content.sound = UNNotificationSound.default()
                content.categoryIdentifier = "reminderCategory"
                
                let dueDateInterval = TimeInterval(reminder.value(forKey: "dueDate") as! String)!
                let date = Date(timeIntervalSince1970: dueDateInterval)
                let calendar = Calendar.current
//                let dateComponents = calendar.dateComponents([.minute, .hour, .day], from: date)
                var dateComponents = DateComponents()
                
                // Check if reminder should repeat
                var shouldRepeat = false

//                if let repeatOption = reminder["repeats"] as? String {
//                    switch repeatOption {
//                        case "Yes":
//                            shouldRepeat = true
//                        case "No":
//                            shouldRepeat = false
////                        case "None":
////                            shouldRepeat = false
////                        case "Hourly", "Daily", "Weekly":
////                            shouldRepeat = true
//                    default:
//                        break
//                    }
//                }
                
                if let repeatOption = reminder["repeats"] as? String {
                    switch repeatOption {
                    case "None":
                        shouldRepeat = false
                    // TODO: TESTING
                    case "Minute":
                        shouldRepeat = true
                        dateComponents = calendar.dateComponents([.second], from: date)
                    case "Hourly":
                        shouldRepeat = true
                        // Only look at minute to repeat each hour
                        dateComponents = calendar.dateComponents([.minute], from: date)
                    case "Daily":
                        shouldRepeat = true
                        // Only look at minute, hour to repeat each day
                        dateComponents = calendar.dateComponents([.minute, .hour], from: date)
                    case "Weekly":
                        shouldRepeat = true
                        // Only look at minute, hour, day to repeat each week
                        dateComponents = calendar.dateComponents([.minute, .hour, .day], from: date)
                    default:
                        break
                    }
                }
                
//                print("Reminder to schedule should repeat:", shouldRepeat)
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: shouldRepeat)
                let request = UNNotificationRequest(identifier: reminderId, content: content, trigger: trigger)
                center.add(request, withCompletionHandler: { (error) in
                    if error != nil {
                        print("Error adding push notification request:", error!)
                    } else {
                        
                        print("Push notification request added")
                        DispatchQueue.main.async(execute: {
                            self.badgeCount += 1
                            self.updateTabBadge()
                        })
                        
                        print("Should Repeat: \(shouldRepeat)")
                        print("Next repeat: \(trigger.nextTriggerDate())")
                        if shouldRepeat {
                            print("Time before next trigger: \(Date().timeIntervalSince(trigger.nextTriggerDate()!)) seconds --OR-- \(Date().timeIntervalSince(trigger.nextTriggerDate()!)/60) minutes")
                        }
                    }
                })
            })
        } else {
            // Notifications disabled
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
    
    func cancelLocalNotification(_ reminderId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId])
    }
    
    // MARK: - UIPickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return repeatOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return repeatOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        repeatsTF.text = "Repeats - \(repeatOptions[row])"
        repeatsTF.text = "Repeats \(repeatOptions[row])"
        
//        if repeatOptions[row] != "None" {
//            self.datePickerView.datePickerMode = UIDatePickerMode.time
//        } else {
//            self.datePickerView.datePickerMode = UIDatePickerMode.dateAndTime
//        }
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
            print("Show incomplete reminders")
            addReminderTableButton.isHidden = false
        } else if sender.selectedSegmentIndex == 1 {
            // Show completed reminders
            print("Show completed reminders")
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
