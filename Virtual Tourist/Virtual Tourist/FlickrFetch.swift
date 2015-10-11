//
//  Flickr Fetch.swift
//  Virtual Tourist
//
//  Created by Mayank Kumar on 7/23/15.
//  Copyright © 2015 Mayank Kumar. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class FlickrFetch: NSObject {
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "06b002f0f3083f88e8a609606bbbae71"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let BOUNDING_BOX_HALF_WIDTH = 1.0
    let BOUNDING_BOX_HALF_HEIGHT = 1.0
    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LON_MIN = -180.0
    let LON_MAX = 180.0
    
    var appDel: AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    var sharedContext: NSManagedObjectContext {
        return appDel.managedObjectContext
    }
    
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func escapedParameters(dictionary: [String: AnyObject]) -> String {
        var url = [String] ()
        for(key, value) in dictionary {
            let stringValue = "\(value)"
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            url += [key + "=" + "\(escapedValue)"]
        }
        return (!url.isEmpty ? "?" : "") + url.joinWithSeparator("&")
    }
    
    func getImageFromFlickr(pin: Pin!, completionHandler: (success: Bool, photo: Photo!) -> Void) -> NSURLSessionTask! {
        let parameters = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString((pin.latitude?.doubleValue)!, longitude: (pin.longitude?.doubleValue)!),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
        ]
        
        let taskToReturn = searchFlickr(pin, parameters: parameters) { success, photo in
            completionHandler(success: success, photo: photo)
        }
        return taskToReturn
    }
    
    func searchFlickr(pin: Pin, parameters: [String: AnyObject], completionHandler: (success: Bool, photo: Photo!) -> Void) -> NSURLSessionTask! {
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        var taskToReturn: NSURLSessionTask!
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                completionHandler(success: false, photo: nil)
            }
            else {
                var result: NSDictionary!
                do {
                    result = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                    if let photosDictionary = result.valueForKey("photos") as? [String: AnyObject] {
                        if let totalPages = photosDictionary["pages"] as? Int {
                            
                            let pageLimit = min(totalPages, 40)
                            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                            let newTask = self.getFlickImageFromPage(pin, parameters: parameters, page: randomPage) { success, photo in
                                completionHandler(success: success, photo: photo)
                            }
                            taskToReturn = newTask!
                        }
                        
                    }
                    else {
                        completionHandler(success: false, photo: nil)
                    }
                    
                } catch {
                    completionHandler(success: false, photo: nil)
                }
            }
        }
        
        task.resume()
        return taskToReturn
    }
    
    func getFlickImageFromPage(pin: Pin, parameters: [String: AnyObject], page: Int, completionHandler: (success: Bool, photo: Photo!) -> Void) -> NSURLSessionTask! {
        var updatedDictionary = parameters
        updatedDictionary["page"] = page
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(updatedDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                completionHandler(success: false, photo: nil)
            }
            else {
                var result: NSDictionary!
                do {
                    result = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                    if let photosDictionary = result.valueForKey("photos") as? [String: AnyObject] {
                        
                        var totalPhotosVal = 0
                        if let totalPhotos = photosDictionary["total"] as? String {
                            totalPhotosVal = (totalPhotos as NSString).integerValue
                        }
                        
                        if totalPhotosVal > 0 {
                            if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                
                                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                                
                                var photoInfo = [String: AnyObject]()
                                photoInfo["id"] = photoDictionary["id"]
                                photoInfo["url_m"] = photoDictionary["url_m"]
                                let photo = Photo(dictionary: photoInfo, context: self.sharedContext)
                                photo.pin = pin
                                self.appDel.saveContext()
                                completionHandler(success: true, photo: photo)
                            }
                        }
                    }
                    else {
                        completionHandler(success: false, photo: nil)
                    }
                    
                } catch {
                    completionHandler(success: false, photo: nil)
                }
            }
        }
        
        task.resume()
        return task
    }
}