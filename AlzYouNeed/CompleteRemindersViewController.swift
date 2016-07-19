//
//  CompleteRemindersViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/18/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class CompleteRemindersViewController: UIViewController, UITableViewDelegate {
    
    // MARK: - UI Elements
    @IBOutlet var remindersTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        
        AYNModel.sharedInstance.completedRemindersArr.removeAll()
        self.remindersTableView.reloadData()
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        // tableView
        remindersTableView.rowHeight = UITableViewAutomaticDimension
        remindersTableView.estimatedRowHeight = 99
    }

    // MARK: - UITableViewDelegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AYNModel.sharedInstance.completedRemindersArr.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:CompleteReminderTableViewCell = tableView.dequeueReusableCellWithIdentifier("completedReminderCell")! as! CompleteReminderTableViewCell
        
        let completedReminder = AYNModel.sharedInstance.completedRemindersArr[indexPath.row]
        
        cell.titleLabel.text = completedReminder.title
        cell.descriptionLabel.text = completedReminder.reminderDescription
        
        // Format readable date
        let date = NSDate(timeIntervalSince1970: Double(completedReminder.dueDate)!)
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        cell.dateLabel.text = dateFormatter.stringFromDate(date)
        
        return cell
    }
}
