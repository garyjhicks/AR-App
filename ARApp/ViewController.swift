//
//  ViewController.swift
//  ARApp
//
//  Created by Gary Hicks on 2018-04-13.
//  Copyright © 2018 Gary Hicks. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation

class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    
    var count = 0
    
    var currentLocation: CLLocation? = nil
    //var destination: CLLocation? = nil
    var locationManager = CLLocationManager()
    var angleMe = 0.0
    var angleDest = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        label.text = stepsWords[count]
        
        prepareToCreate()
        
    }
    
    /*override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }*/
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        sceneView.session.pause()
        
        self.sceneView.scene.rootNode.enumerateChildNodes { (existingNode, _) in
            existingNode.removeFromParentNode()
        }
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [ARSession.RunOptions.resetTracking, ARSession.RunOptions.removeExistingAnchors])
        
        //Get heading
        if count == stepsWords.count{
            displayAlert(title: "Yay!", message: "You have arrived at your destination!")
            label.text = "You have arrived!"
        }
        else{
            label.text = stepsWords[count]
            self.locationManager.startUpdatingHeading()
        }
        
    }
    
    func prepareToCreate() {
        
        var travel = Int(stepDistances[count])
        if travel <= 1 {
            travel = 100
        }
        
        print("Angle: \(Place.angle+90.0)")
        //print(distances)
        
        let xdir = Float(cos((Place.angle+90.0)*3.1415926/180))
        let zdir = Float(-sin((Place.angle+90.0)*3.1415926/180))
        
        print("x direction: \(Float(cos((Place.angle+90.0)*3.1415926/180)))")
        print("z direction: \(Float(-sin((Place.angle+90.0)*3.1415926/180)))")
        
        if (Place.sent) {
            
            for i in 1...travel {
                let vector = SCNVector3Make(xdir*Float(i), -1.2, zdir*Float(i))
                //print(vector)
                createBall(position: vector)
            }
            
            let pinPlace = SCNVector3Make(xdir*Float(travel), 0, zdir*Float(travel))
            //let pinPlace = SCNVector3Make(xdir*2.0, 0, zdir*2.0)
            
            if count == stepsWords.count-1{
                createPin(position: pinPlace, image: "pin.png")
            }
            else{
                createPin(position: pinPlace, image: "bluePin.png")
            }
            
            count+=1
            print("Count: \(count)")
            print("Step: \(stepsWords[count-1])")
        }
    }
    
    func createBall(position: SCNVector3){
        let ballShape = SCNSphere(radius: 0.1)
        let ballNode = SCNNode(geometry: ballShape)
        ballNode.position = position
        ballNode.opacity = 0.5
        sceneView.scene.rootNode.addChildNode(ballNode)
    }
    
    func createPin(position: SCNVector3, image: String){
        let box = SCNBox(width: 0.2, height: 0.2, length: 0.005, chamferRadius: 0)
        let boxNode = SCNNode(geometry: box)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: image)
        box.materials = [material]
        
        boxNode.opacity = 1.0
        boxNode.position = position
        
        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation: CLLocation = locations[0]
        currentLocation = userLocation
        //print(currentLocation)
    
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        //let userHeading = Place.firstHeading!
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
        self.getInfo(coordinates: stepLocations[count])
        
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
            
            prepareToCreate()
            
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
