//
//  ViewController.swift
//  FuglMeyerApp
//
//  Created by Mireia de Gracia on 17/5/23.
//

import UIKit
import AVFoundation
import AudioToolbox

class ViewController: UIViewController {
    var audioPlayer: AVAudioPlayer? // Used for playing ear sound
    var lateralAudioPlayer: AVAudioPlayer? // Used for playing lateral sound
    var earSoundURL: URL! // URL of the ear sound file
    var lateralSoundURL: URL! // URL of the lateral sound file
   
    // to preview some actual data
    let videoCapture = VideoCapture() // VideoCapture instance for capturing video
    
    var previewLayer: AVCaptureVideoPreviewLayer? // Preview layer for displaying captured video
    var isEarDetected = false // Flag to track if an ear movement is detected
    var isArmDetected = false // Flag to track if an arm movement is detected
    var pointsLayer = CAShapeLayer() // Layer for drawing recognized points
    
    private func setupVideoPreview() {
        videoCapture.startCaptureSession() // Start the video capture session
        
        previewLayer = AVCaptureVideoPreviewLayer(session: videoCapture.captureSession) // Create preview layer
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback) // Set audio session category for playback
            try AVAudioSession.sharedInstance().setActive(true) // Activate the audio session
        } catch {
            // Handle any errors that occur during audio session configuration
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
        
        // Ensure that the previewLayer is initialized
        guard let previewLayer = previewLayer else { return }
        
        view.layer.addSublayer(previewLayer) // Add preview layer to the view's layer
        previewLayer.frame = view.frame // Set the frame of the preview layer
        
        view.layer.addSublayer(pointsLayer) // Add points layer to the view's layer
        pointsLayer.frame = view.frame // Set the frame of the points layer
        pointsLayer.strokeColor = UIColor.green.cgColor // Set the stroke color of the points layer
    }
    
    private func preloadAudioFiles() {
        // Preload ear sound
        if let earSoundPath = Bundle.main.path(forResource: "sound_test_ear", ofType: "wav") {
            earSoundURL = URL(fileURLWithPath: earSoundPath)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: earSoundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Failed to preload ear sound: \(error.localizedDescription)")
            }
        }
        
        // Preload lateral sound
        if let lateralSoundPath = Bundle.main.path(forResource: "sound_test_arm", ofType: "wav") {
            lateralSoundURL = URL(fileURLWithPath: lateralSoundPath)
            do {
                lateralAudioPlayer = try AVAudioPlayer(contentsOf: lateralSoundURL)
                lateralAudioPlayer?.prepareToPlay()
            } catch {
                print("Failed to preload lateral sound: \(error.localizedDescription)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupVideoPreview() // Set up the video preview
        
        videoCapture.predictor.delegate = self // Set the delegate for the video capture's predictor
        
        preloadAudioFiles() // Preload audio files for playback
    }
}

extension ViewController: PredictorDelegate {
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double) {
        // Action labeling delegate method
        print(confidence)
        print(action)
        if (action == "ear_right" || action == "ear_left") && confidence > 0.80 && !isEarDetected{
            // If the action is "ear" and the confidence level is high enough, and no ear is currently detected
            
            //print("ear detected")
//            print(confidence)
            isEarDetected = true // Set clap detected flag
            
            DispatchQueue.main.async {
                if let audioPlayer = self.audioPlayer {
                    audioPlayer.play() // Play the ear sound asynchronously
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.isEarDetected = false // Reset clap detected flag after a delay
            }
        }
        else if (action == "90lateral_right" || action == "90lateral_left") && confidence > 0.80 && !isArmDetected{
            // If the action is "90lateral" and the confidence level is high enough, and no arm movement is currently detected

//            print("arm detected")
//            print(confidence)
            isArmDetected = true // Set arm detected flag

            DispatchQueue.main.async {
                if let lateralAudioPlayer = self.lateralAudioPlayer {
                    lateralAudioPlayer.play() // Play the lateral sound asynchronously
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.isArmDetected = false // Reset arm detected flag after a delay
            }
        }
    }
    
    func predictor(_ predictor: Predictor, didFindNewRecognizedPoints points: [CGPoint]) {
        // Point recognition delegate method
        
        guard let previewLayer = previewLayer else { return }
        
        let convertedPoints = points.map {
            previewLayer.layerPointConverted(fromCaptureDevicePoint: $0) // Convert points to the layer's coordinate system
        }
        
        let combinedPath = CGMutablePath() // Create a combined path to draw recognized points
        
        for point in convertedPoints {
            let dotPath = UIBezierPath(ovalIn: CGRect(x: point.x, y: point.y, width: 5, height: 5)) // Create an oval shape for each point
            combinedPath.addPath(dotPath.cgPath) // Add the oval shape to the combined path
        }
        
        pointsLayer.path = combinedPath // Set the path of the points layer to the combined path
        
        DispatchQueue.main.async {
            self.pointsLayer.didChangeValue(for: \.path) // Update the points layer asynchronously to reflect the changes made
        }
    }
}
