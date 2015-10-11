//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Mayank Kumar on 7/23/15.
//  Copyright © 2015 Mayank Kumar. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var id: String?
    @NSManaged var url: String?
    @NSManaged var downloadStatus: NSNumber?
    @NSManaged var pin: Pin?

}
