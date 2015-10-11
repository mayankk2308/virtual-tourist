//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by Mayank Kumar on 7/22/15.
//  Copyright © 2015 Mayank Kumar. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    @IBOutlet var imageViewer: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var photo: Photo!
    
    var taskToCancelIfCellIsReused: NSURLSessionDataTask? {
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
