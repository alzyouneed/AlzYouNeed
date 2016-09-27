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
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        self.tabBarController?.tabBar.isHidden = true
        
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
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AYNModel.sharedInstance.completedRemindersArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell:CompleteReminderTableViewCell = tableView.dequeueReusableCell(withIdentifier: "completedReminderCell")! as! CompleteReminderTableViewCell
        
        let completedReminder = AYNModel.sharedInstance.completedRemindersArr[(indexPath as NSIndexPath).row]
        
        cell.titleLabel.text = completedReminder.title
        cell.descriptionLabel.text = completedReminder.reminderDescription
        
        // Format readable date
        let date = Date(timeIntervalSince1970: Double(completedReminder.completedDate)!)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, h:mm a"
        cell.dateLabel.text = "Completed \(dateFormatter.string(from: date))"
        
        return cell
    }
}
