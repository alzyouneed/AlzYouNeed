//
//  AppDelegate.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/11/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Configure Firebase
        FIRApp.configure()
        
//        FIRDatabase.database().persistenceEnabled = true
        
        // Remove navigation bar button text
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clearColor()], forState: UIControlState.Normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clearColor()], forState: UIControlState.Highlighted)
        
        // Customize navigation bar appearance
        UINavigationBar.appearance().barTintColor = backgroundPurple
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 20)!]
        
        // Set status bar to light
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        // Customize tab bar appearance
        UITabBar.appearance().tintColor = UIColor.whiteColor()
        UITabBar.appearance().barTintColor = deepSpaceSparkle
        
        // Set initial tab bar
        let tabBarController = self.window?.rootViewController as! UITabBarController
        tabBarController.selectedIndex = 1
        
        // Get new reminders
        let tabArray = tabBarController.tabBar.items as NSArray!
        let tabItem = tabArray.objectAtIndex(2) as! UITabBarItem
        tabItem.badgeValue = "8"
        
//        printAllFonts()
        
        return true
    }
    
    func printAllFonts() {
        let fontFamilyNames = UIFont.familyNames()
        for familyName in fontFamilyNames {
            print("------------------------------")
            print("Font Family Name = [\(familyName)]")
            let names = UIFont.fontNamesForFamilyName(familyName)
            print("Font Names = [\(names)]")
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("Will resign active") // Log start of call here
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("Did become active") // Log end of call here 
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

