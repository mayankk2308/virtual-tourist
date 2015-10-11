//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Mayank Kumar on 7/22/15.
//  Copyright © 2015 Mayank Kumar. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {

    //UI Elements & CoreData Properties
    @IBOutlet var map: MKMapView!
    
    var press: UILongPressGestureRecognizer! {
        return UILongPressGestureRecognizer(target: self, action: "handlePress:")
    }
    
    lazy var appDel: AppDelegate = {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }()
    
    lazy var sharedContext: NSManagedObjectContext! = {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }()
    
    var pins = [Pin]()
    var deleteMode = false
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var doneButton: UIBarButtonItem!
    
    
    //Life-cycle methods
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.title = "Virtual Tourist"
        self.doneButton.enabled = false
        self.deleteMode = false
        
        map.delegate = self
        map.addGestureRecognizer(press)
        pins = fetchAllStoredPins()
        if pins.count > 0 {
            self.addAnnotationsToMap(pins)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let controller = segue.destinationViewController as! PhotoViewController
        let annotation = sender as! PointAnnotation
        controller.selectedAnnotation = annotation
        controller.pin = annotation.pin
    }
    
    //Map operations
    func addAnnotationsToMap(pins: [Pin]) {
        var annotations = [PointAnnotation]()
        for pin in pins {
            let annotation = PointAnnotation()
            annotation.coordinate.latitude = pin.latitude as! CLLocationDegrees
            annotation.coordinate.longitude = pin.longitude as! CLLocationDegrees
            annotation.pin = pin
            annotations.append(annotation)
        }
        map.addAnnotations(annotations)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseid = "pin"
        var annView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseid) as! MKPinAnnotationView!
        if annView == nil {
            annView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseid)
            annView.canShowCallout = false
            annView.animatesDrop = true
        }
        else {
            annView.annotation = annotation
        }
        return annView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if deleteMode {
            let annotation = view.annotation! as! PointAnnotation
            let objectToDelete = annotation.pin!
            mapView.removeAnnotation(annotation)
            let index = (pins as NSArray).indexOfObject(objectToDelete)
            sharedContext!.deleteObject(objectToDelete)
            appDel.saveContext()
            pins.removeAtIndex(index)
        }
        else {
            performSegueWithIdentifier("showPhotoView", sender: view.annotation)
            mapView.removeAnnotations(mapView.annotations)
        }
    }
    
    //CoreData operations
    func fetchAllStoredPins() -> [Pin] {
        let request = NSFetchRequest(entityName: "Pin")
        let results: [AnyObject]?
        do {
            results = try sharedContext!.executeFetchRequest(request)
        } catch {
            print("unable to process fetch request")
            results = nil
        }
        return results as! [Pin]
    }
    
    //UI operations
    @IBAction func enableMapEditMode(sender: UIBarButtonItem) {
        deleteMode = true
        self.doneButton.enabled = true
        self.editButton.enabled = false
        self.navigationItem.title = "Now In Edit Mode"
    }
    
    @IBAction func disableMapEditMode(sender: UIBarButtonItem) {
        deleteMode = false
        self.doneButton.enabled = false
        self.editButton.enabled = true
        self.navigationItem.title = "Virtual Tourist"
    }
    
    func handlePress(sender: UILongPressGestureRecognizer) {
        
        //drop pin on the map
        if sender.state != .Ended && sender.state != .Changed && !deleteMode {
            let position = sender.locationInView(self.map)
            let annotation = PointAnnotation()
            let coordinate = self.map.convertPoint(position, toCoordinateFromView: map)
            annotation.coordinate = coordinate
            let pin = Pin(latitude: annotation.coordinate.latitude as Double, longitude: annotation.coordinate.longitude, context: sharedContext!)
            annotation.pin = pin
            self.map.addAnnotation(annotation)
            //save the new pin
            pins.append(pin)
            appDel.saveContext()
        }
    }
}

