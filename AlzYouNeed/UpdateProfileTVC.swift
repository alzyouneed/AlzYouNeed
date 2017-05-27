//
//  UpdateProfileTVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/27/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit
import PKHUD
import SkyFloatingLabelTextField
import Firebase

class UpdateProfileTVC: UITableViewController {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var notificationSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupView() {
        setupUserImageView()
        setupNameLabel()
        setupNotificationSwitch()
    }
    
    func setupUserImageView() {
        userImageView.layer.masksToBounds = false
        userImageView.layer.cornerRadius = self.userImageView.frame.height/2
        userImageView.clipsToBounds = true
//        userImageView.layer.borderWidth = 2
//        userImageView.layer.borderColor = UIColor.white.cgColor
//        userImageView.layer.borderColor = UIColor(hex: "7189FF").cgColor
        
        if let userImage = AYNModel.sharedInstance.userImage {
            userImageView.image = userImage
        }
    }
    
    func setupNameLabel() {
        if let user = FIRAuth.auth()?.currentUser {
            self.nameLabel.text = user.displayName?.components(separatedBy: " ").first
        }
    }
    
    func setupNotificationSwitch() {
        if UIApplication.shared.isRegisteredForRemoteNotifications {
            notificationSwitch.isOn = true
            print("TRUE")
        } else {
            notificationSwitch.isOn = false
            print("FALSE")
        }
    }

    @IBAction func changePicturePressed(_ sender: UIButton) {
        
    }
    
    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
