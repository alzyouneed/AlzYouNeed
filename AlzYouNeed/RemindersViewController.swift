//
//  RemindersViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/9/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class RemindersViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let now = NSDate()
        let newReminder = Reminder(reminderTitle: "New task", reminderDescription: "Do this task soon please", reminderDueDate: now.description)
        FirebaseManager.createFamilyReminder(newReminder, completionHandler: { (error, newDatabaseRef) in
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        FirebaseManager.getFamilyReminders { (error, reminders) in
            print("Reminders: \(reminders)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
