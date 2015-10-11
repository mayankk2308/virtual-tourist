//
//  PhotoViewController.swift
//  Virtual Tourist
//
//  Created by Mayank Kumar on 7/22/15.
//  Copyright © 2015 Mayank Kumar. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    //Properties
    var selectedAnnotation: MKPointAnnotation!
    var pin: Pin!
    var layoutComplete = false
    var dataTask: NSURLSessionTask!
    var imageCount = 0
    var selectedIndices = [Int]()
    var dataReloaded =  false
    
    var photosJustAdded = [Photo!]()
    var photosJustRemoved = [Photo!]()
    var deleteCount = 0
    var initialFetchCount = 0
    
    var fetchedPhotos: [Photo] {
        return fetchPhotosFromDisk()
    }
    
    lazy var appDel: AppDelegate = {
        return UIApplication.sharedApplication().delegate as! AppDelegate
        }()
    
    lazy var sharedContext: NSManagedObjectContext! = {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        }()
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var photoView: UICollectionView!
    @IBOutlet var refreshCollection: UIBarButtonItem!
    
    //Life-cycle operations
    override func viewDidLoad() {
        setupMap()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.dataReloaded = false
        self.photoView.userInteractionEnabled = false
        self.photoView.reloadData()
        if fetchedPhotos.count > 0 {
            self.refreshCollection.enabled = true
            self.photoView.scrollEnabled = true
            self.initialFetchCount = fetchedPhotos.count
        }
        else {
            self.deleteCount = 0
            self.refreshCollection.enabled = false
            self.photoView.scrollEnabled = false
        }
        layoutComplete = false
    }
    
    override func viewDidLayoutSubviews() {
        // Lay out the collection view so that cells take up 1/3 of the width, with space
        
        if !layoutComplete {
            layoutComplete = true
            let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.sectionInset = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
            layout.minimumLineSpacing = 3
            layout.minimumInteritemSpacing = 3
        
            let width = floor(photoView.frame.width / 3 - 4)
            layout.itemSize = CGSize(width: width, height: width)
            photoView.collectionViewLayout = layout
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
//        self.photoView.delegate = nil
//        self.photoView.dataSource = nil
//        self.photoView = nil
    }
    
    //Map operations
    func setupMap() {
        map.addAnnotation(selectedAnnotation)
        let newCoordinate = CLLocationCoordinate2D(latitude: selectedAnnotation.coordinate.latitude + 0.005, longitude: selectedAnnotation.coordinate.longitude)
        map.setRegion(MKCoordinateRegionMakeWithDistance(selectedAnnotation.coordinate, 2000, 2000), animated: true)
        map.setCenterCoordinate(newCoordinate, animated: false)
    }
    
    
    //Collection View operations
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! PhotoCell
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    
    func configureCell(cell: PhotoCell, indexPath: NSIndexPath) {
        cell.imageViewer.image = UIImage(named: "Placeholder")
        if !dataReloaded && fetchedPhotos.count > 0 {
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.hidden = true
        }
        else {
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.hidden = false
        }
        if fetchedPhotos.count > 0 {
            photosJustAdded.append(fetchedPhotos[indexPath.row])
            cell.imageViewer.image = ImagePersistence().accessImage(withIdentifier: fetchedPhotos[indexPath.row].id)
            cell.photo = fetchedPhotos[indexPath.row]
            cell.activityIndicator.hidden = true
            self.photoView.userInteractionEnabled = true
            self.dataReloaded = false
        }
        else {
            cell.activityIndicator.startAnimating()
            dataTask = FlickrFetch().getImageFromFlickr(self.pin) { success, photo in
                if success {
                    self.imageCount++
                    self.photosJustAdded.append(photo)
                    if let url = NSURL(string: photo.url!) {
                        if let data = NSData(contentsOfURL: url) {
                            if let image = UIImage(data: data) {
                                ImagePersistence().storeImage(image, withIdentifier: photo.id)
                                cell.photo = photo
                            }
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.imageViewer.image = ImagePersistence().accessImage(withIdentifier: photo.id)
                            cell.activityIndicator.stopAnimating()
                            cell.activityIndicator.hidden = true
                            if self.imageCount == 12 {
                                self.refreshCollection.enabled = true
                                self.photoView.scrollEnabled = true
                                self.photoView.userInteractionEnabled = true
                                self.dataReloaded = false
                            }
                        }
                    }
                }
                else {
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.activityIndicator.stopAnimating()
                        let alert = UIAlertController(title: "Download Failure", message: "Unable to retrieve photos. Please try again.", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: nil))
                        self.refreshCollection.enabled = true
                    }
                }
            }
            cell.taskToCancelIfCellIsReused = dataTask as? NSURLSessionDataTask
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if fetchedPhotos.count > 0 {
            return fetchedPhotos.count
        }
        return 12
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell!
        ImagePersistence().removeImage(ImagePersistence().accessImage(withIdentifier: cell.photo.id), withIdentifier: cell.photo.id)
        self.deleteCount++
        self.photosJustRemoved.append(cell.photo)
        self.sharedContext.deleteObject(cell.photo)
        self.appDel.saveContext()
        print(fetchedPhotos.count)
        if deleteCount == 12 || (initialFetchCount > 0 && deleteCount == initialFetchCount) {
            refreshForCollection()
        }
        else {
            self.photoView.deleteItemsAtIndexPaths([indexPath])
        }
    }
    
    //Core Data operations
    func fetchPhotosFromDisk() -> [Photo] {
        let request = NSFetchRequest(entityName: "Photo")
        request.predicate = NSPredicate(format: "pin == %@", self.pin)
        let result: [Photo]!
        do {
            result = try self.sharedContext.executeFetchRequest(request) as? [Photo]
        } catch {
            result = nil
        }
        return result
    }
    
    func deleteAllPhotos() {
        //this code does not work for some reason
        //        for photo in pin.photos! {
        //            photo.pin = nil
        //            ImagePersistence().removeImage(ImagePersistence().accessImage(withIdentifier: photo.id), withIdentifier: photo.id)
        //        }
        
        //photosJustAdded is a not-so-nice workaround
        var flag = false
        if photosJustRemoved.count > 0 {
            for photo in photosJustAdded {
                flag = false
                for removedPhoto in photosJustRemoved {
                    if photo == removedPhoto {
                        flag = true
                    }
                }
                if !flag {
                    photo.pin = nil
                    ImagePersistence().removeImage(ImagePersistence().accessImage(withIdentifier: photo.url), withIdentifier: photo.url)
                }
            }
        }
        else {
            for photo in photosJustAdded {
                photo.pin = nil
                ImagePersistence().removeImage(ImagePersistence().accessImage(withIdentifier: photo.url), withIdentifier: photo.url)
            }
        }
        self.appDel.saveContext()
    }
    
    //UI operations
    @IBAction func loadNewCollection(sender: UIBarButtonItem) {
        refreshForCollection()
    }
    
    func refreshForCollection() -> Void {
        deleteAllPhotos()
        self.photosJustAdded = [Photo!]()
        self.photosJustRemoved = [Photo!]()
        self.photoView.reloadData()
        dataReloaded = true
        self.photoView.userInteractionEnabled = false
        self.photoView.scrollEnabled = false
        self.refreshCollection.enabled = false
        self.imageCount = 0
        self.deleteCount = 0
        self.initialFetchCount = 0
    }
    
    
}