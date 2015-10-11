//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Mayank Kumar on 7/23/15.
//  Copyright © 2015 Mayank Kumar. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
class Pin: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.longitude = longitude
        self.latitude = latitude
    }
}
