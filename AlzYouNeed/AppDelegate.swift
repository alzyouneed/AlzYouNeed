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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    override init() {
        // Firebase init
        FIRApp.configure()
//        FIRDatabase.database().persistenceEnabled = true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Firebase
//        FIRApp.configure()  -- caused crash on launch here
        
        // Remove navigation bar button text
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear], for: UIControlState())
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear], for: UIControlState.highlighted)
        
        // Customize navigation bar appearance
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 20)!]
        
        // Set status bar to light
        UIApplication.shared.statusBarStyle = .lightContent
        
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
//        if let options = launchOptions {
//            if (options[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification) != nil {
////            if let notification = options[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
//                tabBarController.selectedIndex = 2
////                if let userInfo = notification.userInfo {
////                    
////                }
//            }
//        }
        
        
//        let settings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
//        application.registerUserNotificationSettings(settings)
//        application.registerForRemoteNotifications()
        
        
        // Add observer for InstanceID token refresh callback.
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification), name: NSNotification.Name.firInstanceIDTokenRefresh, object: nil)
        
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
    
    // MARK: - Push Notifications
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
    
    // Remote
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
        var tokenString = ""
        
        for i in 0..<deviceToken.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        

        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
//        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.Unknown)
//        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.Prod)
//        print("Device Token:", tokenString)
//        print("FCM Token:", FIRInstanceID.instanceID().token()!)
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
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
    // MARK: - Extra
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("Will resign active") // Log start of call here
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
        print("Did become active") // Log end of call here 
        connectToFcm()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

