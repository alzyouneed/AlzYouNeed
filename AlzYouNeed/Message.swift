//
//  Message.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/25/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class Message: NSObject {
    var messageId: String!
    var senderId: String!
    var dateSent: String!
    var messageString: String!
    
    init?(messageId: String, messageDict: NSDictionary) {
        super.init()
        
        self.messageId = messageId
        self.senderId = messageDict.objectForKey("senderId") as? String ?? ""
        self.dateSent = messageDict.objectForKey("timestamp") as? String ?? ""
        self.messageString = messageDict.objectForKey("messageString") as? String ?? ""
    }
    
    override var description: String {
        return "messageId: \(messageId) -- senderId: \(senderId) -- dateSent: \(dateSent) -- messageString: \(messageString)"
    }
}
