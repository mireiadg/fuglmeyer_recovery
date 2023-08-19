#FuglMeyerApp

##Overview

FuglMeyerApp is an iOS application that utilizes computer vision and audio playback to detect specific body movements included in the Fugl Meyer assesment for stroke recovery, and provide audio feedback when actions are completed. The app captures video from the device's front camera, processes it to estimate body positions, and plays corresponding audio sounds based on the detected movements.

The codebase consists of three main components:

1. **ViewController.swift**: This file contains the main view controller class responsible for managing the app's user interface and coordinating interactions with the video capture and prediction components.

2. **Predictor.swift**: The Predictor class is responsible for analyzing the body pose observations received from the video capture and making predictions about the detected actions. It utilizes a trained machine learning model (*FMClassifier*) to label the actions and calculates the confidence level for each prediction. It also delegates the recognized points to the ViewController for visualization.

3. **VideoCapture.swift**: The VideoCapture class handles the capture of video data from the device's front camera. It configures an AVCaptureSession to manage the input (camera) and output (video data) and sets up an AVCaptureVideoDataOutput to receive the video frames. It also delegates the received sample buffers to the Predictor for pose estimation.

##Dependencies

- AVFoundation: Used for capturing video data, audio playback, and managing AVAudioPlayer instances.
- Vision: Provides support for body pose estimation using VNHumanBodyPoseObservation.
- CoreML: Enables the integration and utilization of a trained machine learning model (FMClassifier) for action prediction.

##Getting Started

To run the FuglMeyerApp, follow these steps:

1. Clone the repository to your local machine.
2. Open the project in Xcode.
3. Build and run the app on your iOS device or simulator.
4. Grant permission for the app to access the camera.

##Behavior

1. When the app is launched, the ViewController's `viewDidLoad()`method is called, triggering the setup of the video preview and audio file preloading. The AVCaptureVideoPreviewLayer is added as a sublayer to the view, allowing real-time video display. Audio files for ear and lateral sounds are preloaded using AVAudioPlayer.

2. The `setupVideoPreview()`method initializes the video capture by starting the capture session and setting up the AVCaptureVideoPreviewLayer for previewing the captured video.

3. The `preloadAudioFiles()`method loads the ear and lateral sound files into AVAudioPlayer instances to be played later during action detection.

4. The ViewController conforms to the PredictorDelegate protocol, implementing the delegate methods `didFindNewRecognizedPoints()`and `didLabelAction()`. These methods are called by the Predictor when new recognized body points or labeled actions are available.

5. The Predictor class estimates body poses by receiving CMSampleBuffer objects through the `estimation(sampleBuffer:)`method. It uses Vision and Core ML to process the video frames and extract VNHumanBodyPoseObservation instances.

6. For each received VNHumanBodyPoseObservation, the recognized body points are extracted and transformed to display coordinates. The transformed points are then passed to the ViewController using the delegate method `didFindNewRecognizedPoints()`.

7. The Predictor maintains a window of VNHumanBodyPoseObservations for prediction purposes. When a new observation is received, it is added to the window, and the oldest observation is removed if the window reaches its maximum size (predictionWindowSize).

8. The Predictor uses a trained machine learning model (FMClassifier) to label the actions based on the stored observations in the window. The labeled action and its confidence level are sent to the ViewController using the delegate method `didLabelAction()`.

9. When an action is labeled and its confidence level exceeds the specified threshold, the ViewController triggers the corresponding behavior. If the action is "ear," the ear sound is played using the AVAudioPlayer for auditory feedback. If the action is "90lateral," the lateral sound is played.

10. A delay of 3 seconds is introduced after an action is detected to prevent rapid and repeated action triggering. The corresponding flag (isClapDetected or isArmDetected) is reset after the delay to allow the detection of subsequent actions.


##Notes

- The code provided is a simplified representation of the actual app and may require additional modifications and improvements to suit specific requirements.
- Ensure that the *FMClassifier*model is available and properly configured for accurate action predictions.
- Adjust the action confidence threshold and other parameters as needed to optimize the app's behavior.


