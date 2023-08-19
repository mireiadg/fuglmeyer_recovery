//
//  VideoCapture.swift
//  FuglMeyerApp
//
//  Created by Mireia de Gracia on 17/5/23.
//

import Foundation
import AVFoundation

class VideoCapture: NSObject {
    let captureSession = AVCaptureSession() // Capture session to manage input and output
    
    let videoOutput = AVCaptureVideoDataOutput() // Output to capture video data
    
    let predictor = Predictor() // Predictor for body position
    
    override init() {
        super.init()
        
        // Specify the capture device (change default camera to front camera!!!)
        // Create an AVCaptureDeviceInput to get data from the capture device
        guard let captureDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first,
            let input = try? AVCaptureDeviceInput(device: captureDevice) else {
                return
        }
        
        // Configure the capture session
        captureSession.sessionPreset = AVCaptureSession.Preset.high // Set data resolution to high
        captureSession.addInput(input) // Add the input to the capture session
        captureSession.addOutput(videoOutput) // Add the video output to the capture session
        videoOutput.alwaysDiscardsLateVideoFrames = true // Discard late video frames to reduce latency
    }
    
    func startCaptureSession() {
        captureSession.startRunning() // Start the capture session
        
        // Set the VideoCapture class as the delegate for video output
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoDispatchQueue"))
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        predictor.estimation(sampleBuffer: sampleBuffer) // Perform body position estimation using the predictor
        
        // Additional code for processing the video data if needed
        // let videoData = sampleBuffer
        // print(videoData)
    }
}
