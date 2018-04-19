//
//  MapViewController.swift
//  ARApp
//
//  Created by Gary Hicks on 2018-04-14.
//  Copyright © 2018 Gary Hicks. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

var stepDistances = [Double]()
var stepLocations = [CLLocationCoordinate2D]()
var stepsWords = [String]()

struct Place {
    static var firstHeading:CLLocationDirection? = nil
    static var angle = 0.0
    static var sent = false
}

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var textBox: UITextField!
    
    var currentLocation: CLLocation? = nil
    var destination: CLLocation? = nil
    var locationManager = CLLocationManager()
    var angleMe = 0.0
    var angleDest = 0.0
    
    @IBAction func go(_ sender: Any) {
        
        let geoCoder = CLGeocoder()
        
        if let address = textBox.text{
            geoCoder.geocodeAddressString(address) { (placemarks, error) in
                if let placemark = placemarks?[0]{
                    
                    self.map.removeAnnotations(self.map.annotations)
                    
                    
                    let coordinates: CLLocation = placemark.location!
                    self.destination  = coordinates
                    let latitude = coordinates.coordinate.latitude
                    let longitude = coordinates.coordinate.longitude
                    
                    //Annotation
                    let annotation = MKPointAnnotation()
                    let newCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    annotation.coordinate = newCoordinate
                    annotation.title = self.textBox.text
                    self.map.addAnnotation(annotation)
                    
                    //Directions
                    let directionRequest = MKDirectionsRequest()
                    let destinationPlacemark = MKPlacemark(placemark: placemark)
                    directionRequest.source = MKMapItem.forCurrentLocation()
                    directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
                    directionRequest.transportType = .automobile
                    
                    let directions = MKDirections(request: directionRequest)
                    directions.calculate{ (directionsResponse, error) in
                        if let directionsResponse = directionsResponse {
                            let route = directionsResponse.routes[0]
                            
                            for step in route.steps{
                                
                                stepsWords.append(step.instructions)
                                print(step.instructions)
                                stepLocations.append(step.polyline.coordinate)
                                print(step.polyline.coordinate)
                                stepDistances.append(step.distance)
                                print(step.distance)
                                
                            }
                            
                            //Get heading
                            self.locationManager.startUpdatingHeading()
                            
                            DispatchQueue.main.async {

                                Place.sent = true
                                
                                self.map.delegate = self
                                self.map.removeOverlays(self.map.overlays)
                                self.map.add(route.polyline, level: .aboveRoads)
                                let routeRect = route.polyline.boundingMapRect
                                self.map.setRegion(MKCoordinateRegionForMapRect(routeRect), animated: true)
                                
                            }

                        }
                    }

                }
            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.hideKeyboard()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        map.showsUserLocation = true
        map.showsCompass = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0]
        currentLocation = userLocation
        
        if Place.sent == false {
            let latitude = userLocation.coordinate.latitude
            let longitude = userLocation.coordinate.longitude
            
            let latDelta: CLLocationDegrees = 0.1
            let longDelta: CLLocationDegrees = 0.1
            let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
            let location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region: MKCoordinateRegion = MKCoordinateRegion(center: location, span: span)
            self.map.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let userHeading = newHeading.trueHeading
        Place.firstHeading = userHeading
        angleMe = (360.0-userHeading) + 90.0
        if angleMe >= 360.0 {
            angleMe = angleMe-360
        }
        print("User Heading: \(userHeading)")
        print("AngleMe: \(angleMe)")
        
        locationManager.stopUpdatingHeading()
        
        //Get Distance and Angle
        self.getInfo(coordinates: stepLocations[0])
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.purple
        renderer.lineWidth = 4.0
        return renderer
    }
    
    func getInfo(coordinates: CLLocationCoordinate2D){
        
        if let location = currentLocation {
            
            /*let dist = coordinates.distance(from: location)
            distances.append(dist)
            print("Dist: \(dist)")*/
            
            let y1: CLLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let y2: CLLocation = CLLocation(latitude: coordinates.latitude, longitude: location.coordinate.longitude)
            let yDelta = y2.distance(from: y1)
            
            //print(y1.coordinate.latitude)
            //print(y2.coordinate.latitude)
            print("yDelta: \(yDelta)")
            
            
            let x1: CLLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let x2: CLLocation = CLLocation(latitude: location.coordinate.latitude, longitude: coordinates.longitude)
            let xDelta = x2.distance(from: x1)
            
            //print(x1.coordinate.longitude)
            //print(x2.coordinate.longitude)
            print("xDelta: \(xDelta)")
            
            angleDest = (atan(yDelta/xDelta))*(180.0/3.1415926)
            //print("AngleDest: \(angleDest)")
            
            //print(Double(x1.coordinate.longitude))
            
            if x2.coordinate.longitude > x1.coordinate.longitude {
                if y2.coordinate.latitude > y1.coordinate.latitude {
                    //First Quadrant, stays the same
                    print(1)
                }
                else{
                    //Fourth Quadrant, 360 - angleDest
                    angleDest = 360.0 - angleDest
                    print(4)
                }
            }
            else{
                if y2.coordinate.latitude > y1.coordinate.latitude {
                    //Second Quadrant, 180 - angleDest
                    angleDest = 180 - angleDest
                    print(2)
                }
                else{
                    //Third Quadrant, 180 + angleDest
                    angleDest = 180 + angleDest
                    print(3)
                }
            }
            
            print("AngleDest: \(angleDest)")
            Place.angle = angleDest - angleMe
            print("Final Angle: \(Place.angle)")
            
        }
    }

}

extension UIViewController
{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
}
