//
//  AppDelegate.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/11/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import Fabric
import Crashlytics
import GoogleSignIn
import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var window: UIWindow?
    var ref: FIRDatabaseReference!

    override init() {
        super.init()
        // Firebase init
        FIRApp.configure()
        ref = FIRDatabase.database().reference()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Google Sign-in
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        // Configure Facebook Sign-in
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Configure Firebase
//        FIRApp.configure()  -- caused crash on launch here
//        FIRDatabase.database().persistenceEnabled = true
        
        // Remove navigation bar button text
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear], for: UIControlState())
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear], for: UIControlState.highlighted)
        
        // Customize navigation bar appearance
//        UINavigationBar.appearance().tintColor = UIColor.white
//        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 20)!]
        
        // Set status bar to light
//        UIApplication.shared.statusBarStyle = .lightContent
        
        // Customize tab bar appearance
        UITabBar.appearance().tintColor = slateBlue
        UITabBar.appearance().barTintColor = UIColor.white
        
        // Set initial tab bar
        let tabBarController = self.window?.rootViewController as! UITabBarController
        tabBarController.selectedIndex = 1
        
        // Get new reminders
//        let tabArray = tabBarController.tabBar.items as NSArray!
//        let tabItem = tabArray.objectAtIndex(2) as! UITabBarItem
//        tabItem.badgeValue = "8"
        
        // Local reminders
        if UserDefaultsManager.getNotificationStatus() {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if let error = error {
                    print("Error:", error)
                } else {
                    if granted {
                        print("Authorization successful")
                        center.delegate = self
                    }
                }
            }
        }
        
        
        // Add observer for InstanceID token refresh callback.
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification), name: NSNotification.Name.firInstanceIDTokenRefresh, object: nil)
        
        setupNotifications()
        Fabric.with([Crashlytics.self])

        return true
    }
    
    func printAllFonts() {
        let fontFamilyNames = UIFont.familyNames
        for familyName in fontFamilyNames {
            print("------------------------------")
            print("Font Family Name = [\(familyName)]")
            let names = UIFont.fontNames(forFamilyName: familyName)
            print("Font Names = [\(names)]")
        }
    }
   
    // MARK: - Sign-in Methods
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if(url.scheme!.isEqual("fb1684045731890215")) {
            print("Open URL: Facebook")
            let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            return handled
            
        } else {
            print("Open URL: Google")
            return GIDSignIn.sharedInstance().handle(url as URL!,
                                                     sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!,
                                                     annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            print("Error signing in with Google: \(error.localizedDescription)")
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (firebaseUser, error) in
            if let error = error {
                print("Error signing in with Google in FIRAuth: \(error.localizedDescription)")
                return
            }
            print("Signed in with Google")

            // Notify MethodsVC that sign-in was successful
            NotificationCenter.default.post(name: Notification.Name(rawValue: signInNotificationKey), object: self)
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
    // MARK: - Push Notifications
    /*
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != UIUserNotificationType() {
            application.registerForRemoteNotifications()
        }
    }
    
    // Local
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
//        let tabBarController = self.window?.rootViewController as! UITabBarController
//        tabBarController.selectedIndex = 2
        if let userInfo = notification.userInfo {
            print("userInfo: \(userInfo)")
        }
    }
   */
    
    // Remote
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
//        var tokenString = ""
//        
//        for i in 0..<deviceToken.count {
//            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
//        }
////        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
//        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.prod)
        
        // Convert token to string
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        // Print it to console
        print("APNs device token: \(deviceTokenString)")
        
        // Persist it in your backend in case it's new
        if let currentUserId = FIRAuth.auth()?.currentUser?.uid {
            if ref != nil {
                
                // See if device token updated
                if let savedDeviceToken = UserDefaultsManager.getDeviceToken() {
                    
                    if deviceTokenString != savedDeviceToken {
                        print("New device token")
                        UserDefaultsManager.saveDeviceToken(token: deviceTokenString)
                        
                        // New device token
                        self.ref.child("users").child(currentUserId).updateChildValues(["deviceToken":deviceTokenString])
                        
                        if let familyName = AYNModel.sharedInstance.currentUser?["familyId"] as? String {
                            // Update token in Firebase
                            self.ref.child("families").child(familyName).child("members").child(currentUserId).updateChildValues(["deviceToken":deviceTokenString])
                        }
                    }
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register remote notifications:", error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
//        print("Message ID: \(userInfo["gcm.message_id"]!)")
        
        // Print full message.
//        print("%@", userInfo)
        completionHandler(.newData)
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        
        // Prevent crashing from unwrapping possible nil value
        guard let refreshedToken = FIRInstanceID.instanceID().token() else { return }
        print("InstanceID token: \(refreshedToken)")
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    
    func connectToFcm() {
        FIRMessaging.messaging().connect { (error) in
            if (error != nil) {
                print("Unable to connect with FCM. \(String(describing: error))")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
    // MARK: - Extra
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//        print("Will resign active") // Log start of call here
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        FIRMessaging.messaging().disconnect()
        print("Disconnected from FCM.")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        print("Did become active") // Log end of call here 
        connectToFcm()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

// MARK: - Push Notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func setupNotifications() {
        let action = UNNotificationAction(identifier: "snooze", title: "Snooze", options: [])
        let category = UNNotificationCategory.init(identifier: "reminderCategory", actions: [action], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification center did receive response")
        if response.actionIdentifier == "snooze" {
            print("Snooze action")
            let newTrigger = UNTimeIntervalNotificationTrigger(timeInterval: (5*60), repeats: false)
            let oldRequest = response.notification.request
            
            let newRequest = UNNotificationRequest(identifier: oldRequest.identifier, content: oldRequest.content, trigger: newTrigger)

            let center = UNUserNotificationCenter.current()
            center.add(newRequest, withCompletionHandler: { (error) in
                if error != nil {
                    print("Error adding push notification request:", error!)
                } else {
                    print("Push notification request added")
                    completionHandler()
                }
            })
        }
    }
}

