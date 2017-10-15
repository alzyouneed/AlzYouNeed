//
//  FirebaseManager.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/24/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class FirebaseManager: NSObject {

    // MARK: - User Management
    class func getCurrentUser(_ completionHandler: @escaping (_ userDict: NSDictionary?, _ error: NSError?) -> Void) {
        if let user = Auth.auth().currentUser {
            let userId = user.uid
            let databaseRef = Database.database().reference()

            databaseRef.child(UserPath).child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
                if let dict = snapshot.value! as? NSDictionary {
                    // Used by UserDefaults to check auth of saved user before loading
                    dict.setValue(snapshot.key, forKey: "userId")

                    // TODO: Fix / remove this
//                    UserDefaultsManager.saveCurrentUser(_user: dict)
//                    AYNModel.sharedInstance.currentUser = dict

                    completionHandler(dict, nil)
                }
                else {
                    // No user to retrieve
                    print("No user found in RTDB")
                    let error = NSError(domain: "UserRTDBErrorDomain", code: 2, userInfo: nil)
                    completionHandler(nil, error)
                }
            }) { (error) in
                print("Error occurred while retrieving current user")
                completionHandler(nil, error as NSError?)
            }
        }
    }

    class func getUserById(_ userId: String, completionHandler: @escaping (_ userDict: NSDictionary?, _ error: NSError?) -> Void) {
        let databaseRef = Database.database().reference()
        databaseRef.child(UserPath).child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dict = snapshot.value! as? NSDictionary {
                 print("User retrieved by ID")
                completionHandler(dict, nil)
            }
            else {
                // No user to retrieve
                print("No user found in RTDB for userId")
                let error = NSError(domain: "UserRTDBErrorDomain", code: 2, userInfo: nil)
                completionHandler(nil, error)
            }
        }) { (error) in
            print("Error occurred while retrieving user by userId")
            completionHandler(nil, error as NSError?)
        }
    }

    class func updateUser(updates: NSDictionary, completionHandler: @escaping (_ error: NSError?) -> Void ){
        if let user = Auth.auth().currentUser {
            let userId = user.uid
            let databaseRef = Database.database().reference()
            let updatesDict = updates as! [AnyHashable: Any]

            databaseRef.child(UserPath).child(userId).updateChildValues(updatesDict, withCompletionBlock: { (error, ref) in
                if let error = error {
                    print("Error updating user: ", error.localizedDescription)
                    completionHandler(error as NSError)
                } else {
                    print("Updated user")
                    completionHandler(nil)
                }
            })
        }
    }

    class func updateUserImage(image: UIImage, completionHandler: @escaping (_ error: NSError?) -> Void) {
        if let user = Auth.auth().currentUser {
            let storageRef = Storage.storage().reference()
            let imagePath = "profileImage/" + user.uid
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpg"

            var imageData = Data()
            imageData = UIImageJPEGRepresentation(image, 0)!

            storageRef.child(imagePath).putData(imageData, metadata: metaData, completion: { (firMetaData, error) in
                if let error = error {
                    print("Error uploading image: ", error.localizedDescription)
                    completionHandler(error as NSError)
                } else {
                    if let firMetaData = firMetaData {
                        if let photoURL = firMetaData.downloadURL() {
                            // Store in User Profile
                            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                            changeRequest?.photoURL = photoURL
                            changeRequest?.commitChanges(completion: { (error) in
                                if let error = error {
                                    print("Error updating photoURL: ", error.localizedDescription)
                                    completionHandler(error as NSError)
                                } else {
                                    print("Updated photoURL")

                                    // Store in RTDB
                                    FirebaseManager.updateUser(updates: ["photoURL" : photoURL.absoluteString] as NSDictionary, completionHandler: { (error) in
                                        if let error = error {
                                            print("Error updating photoURL in RTDB: ", error.localizedDescription)
                                            completionHandler(error)
                                        } else {
                                            print("Updated photoURL in RTDB")
                                            completionHandler(nil)
                                        }
                                    })
                                }
                            })
                        }
                    }
                }
            })
        }
    }

    // MARK: - Family Group Management
    class func createNewFamilyGroup(_ familyId: String, password: String, completionHandler: @escaping (_ error: NSError?, _ newDatabaseRef: DatabaseReference?) -> Void) {
        if let user = Auth.auth().currentUser {
            // Check if family group already exists
            lookUpFamilyGroup(familyId, completionHandler: { (error, familyExists) in
                if error != nil {
                    completionHandler(error, nil)
                } else {
                    if let familyExists = familyExists {
                        if familyExists {
                            // Family exists - don't create new one
                            print("Family name already in use")
                            let error = NSError(domain: "ExistingFamilyGroupError", code: 00001, userInfo: nil)
                            completionHandler(error, nil)
                        } else {
                            // Family name is free
                            let databaseRef = Database.database().reference()
                            let userDict = ["admin" : true]
                            let familyToSave = ["password": password, GroupMembersPath:[user.uid: userDict], "notepad" : "Store your notes here!"] as [String : Any]

                            // Update current user and new family, and signup Status
                            let childUpdates = ["/\(UserPath)/\(user.uid)/groupId": familyId,
                                                "/\(UserPath)/\(user.uid)/admin": "true",
                                                "/\(GroupPath)/\(familyId)": familyToSave] as [String : Any]

                            databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                                if error != nil {
                                    print("Error creating new family group")
                                    completionHandler(error as NSError?, databaseRef)
                                }
                                else {
                                    print("New family group created -- joined Family: \(familyId)")
//                                    AYNModel.sharedInstance.currentUser = modifiedDict
                                    completionHandler(error as NSError?, databaseRef)
                                }
                            })
                        }
                    }
                }
            })
        }
    }

    class func joinFamilyGroup(_ familyId: String, password: String, completionHandler: @escaping (_ error: NSError?, _ newDatabaseRef: DatabaseReference?) -> Void) {
        if let user = Auth.auth().currentUser {
            lookUpFamilyGroup(familyId, completionHandler: { (error, familyExists) in
                if error != nil {
                    completionHandler(error, nil)
                } else {
                    if let familyExists = familyExists {
                        if familyExists {
                            // Family exists -- check password
                            getFamilyPassword(familyId, completionHandler: { (familyPassword, error) in
                                if error != nil {
                                    completionHandler(error, nil)
                                } else {
                                    if let familyPassword = familyPassword {
                                        // Compare password to user input
                                        if password == familyPassword {
                                            // Password correct
                                            let databaseRef = Database.database().reference()
                                            let userDict = ["admin" : false]
                                            // Update current user and new family, and signUp status
                                            let childUpdates = ["/\(UserPath)/\(user.uid)/groupId": familyId,
                                                                "/\(UserPath)/\(user.uid)/admin": "false"]

                                            databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                                                if error != nil {
                                                    print("Error occurred while updating user with new family group values")
                                                    completionHandler(error as NSError?, nil)
                                                }
                                                else {
                                                    print("User family group values updated")
                                                    databaseRef.child(GroupPath).child(familyId).child(GroupMembersPath).child(user.uid).setValue(userDict, withCompletionBlock: { (secondError, secondDatabaseRef) in
                                                        if error != nil {
                                                            print("Error occurred while adding user to family")
                                                            completionHandler(secondError as NSError?, secondDatabaseRef)
                                                        }
                                                        else {
                                                            print("User added to family")
//                                                            AYNModel.sharedInstance.currentUser = userDict
                                                            completionHandler(nil, secondDatabaseRef)
                                                        }
                                                    })
                                                }
                                            })
                                        } else {
                                            // Password incorrect
                                            print("Incorrect password to join family: \(familyId)")
                                            let wrongPasswordError = NSError(domain: "Incorrect password", code: 3, userInfo: nil)
                                            completionHandler(wrongPasswordError, nil)
                                        }
                                    }
                                }
                            })
                        } else {
                            // Family does not exist
                            print("Family does not exist")
                            let familyError = NSError(domain: "familyIdError", code: 00004, userInfo: nil)
                            completionHandler(familyError, nil)
                        }
                    }
                }
            })
        }
    }

    // Helper functions
    class func lookUpFamilyGroup(_ familyId: String, completionHandler: @escaping (_ error: NSError?, _ familyExists: Bool?) -> Void) {
        let databaseRef = Database.database().reference()

        databaseRef.child(GroupPath).observeSingleEvent(of: .value, with: { (snapshot) in
            if let groupExists = snapshot.hasChild(familyId) as Bool? {
                print("Family group exists: \(groupExists)")
                completionHandler(nil, groupExists)
            }
        }) { (error) in
            print("Family group error:", error)
            completionHandler(error as NSError?, nil)
        }
    }

    class func getFamilyPassword(_ familyId: String, completionHandler: @escaping (_ password: String?, _ error: NSError?) -> Void) {
        let databaseRef = Database.database().reference()

        databaseRef.child(GroupPath).child(familyId).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dict = snapshot.value as? NSDictionary, let familyPassword = dict["password"] as? String {
            // if let familyPassword = snapshot.value!["password"] as? String {  SWIFT 3 CHANGE
                print("Family password retrieved")
                completionHandler(familyPassword, nil)
            }
        }) { (error) in
            print("Error occurred while retrieving family password")
            completionHandler(nil, error as NSError?)
        }
    }

    class func getFamilyMembers(_ completionHandler: @escaping (_ members: [Contact]?, _ error: NSError?) -> Void) {
        if let user = Auth.auth().currentUser{

//            if AYNModel.sharedInstance.currentUser != nil {
                let userId = user.uid
                // Search for members using current user's familyId
                if let groupId = AYNModel.sharedInstance.groupId {
//                if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let databaseRef = Database.database().reference()
                    var membersArr = [Contact]()

                    databaseRef.child(GroupPath).child(groupId).child(GroupMembersPath).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let dict = snapshot.value! as? NSDictionary {
                            for (key, value) in dict {
                                if let uId = key as? String {
                                    // Prevent adding current user to array
                                    if uId != userId {
                                        if let memberDict = value as? NSDictionary {
                                            if let contact = Contact(userId: uId, userDict: memberDict) {
                                                membersArr.append(contact)
                                            }
                                        }
                                    }
                                }
                            }
                            print("Family members retrieved")
                            completionHandler(membersArr, nil)
                        }
                    }) { (error) in
                        print("Error occurred while retrieving family members")

                    }
                }
