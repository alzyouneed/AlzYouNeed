//
//  Person.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class Person: NSObject, NSCoding {
    // MARK: - Properties
    var identifier: String!
    var firstName: String!
    var lastName: String!
    
    // Save image path for more efficient storage and loading
    var photoPath: String!
    var phoneNumber: String!
    
    
    // MARK: - Init
    init(identifier: String, firstName: String, lastName: String?, photo: UIImage?, phoneNumber: String?) {
        super.init()
        self.identifier = identifier
        self.firstName = firstName
        self.lastName = lastName ?? ""
        self.photoPath = ""
        self.phoneNumber = phoneNumber ?? ""
        
        // If there is a photo, save the image using full name
        if photo != nil {
            print("Photo exists -- attempting to save")
            self.photoPath = saveImage(photo!, identifier: identifier)
        }
    }
    
    init(identifier: String, firstName: String, lastName: String?, photoPath: String?, phoneNumber: String?) {
        super.init()
        self.identifier = identifier
        self.firstName = firstName
        self.lastName = lastName ?? ""
        self.photoPath = photoPath ?? ""
        self.phoneNumber = phoneNumber ?? ""
    }
    
    // MARK: - NSCoding
    
    required convenience init(coder aDecoder: NSCoder) {
        let identifier = aDecoder.decodeObjectForKey("identifier") as! String
        let firstName = aDecoder.decodeObjectForKey("firstName") as! String
        let lastName = aDecoder.decodeObjectForKey("lastName") as? String
        let photoPath = aDecoder.decodeObjectForKey("photoPath") as? String
        let phoneNumber = aDecoder.decodeObjectForKey("phoneNumber") as? String
        self.init(identifier: identifier, firstName: firstName, lastName: lastName, photoPath: photoPath, phoneNumber: phoneNumber)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.identifier, forKey: "identifier")
        aCoder.encodeObject(self.firstName, forKey: "firstName")
        aCoder.encodeObject(self.lastName, forKey: "lastName")
        aCoder.encodeObject(self.photoPath, forKey: "photoPath")
        aCoder.encodeObject(self.phoneNumber, forKey: "phoneNumber")
    }
    
    
    // MARK: - Save Image Methods
    
    func saveImage(image: UIImage, identifier: String) -> String {
        print("Saving image")
        let pngImageData = UIImagePNGRepresentation(image)
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir = "\(dirPaths[0] as String)/" // Document directory
        
        let imageName = "\(identifier).png"
        let imagePath = "\(docsDir)\(imageName)"
        
        if pngImageData != nil {
            pngImageData!.writeToFile(imagePath, atomically: true)
        }
        
        // return imageName for loading later
        return imageName
    }

}
