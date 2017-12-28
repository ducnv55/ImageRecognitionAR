//
//  ViewController.swift
//  ImageRecognitionAR
//
//  Created by Duc Nguyen Viet on 12/15/17.
//  Copyright © 2017 TMH Tech Lab. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision
import SDWebImage

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // IBOutlet
    @IBOutlet weak var debugTextView: UITextView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    
    // SCENE
    @IBOutlet var sceneView: ARSCNView!
    let bubbleDepth : Float = 0.06 // the 'depth' of 3D text
    var latestPrediction : String = "…" // a variable containing the latest CoreML prediction
    var scaleValue = SCNVector3Make(0.5, 0.5, 0.5)
    var textScaleValue = SCNVector3Make(0.2, 0.2, 0.2)
    
    // COREML
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    
    let username: [String] = ["duc", "viet", "tam", "jo"]
    var userData: [String: User] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
        
        loadingView.isHidden = false
        loadingIndicatorView.startAnimating()
        
        // Node tap gesture
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.addTarget(self, action: #selector(self.sceneTapped))
        self.sceneView.gestureRecognizers = [tapRecognizer]
        
        // GET USER'S DATA
        getData {
            // Tap Gesture Recognizer
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
            tapGesture.numberOfTapsRequired = 2
            self.view.addGestureRecognizer(tapGesture)
            
            //////////////////////////////////////////////////
            
            // Set up Vision Model
            guard let selectedModel = try? VNCoreMLModel(for: face().model) else { // (Optional) This can be replaced with other models on https://developer.apple.com/machine-learning/
                fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/ . Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
            }
            
            // Set up Vision-CoreML Request
            let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: self.classificationCompleteHandler)
            classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
            self.visionRequests = [classificationRequest]
            
            // Begin Loop to Update CoreML
            self.loopCoreMLUpdate()
            
            self.loadingIndicatorView.stopAnimating()
            self.loadingView.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Enable plane detection
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func getData(completion: @escaping () -> Void) {
        var userCompletedLoadingDataCount = 0
        for user in username {
            var imageCount = 0
            let initUser = Api(scname: user)
            initUser.getData(data: { (data) in
                // get facebook avatar
                let fbAvaImageView = UIImageView()
                fbAvaImageView.sd_setImage(with: data.facebook.picture, placeholderImage: #imageLiteral(resourceName: "facebook"), options: SDWebImageOptions.continueInBackground, completed: { (image, err, cache, url) in
                    imageCount += 1
                    if imageCount == 3 {
                        userCompletedLoadingDataCount += 1
                        if userCompletedLoadingDataCount == self.username.count {
                            completion()
                        }
                    }
                })
                
                // get twitter avatar
                let twAvaImageView = UIImageView()
                let twAvatarUrlString = data.twitter.profile_image_url_https.absoluteString
                let hightResTwAvaUrlString = twAvatarUrlString.replacingOccurrences(of: "_normal", with: "")
                twAvaImageView.sd_setImage(with: URL(string: hightResTwAvaUrlString), placeholderImage: #imageLiteral(resourceName: "twitter"), options: SDWebImageOptions.continueInBackground, completed: { (image, err, cache, url) in
                    imageCount += 1
                    if imageCount == 3 {
                        userCompletedLoadingDataCount += 1
                        if userCompletedLoadingDataCount == self.username.count {
                            completion()
                        }
                    }
                })
                
                // get instagram avatar
                let insAvaImageView = UIImageView()
                insAvaImageView.sd_setImage(with: data.instagram.profile_picture, placeholderImage: #imageLiteral(resourceName: "instagram"), options: SDWebImageOptions.continueInBackground, completed: { (image, err, cache, url) in
                    imageCount += 1
                    if imageCount == 3 {
                        userCompletedLoadingDataCount += 1
                        if userCompletedLoadingDataCount == self.username.count {
                            completion()
                        }
                    }
                })
                
                let userInfo = User(fullname: data.facebook.name,
                                    fb_id: data.facebook.id,
                                    tw_id: data.twitter.id,
                                    ins_id: String(data.instagram.id),
                                    fb_ava: fbAvaImageView,
                                    tw_ava: twAvaImageView,
                                    ins_ava: insAvaImageView)
                self.userData[user] = userInfo
            })
        }
    }
    
    // MARK: NODE TAP GESTURE
    @objc func sceneTapped(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(location, options: nil)
        if hitResults.count > 0 {
            let result = hitResults[0]
            let node = result.node
            if let accountID = node.name, let label = node.accessibilityLabel {
                // go to user's social media app
                jumpToApp(appName: label, accountID: accountID)
            }
        }
    }
    
    func jumpToApp(appName: String, accountID: String) {
        var appURL = URL(string: "")
        switch appName {
        case "facebook":
            appURL = URL(string: "fb://profile/" + accountID)
        case "twitter":
            appURL = URL(string: "twitter://user?id=" + accountID)
        case "instagram":
            appURL = URL(string: "instagram://user?id=" + accountID)
        default:
            return
        }
        if UIApplication.shared.canOpenURL(appURL!) {
            UIApplication.shared.open(appURL!, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // Do any desired updates to SceneKit here.
        }
    }
    
    // MARK: - Status Bar: Hide
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: - Interaction
    
    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // HIT TEST : REAL WORLD
        // Get Screen Centre
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
        
        if let closestResult = arHitTestResults.first {
            // Get Coordinates of HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            let startPosition = SCNVector3Make(worldCoord.x, worldCoord.y + 0.3, worldCoord.z)
            
            // Create 3D Text
            let node : SCNNode = createNewBubbleParentNode(latestPrediction.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
            sceneView.scene.rootNode.addChildNode(node)
            node.position = startPosition
            
            // animation
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1
            SCNTransaction.commit()
            
            let action = SCNAction.move(to: worldCoord, duration: 1)
            node.runAction(action)
        }
    }
    
    func createNewBubbleParentNode(_ name : String) -> SCNNode {
        
        // TEXT BILLBOARD CONSTRAINT
//        let billboardConstraint = SCNBillboardConstraint()
//        billboardConstraint.freeAxes = 
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: self.userData[name]?.fullname, extrusionDepth: CGFloat(bubbleDepth))
        let font = UIFont(name: "HelveticaNeue-Bold", size: 0.1)
        bubble.font = font
        bubble.alignmentMode = kCAAlignmentCenter
        bubble.firstMaterial?.diffuse.contents = UIColor.red
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        var (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2 + 0.05, minBound.y - 0.35, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = textScaleValue
        
        // FACEBOOK NODE
        let facebookSCNBox = getSocialMediaNode(type: "facebook")
        (minBound, maxBound) = facebookSCNBox.boundingBox
        let fbNode = SCNNode(geometry: facebookSCNBox)
        fbNode.name = self.userData[name]?.fb_id
        fbNode.accessibilityLabel = "facebook"
        // Centre Node - to Centre-Bottom point
        fbNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2 + 0.15, minBound.y, bubbleDepth/2)
        fbNode.scale = scaleValue
        
        // TWITTER NODE
        let twitterSCNBox = getSocialMediaNode(type: "twitter")
        (minBound, maxBound) = twitterSCNBox.boundingBox
        let twNode = SCNNode(geometry: twitterSCNBox)
        twNode.name = self.userData[name]?.tw_id
        twNode.accessibilityLabel = "twitter"
        // Centre Node - to Centre-Bottom point
        twNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        twNode.scale = scaleValue
        
        // INSTAGRAM NODE
        let instagramSCNBox = getSocialMediaNode(type: "instagram")
        (minBound, maxBound) = instagramSCNBox.boundingBox
        let insNode = SCNNode(geometry: instagramSCNBox)
        insNode.name = self.userData[name]?.ins_id
        insNode.accessibilityLabel = "instagram"
        // Centre Node - to Centre-Bottom point
        insNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2 - 0.15, minBound.y, bubbleDepth/2)
        insNode.scale = scaleValue
        
        // SOCIAL MEDIA NODE
        // Cover with Facebook, Twitter, Instagram's profile 
        let smSCNBox = get3dAvatarImage(name: name)
        (minBound, maxBound) = smSCNBox.boundingBox
        let socialMediaNode = SCNNode(geometry: smSCNBox)
        // Centre Node - to Centre-Bottom point
        socialMediaNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2 - 0.05, minBound.y - 0.2, bubbleDepth/2)
        socialMediaNode.scale = scaleValue
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(fbNode)
        bubbleNodeParent.addChildNode(twNode)
        bubbleNodeParent.addChildNode(insNode)
        bubbleNodeParent.addChildNode(socialMediaNode)