//            }
        }
    }

    // Custom UserInfo unique to each familyMember's instance of their relationship to others
    class func updateFamilyMemberUserInfo(_ contactUserId: String, updates: NSDictionary, completionHandler: @escaping (_ error: NSError?) -> Void) {
        if let user = Auth.auth().currentUser {
            if AYNModel.sharedInstance.currentUser != nil {
                if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let userId = user.uid
                    let databaseRef = Database.database().reference()

                    let updatesDict = updates as! [AnyHashable: Any]

                    databaseRef.child(GroupPath).child(userFamilyId).child(GroupMembersPath).child(userId).child("communicationInfo").child(contactUserId).updateChildValues(updatesDict, withCompletionBlock: { (error, newRef) in
                        if error != nil {
                            // Error
                            print("Error updating family member userInfo")
                            completionHandler(error as NSError?)
                        }
                        else {
                            // Success
                            print("Updated family member userInfo")
                            completionHandler(nil)
                        }
                    })
                }
            }
        }
    }

    class func getFamilyMemberUserInfo(_ contactUserId: String, completionHandler: @escaping (_ error: NSError?, _ userInfo: NSDictionary?) -> Void) {
        if let user = Auth.auth().currentUser {
            if AYNModel.sharedInstance.currentUser != nil {
                if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let userId = user.uid
                    let databaseRef = Database.database().reference()

                    databaseRef.child(GroupPath).child(userFamilyId).child(GroupMembersPath).child(userId).child("communicationInfo").child(contactUserId).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let dict = snapshot.value! as? NSDictionary {
                            print("Retrieved family member userInfo")
                            completionHandler(nil, dict)
                        }
                    }) { (error) in
                        print("Error retrieving family member userInfo")
                        completionHandler(error as NSError?, nil)
                    }
                }
            }
        }
    }

    // MARK: - Reminders
    class func createFamilyReminder(_ reminder: NSDictionary, completionHandler: @escaping (_ error: NSError?, _ newDatabaseRef: DatabaseReference?) -> Void) {
        if let groupId = AYNModel.sharedInstance.groupId {
            let databaseRef = Database.database().reference()

            databaseRef.child(GroupPath).child(groupId).child("reminders").childByAutoId().setValue(reminder, withCompletionBlock: { (error, newDatabaseRef) in
                if error != nil {
                    // Error
                    print("Error creating reminder")
                    completionHandler(error as NSError?, nil)
                }
                else {
                    // Success
                    print("Created new family reminder")
                    completionHandler(nil, newDatabaseRef)
                }
            })
        }
    }

    class func deleteFamilyReminder(_ reminderId: String, completionHandler: @escaping (_ error: NSError?, _ newDatabaseRef: DatabaseReference?) -> Void) {
        if let groupId = AYNModel.sharedInstance.groupId {
            let databaseRef = Database.database().reference()

            databaseRef.child(GroupPath).child(groupId).child("reminders").child(reminderId).removeValue(completionBlock: { (error, oldRef) in
                if error != nil {
                    print("Error deleting reminder")
                    completionHandler(error as NSError?, nil)
                }
                else {
                    print("Reminder deleted")
                    completionHandler(nil, oldRef)
                }
            })
        }
    }

    class func completeFamilyReminder(_ reminder: Reminder, completionHandler: @escaping (_ error: NSError?, _ newDatabaseRef: DatabaseReference?) -> Void) {
        if let groupId = AYNModel.sharedInstance.groupId {
            let databaseRef = Database.database().reference()

            var modifiedReminderDict = reminder.asDict()

            modifiedReminderDict["completedDate"] = Date().timeIntervalSince1970.description

            let childUpdates = ["/groups/\(groupId)/completedReminders/\(reminder.id!)": modifiedReminderDict]

            databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                if error != nil {
                    print("Error occurred while marking reminder as complete")
                    completionHandler(error as NSError?, nil)
                }
                else {
                    print("Reminder completed -- deleting from old location")
                    deleteFamilyReminder(reminder.id, completionHandler: { (error, newDatabaseRef) in
                        if error != nil {
                            completionHandler(error, nil)
                        }
                        else {
                            completionHandler(nil, newDatabaseRef)
                        }
                    })
                }
            })
        }
    }

    class func getCompletedFamilyReminders(_ completionHandler: @escaping (_ completedReminders: [Reminder]?, _ error: NSError?) -> Void) {
        if let groupId = AYNModel.sharedInstance.groupId {
            let databaseRef = Database.database().reference()
            var remindersArr = [Reminder]()

            databaseRef.child(GroupPath).child(groupId).child("completedReminders").observeSingleEvent(of: .value, with: { (snapshot) in
                if let dict = snapshot.value! as? NSDictionary {
                    for (key, value) in dict {
                        if let reminderId = key as? String {
                            if let reminderDict = value as? NSDictionary {
                                if let completedReminder = Reminder(reminderId: reminderId, reminderDict: reminderDict) {
                                    remindersArr.append(completedReminder)
                                }
                            }
                        }
                    }
                    print("Completed reminders retrieved")
                    completionHandler(remindersArr, nil)
                }
            }) { (error) in
                print("Error occurred while retrieving completed reminders")

            }
        }
    }

    // MARK: - Messages
    class func sendNewMessage(_ receiverId: String, conversationId: String, message: NSDictionary, completionHandler: @escaping (_ error: NSError?) -> Void) {
        if let user = Auth.auth().currentUser {
            if let groupId = AYNModel.sharedInstance.groupId {
//                if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let databaseRef = Database.database().reference()
                    let messageKey = databaseRef.child(GroupPath).child(groupId).child("conversations").child(conversationId).childByAutoId().key

                    // Add current user ID to message object
                    let modifiedMessage = message.mutableCopy() as! NSMutableDictionary
                    modifiedMessage.setObject(user.uid, forKey: "senderId" as NSCopying)

                    let favoritedDict = [user.uid : "false", receiverId : "false"]
                    modifiedMessage.setObject(favoritedDict, forKey: "favorited" as NSCopying)

                    databaseRef.child(GroupPath).child(groupId).child("conversations").child(conversationId).child(messageKey).setValue(modifiedMessage, withCompletionBlock: { (error, newDatabaseRef) in
                        if error != nil {
                            // Error
                            print("Error sending message")
                            completionHandler(error as NSError?)
                        }
                        else {
                            // Success
                            print("Sent new message")
                            completionHandler(nil)
                        }
                    })
//                }
            }
        }
    }

    class func favoriteMessage(_ conversationId: String, messageId: String, favorited: String, completionHandler: @escaping (_ error: NSError?) -> Void) {
        if let user = Auth.auth().currentUser {
            if AYNModel.sharedInstance.currentUser != nil {
                if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                    let databaseRef = Database.database().reference()

                    let childUpdates = [user.uid : favorited]
                    databaseRef.child(GroupPath).child(userFamilyId).child("conversations").child(conversationId).child(messageId).updateChildValues(childUpdates, withCompletionBlock: { (error, newDatabaseRef) in
                        if let error = error {
                            // Error
                            print("Error updating favorite value for message")
                            completionHandler(error as NSError?)
                        } else {
                            // Success
                            print("Updated favorite value for message")
                            completionHandler(nil)
                        }
                    })
                }
            }
        }
    }

    class func getConversationId(_ familyId: String, receiverId: String, completionHandler: @escaping (_ error: NSError?, _ conversationId: String?) -> Void) {
        if (Auth.auth().currentUser) != nil {
//            if AYNModel.sharedInstance.currentUser != nil {
                // Get list of current user's conversations (by ID)
                // Must use getCurrentUser to ensure most up-to-date information (newly created conversations)
                getCurrentUser({ (userDict, error) in
                    if error != nil {
                        completionHandler(error, nil)
                    } else {
                        if let userDict = userDict {
                            if let senderConversations = userDict.object(forKey: "conversations") as? NSDictionary {
                                //                            if let senderConversations = AYNModel.sharedInstance.currentUser?.object(forKey: "conversations") as? NSDictionary {
                                // Lookup receiver
                                getUserById(receiverId, completionHandler: { (userDict, error) in
                                    if let error = error {
                                        // Error
                                        completionHandler(error, nil)
                                    } else {
                                        // Get list of receiver's conversations (by ID)
                                        if let receiverConversations = userDict?.object(forKey: "conversations") as? NSDictionary {
                                            let senderConversationKeys = senderConversations.allKeys
                                            // Iterate through each key of sender to find matching conversation ID
                                            for key in senderConversationKeys {
                                                if receiverConversations.object(forKey: key) != nil {
                                                    //                                                print("Sender keys: \(senderConversationKeys)")
                                                    // Found matching conversation ID for both users
                                                    if let conversationId = key as? String {
                                                        print("Found existing conversation ID for users")
                                                        completionHandler(nil, conversationId)
                                                        return
                                                    }
                                                }
                                            }
                                            // No matching conversation ID found
                                            print("Could not find matching conversation ID for users -- creating new conversation")
                                            // Create ID here
                                            createNewConversation(receiverId, familyId: familyId, completionHandler: { (error, conversationId) in
                                                if let error = error {
                                                    // Error
                                                    completionHandler(error, nil)
                                                } else {
                                                    // Success
                                                    completionHandler(nil, conversationId)
                                                }
                                            })
                                        } else {
                                            // Receiver has no saved conversations
                                            print("Receiver has no saved conversations -- creating new conversation")
                                            // Create ID here
                                            createNewConversation(receiverId, familyId: familyId, completionHandler: { (error, conversationId) in
                                                if let error = error {
                                                    // Error
                                                    completionHandler(error, nil)
                                                } else {
                                                    // Success
                                                    completionHandler(nil, conversationId)
                                                }
                                            })
                                        }
                                    }
                                })
                            } else {
                                // Sender has no saved conversations
                                print("Sender has no saved conversations -- creating new conversation")
                                // Create ID here
                                createNewConversation(receiverId, familyId: familyId, completionHandler: { (error, conversationId) in
                                    if let error = error {
                                        // Error
                                        completionHandler(error, nil)
                                    } else {
                                        // Success
                                        completionHandler(nil, conversationId)
                                    }
                                })
                            }
                        }
                    }
                })
//            }
        }
    }

    fileprivate class func createNewConversation(_ receiverId: String, familyId: String, completionHandler: @escaping (_ error: NSError?, _ conversationId: String?) -> Void) {
        if let user = Auth.auth().currentUser {
            let databaseRef = Database.database().reference()
            let newConversationId = databaseRef.child(GroupPath).child(familyId).child("conversations").childByAutoId().key

            let childUpdates = ["/users/\(user.uid)/conversations/\(newConversationId)": "true",
                                "/users/\(receiverId)/conversations/\(newConversationId)": "true"] as [AnyHashable: Any]

            databaseRef.updateChildValues(childUpdates, withCompletionBlock: { (error, databaseRef) in
                if error != nil {
                    print("Error adding users to new conversation")
                    completionHandler(error as NSError?, nil)
                }
                else {
                    print("Created new conversation with users")
                    completionHandler(nil, newConversationId)
                }
            })
        }
    }

}

