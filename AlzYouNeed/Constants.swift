//
//  Constants.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/15/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

// MARK: - Firebase
let UserPath = "users"
let FamilyPath = "families"
let GroupPath = "groups" // TODO: Switch this out for FamilyPath
let GroupMembersPath = "members"

// MARK: - New Palette
let ivory = UIColor(red: 255/255, green: 255/255, blue: 243/255, alpha: 1)
let sunsetOrange = UIColor(red: 254/255, green: 95/255, blue: 85/255, alpha: 1)
let stormCloud = UIColor(red: 79/255, green: 99/255, blue: 103/255, alpha: 1)
let caribbeanGreen = UIColor(red: 6/255, green: 214/255, blue: 160/255, alpha: 1)
let slateBlue = UIColor(red: 136/255, green: 132/255, blue: 255/255, alpha: 1)
let columbiaBlue = UIColor(red: 208/255, green: 219/255, blue: 226/255, alpha: 1)
let crayolaYellow = UIColor(red: 255/255, green: 182/255, blue: 39/255, alpha: 1)

enum Tutorials: String {
    case notepad
    case contactList
    case reminders
}

// MARK: - NSNotification Keys
let signInNotificationKey = "com.alzyouneed.signInNotificationKey"
let googleSignInFailedKey = "com.alzyouneed.googleSignInFailedKey"
