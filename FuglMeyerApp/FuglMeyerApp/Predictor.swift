//
//  Predictor.swift
//  FuglMeyerApp
//
//  Created by Mireia de Gracia on 18/5/23.
//

import Foundation
import Vision

// typealias FMClassifier = fugl_meyer_test_1
//typealias FMClassifier = MyActionClassifier_2
//typealias FMClassifier = fugl_meyer_test_12
//typealias FMClassifier = FuglMeyerActionClassifier_1_Iteration_40
typealias FMClassifier = FuglMeyerActionClassifier_3_Iteration_60
//typealias FMClassifier = Fugl_meyer_test_9_Iteration_40
// typealias FMClassifier = Fugl_meyer_classifier_2

protocol PredictorDelegate: AnyObject {
    func predictor(_ predictor: Predictor, didFindNewRecognizedPoints points: [CGPoint])
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double)
}

class Predictor {
    let predictionWindowSize = 30 // Number of observations to keep in the posesWindow
    var posesWindow: [VNHumanBodyPoseObservation] = [] // Window of VNHumanBodyPoseObservation objects
    
    init() {
        posesWindow.reserveCapacity(predictionWindowSize) // Reserve capacity for the posesWindow array
    }
    
    weak var delegate: PredictorDelegate? // Delegate to notify about recognized points and labeled actions
    
    func estimation(sampleBuffer: CMSampleBuffer) {
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)
        
        let request = VNDetectHumanBodyPoseRequest(completionHandler: bodyPoseHandler)
        
        do {
            try requestHandler.perform([request]) // Perform the request to detect human body pose
        } catch {
            print("Unable to perform the request with error: \(error)")
        }
    }
    
    func prepareInputWithObservations(_ observations: [VNHumanBodyPoseObservation]) -> MLMultiArray? {
        let numAvailableFrames = observations.count
        let observationsNeeded = 30
        var multiArrayBuffer = [MLMultiArray]()
        
        for frameIndex in 0 ..< min(numAvailableFrames, observationsNeeded) {
            let pose = observations[frameIndex]
            do {
                let oneFrameMultiarray = try pose.keypointsMultiArray() // Get the keypoints as a multi-array
                multiArrayBuffer.append(oneFrameMultiarray) // Append the multi-array to the buffer
            } catch {
                continue
            }
        }
        
        if numAvailableFrames < observationsNeeded {
            for _ in 0 ..< (observationsNeeded - numAvailableFrames) {
                do {
                    let oneFrameMultiArray = try MLMultiArray(shape: [1, 3, 18], dataType: .double)
                    multiArrayBuffer.append(oneFrameMultiArray)
                    try resetMultiArray(oneFrameMultiArray)
                } catch {
                    continue
                }
            }
        }
        
        return MLMultiArray(concatenating: [MLMultiArray](multiArrayBuffer), axis: 0, dataType: .float) // Concatenate the multi-arrays along axis 0
    }
    
    func resetMultiArray(_ predictionWindow: MLMultiArray, with value: Double = 0.0) throws {
        let pointer = try UnsafeMutableBufferPointer<Double>(predictionWindow)
        pointer.initialize(repeating: value) // Set all values in the multi-array to the given value
    }
    
    func bodyPoseHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanBodyPoseObservation] else { return }
        
        observations.forEach {
            processObservation($0) // Process each observation and notify the delegate about recognized points
        }
        
        if let result = observations.first {
            storeObservation(result) // Store the first observation in the posesWindow
            
            labelActionType() // Label the action type based on the stored observations
        }
    }
    
    func labelActionType() {
        guard let movementsClassifier = try? FMClassifier(configuration: MLModelConfiguration()),
              let poseMultiArray = prepareInputWithObservations(posesWindow),
              let predictions = try? movementsClassifier.prediction(poses: poseMultiArray) else {
            return
        }
        
        let label = predictions.label // Get the predicted action label
        let confidence = predictions.labelProbabilities[label] ?? 0 // Get the confidence of the predicted action
        
        delegate?.predictor(self, didLabelAction: label, with: confidence) // Notify the delegate about the labeled action
    }
    
    func storeObservation(_ observation: VNHumanBodyPoseObservation) {
        if posesWindow.count >= predictionWindowSize {
            posesWindow.removeFirst() // Remove the oldest observation if the posesWindow is full
        }
        
        posesWindow.append(observation) // Append the new observation to the posesWindow
    }
    
    func processObservation(_ observation: VNHumanBodyPoseObservation) {
        do {
            let recognizedPoints = try observation.recognizedPoints(forGroupKey: .all) // Get the recognized points for all groups
            
            var displayedPoints = recognizedPoints.map {
                CGPoint(x: $0.value.x, y: 1 - $0.value.y) // Adjust the coordinates of recognized points for display
            }
            delegate?.predictor(self, didFindNewRecognizedPoints: displayedPoints) // Notify the delegate about the recognized points
        } catch {
            print("error finding recognizedPoints")
        }
    }
}
