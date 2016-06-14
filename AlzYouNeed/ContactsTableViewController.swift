//
//  ContactsTableViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

class ContactsTableViewController: UITableViewController, CNContactPickerDelegate {
    
    var userContacts: [Person] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactsTableViewController.insertNewObject(_:)), name: "addNewContact", object: nil)
        
//        getContacts()
        
        loadContacts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Logic
    
    func loadContacts() {
        userContacts.removeAll()
        userContacts = UserDefaultsManager.getAllContacts()!
        self.tableView.reloadData()
        
        print("Loaded \(userContacts.count) contacts from UserDefaults")
    }
    
    func getContacts() {
        let store = CNContactStore()
        
        // Check if use of contacts is authorized
        if CNContactStore.authorizationStatusForEntityType(.Contacts) == .NotDetermined {
            store.requestAccessForEntityType(.Contacts, completionHandler: { (authorized: Bool, error: NSError?) in
                if authorized {
//                    self.retrieveContactsWithStore(store)
                }
            })
        }
        // Immediately retrieve contacts
        else if CNContactStore.authorizationStatusForEntityType(.Contacts) == .Authorized {
//            self.retrieveContactsWithStore(store)
        }
    }
    
    func retrieveContactsWithStore(store: CNContactStore) {
        do {
            // Predicate matches all groups
            let groups = try store.groupsMatchingPredicate(nil)
            let predicate = CNContact.predicateForContactsInGroupWithIdentifier(groups[0].identifier)
            
            let keysToFetch = [CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName), CNContactEmailAddressesKey, CNContactPhoneNumbersKey, CNContactImageDataAvailableKey, CNContactImageDataKey]
            
            let contacts = try store.unifiedContactsMatchingPredicate(predicate, keysToFetch: keysToFetch)
            
            userContacts.removeAll()
            
            for contact in contacts {
//                let person = Person(identifier: contact.identifier, firstName: contact.givenName, lastName: contact.familyName, photoPath: "", phoneNumber: (contact.phoneNumbers[0].value as! CNPhoneNumber).stringValue)
                
                // Create image for saving (if one exists)
                var contactImage = UIImage()
                if contact.imageDataAvailable {
                    if let data = contact.imageData {
                        contactImage = UIImage(data: data)!
                    }
                }
                let person = Person(identifier: contact.identifier, firstName: contact.givenName, lastName: contact.familyName, photo: contactImage, phoneNumber: (contact.phoneNumbers[0].value as! CNPhoneNumber).valueForKey("digits") as? String)
                
//                let person = Person(identifier: contact.identifier, firstName: contact.givenName, lastName: contact.familyName, photoPath: "", phoneNumber: (contact.phoneNumbers[0].value as! CNPhoneNumber).valueForKey("digits") as? String)
                userContacts.append(person)
                
//                print("NUMBER: \((contact.phoneNumbers[0].value as! CNPhoneNumber).valueForKey("digits") as! String)")
            }
            
            // Update tableview on main thread
            dispatch_async(dispatch_get_main_queue(), { 
                self.tableView.reloadData()
            })
        }
        catch {
            print(error)
        }
    }
    
    func addExistingContact() {
        let contactPicker = CNContactPickerViewController()
        
        // Only search contacts with phoneNumbers
        contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0", argumentArray: nil)
        contactPicker.delegate = self
        self.presentViewController(contactPicker, animated: true, completion: nil)
    }
    
    @IBAction func addExisting(sender: AnyObject) {
        addExistingContact()
    }
    
    
    // MARK: - CNContactPickerDelegate
    
    func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
        NSNotificationCenter.defaultCenter().postNotificationName("addNewContact", object: nil, userInfo: ["contactToAdd": contact])
    }
    
    func insertNewObject(sender: NSNotification) {
        if let contact = sender.userInfo?["contactToAdd"] as? CNContact {
            
            // Check that contact does not already exist
            if !UserDefaultsManager.contactExists(contact.identifier) {
                var contactImage = UIImage()
                // Check for contact image
                if contact.imageDataAvailable {
                    if let data = contact.imageData {
                        contactImage = UIImage(data: data)!
                    }
                }
                
                // Create new person using contact
                let person = Person(identifier: contact.identifier, firstName: contact.givenName, lastName: contact.familyName, photo: contactImage, phoneNumber: (contact.phoneNumbers[0].value as! CNPhoneNumber).valueForKey("digits") as? String)
                
//                print("Inserting new object: \(person.identifier), \(person.firstName) \(person.lastName), \(person.phoneNumber)")
                
                // Add contact to local array
                userContacts.append(person)
                // Save to defaults
                UserDefaultsManager.saveContact(person)
            
                let indexPath = NSIndexPath(forRow: userContacts.count-1, inSection: 0)
                self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
            else {
                print("Contact already exists")
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return userContacts.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("contactCell", forIndexPath: indexPath)

        let contact = userContacts[indexPath.row]
        
        cell.textLabel?.text = "\(contact.firstName) \(contact.lastName)"
        cell.detailTextLabel?.text = "\(contact.phoneNumber)"

        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let contactObject = userContacts[indexPath.row]
                let controller = segue.destinationViewController as! ContactDetailViewController
//                controller.contactItem = contactObject
                controller.person = contactObject
//                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
//                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    
    // MARK: - Unused
    
    /*
        func addNewGroup() {
            if !checkExistingGroups("Family - Alz You Need") {
                print("Creating Family group")
    
                let store = CNContactStore()
    
                let familyGroup = CNMutableGroup()
                familyGroup.name = "Family - Alz You Need"
                let saveRequest = CNSaveRequest()
                saveRequest.addGroup(familyGroup, toContainerWithIdentifier: nil)
    
                do {
                    try store.executeSaveRequest(saveRequest)
                    print("Adding new group")
                }
                catch {
                    print(error)
                }
            }
            else {
                print("Family group exists")
            }
        }
    
        func checkExistingGroups(group: String) -> Bool {
            do {
                let store = CNContactStore()
                let groups = try store.groupsMatchingPredicate(nil)
                let filteredGroups = groups.filter {
                    $0.name == "\(group)"
                }
    
                guard let checkedGroup = filteredGroups.first else {
                    print("No \(group) group")
                    return false
                }
    
                let predicate = CNContact.predicateForContactsInGroupWithIdentifier(checkedGroup.identifier)
                let keysToFetch = [CNContactGivenNameKey]
                let contacts = try store.unifiedContactsMatchingPredicate(predicate, keysToFetch: keysToFetch)
    
                print(contacts)
                return true
            }
            catch {
                print(error)
                return false
            }
        }
    
        func saveContactInGroup(contact: CNContact) {
            let store = CNContactStore()
            print(contact.phoneNumbers[0].value)
            
            // Create copy of contact to update
            var newContact = contact.mutableCopy() as! CNMutableContact
            
        }
    */
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */


}
