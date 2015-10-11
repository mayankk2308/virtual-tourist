//
//  ImagePersistence.swift
//  Virtual Tourist
//
//  Created by Mayank Kumar on 7/23/15.
//  Copyright © 2015 Mayank Kumar. All rights reserved.
//

import Foundation
import UIKit

class ImagePersistence: NSObject {
    
    //save image to disk
    func storeImage(image: UIImage!, withIdentifier identifier: String!) {
        if image != nil {
            let path = pathForIdentifier(identifier!)
            let data = UIImageJPEGRepresentation(image, 1.0)!
            data.writeToFile(path, atomically: true)
        }
    }
    
    //access image from disk
    func accessImage(withIdentifier identifier: String!) -> UIImage! {
        let path = pathForIdentifier(identifier!)
        //print(path)
        var image: UIImage!
            if let data = NSData(contentsOfFile: path) {
                if let newImage = UIImage(data: data) {
                    image = newImage
                }
            }
        return image
    }
    
    //remove image from disk
    func removeImage(image: UIImage!, withIdentifier identifier: String!) {
        if image != nil {
            let path = pathForIdentifier(identifier!)
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch {
            }
        }
    }
    
    func pathForIdentifier(identifier: String!) -> String {
        let documentsDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier!)
        
        return fullURL.path!
    }
}