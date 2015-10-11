//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Mayank Kumar on 7/23/15.
//  Copyright © 2015 Mayank Kumar. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
class Photo: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.id = dictionary["id"] as? String
        self.url = dictionary["url_m"] as? String
        self.downloadStatus = false
    }
}