extension FirebaseManager {

    class func getFamilyNote(completionHandler: @escaping (_ error: NSError?, _ familyNoteData: [String:String]?) -> Void) {
        if let user = Auth.auth().currentUser, let groupId = AYNModel.sharedInstance.groupId {
            let databaseRef = Database.database().reference()

            databaseRef.child(GroupPath).child(groupId).child("notepad").observeSingleEvent(of: .value, with: { (snapshot) in
                if let familyNote = snapshot.value as? [String:String] {
                    print("Retrieved group note")
                    completionHandler(nil, familyNote)
                }
                else {
                    let firstNote = "Store your notes here!"
                    let name = user.displayName?.components(separatedBy: " ").first
                    let firstNoteData = ["notepad": ["note": firstNote, "lastChangedUser":user.uid, "lastChangedName": name]]

                    databaseRef.child(GroupPath).child(groupId).updateChildValues(firstNoteData, withCompletionBlock: { (error, newRef) in
                        //                        databaseRef.child(GroupPath).child(userFamilyId).child("notepad").updateChildValues(familyNote, withCompletionBlock: { (error, newRef) in
                        if error != nil {
                            // Error
                            print("Error saving first note")
                            completionHandler(error as NSError?, nil)
                        }
                        else {
                            // Success
                            print("Saved first note")
                            completionHandler(nil, ["note": firstNote, "lastChangedUser":user.uid, "lastChangedName": name!])
                        }
                    })
                }
            }) { (error) in
                print("Error retrieving group note:", error)
                completionHandler(error as NSError?, nil)
            }
        }

    }

    class func saveFamilyNote(_changes: String, completionHandler: @escaping (_ error: NSError?) -> Void) {
        if let user = Auth.auth().currentUser {
            let groupId = AYNModel.sharedInstance.groupId!
            let databaseRef = Database.database().reference()
            let name = user.displayName?.components(separatedBy: " ").first

            databaseRef.child(GroupPath).child(groupId).updateChildValues(["notepad": ["note": _changes, "lastChangedUser":user.uid, "lastChangedName": name]], withCompletionBlock: { (error, newRef) in
                if error != nil {
                    // Error
                    print("Error saving note")
                    completionHandler(error as NSError?)
                }
                else {
                    // Success
                    print("Saved note")
                    completionHandler(nil)
                }
            })
        }
    }
}