//        bubbleNodeParent.constraints = [billboardConstraint]
        return bubbleNodeParent
    }
    
    func getSocialMediaNode(type: String) -> SCNBox {
        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        
        let socialMediaMaterial = SCNMaterial()
        socialMediaMaterial.diffuse.contents = UIImage(named: type)
        socialMediaMaterial.locksAmbientWithDiffuse = true
        
        boxGeometry.materials =  [socialMediaMaterial, socialMediaMaterial, socialMediaMaterial,
                                  socialMediaMaterial, socialMediaMaterial, socialMediaMaterial]

        return boxGeometry
    }
    
    func get3dAvatarImage(name: String) -> SCNBox {
        let boxGeometry = SCNBox(width: 0.15, height: 0.15, length: 0.15, chamferRadius: 0.01)
        
        let fbSocialMediaMaterial = SCNMaterial()
        fbSocialMediaMaterial.diffuse.contents = self.userData[name]?.fb_ava.image
        
        let twSocialMediaMaterial = SCNMaterial()
        twSocialMediaMaterial.diffuse.contents = self.userData[name]?.tw_ava.image
        
        let insSocialMediaMaterial = SCNMaterial()
        insSocialMediaMaterial.diffuse.contents = self.userData[name]?.ins_ava.image
        
        fbSocialMediaMaterial.locksAmbientWithDiffuse = true;
        twSocialMediaMaterial.locksAmbientWithDiffuse = true;
        insSocialMediaMaterial.locksAmbientWithDiffuse = true;
        
        boxGeometry.materials =  [fbSocialMediaMaterial, twSocialMediaMaterial, fbSocialMediaMaterial,
                                  insSocialMediaMaterial, twSocialMediaMaterial, insSocialMediaMaterial]
        return boxGeometry
    }
    
    // MARK: - CoreML Vision Handling
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        
        dispatchQueueML.async {
            // 1. Run Update.
            self.updateCoreML()
            
            // 2. Loop this function.
            self.loopCoreMLUpdate()
        }
        
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
        let classifications = observations[0...1] // top 2 results
            .flatMap({ $0 as? VNClassificationObservation })
//            .filter({$0.confidence > 0.5})
            .map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        
        DispatchQueue.main.async {
            // Print Classifications
            //            print(classifications)
            //            print("--")
            
            // Display Debug Text on screen
            var debugText:String = ""
            debugText += classifications
            self.debugTextView.text = debugText
            
            // Store the latest prediction
            var objectName:String = "…"
            objectName = classifications.components(separatedBy: "-")[0]
            objectName = objectName.components(separatedBy: ",")[0]
            self.latestPrediction = objectName
            
        }
    }
    
    func updateCoreML() {
        ///////////////////////////
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        // Note: Not entirely sure if the ciImage is being interpreted as RGB, but for now it works with the Inception model.
        // Note2: Also uncertain if the pixelBuffer should be rotated before handing off to Vision (VNImageRequestHandler) - regardless, for now, it still works well with the Inception model.
        
        ///////////////////////////
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        // let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: myOrientation, options: [:]) // Alternatively; we can convert the above to an RGB CGImage and use that. Also UIInterfaceOrientation can inform orientation values.
        
        ///////////////////////////
        // Run Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
        
    }
    @IBAction func resetSceneView(_ sender: Any) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
    }
}

