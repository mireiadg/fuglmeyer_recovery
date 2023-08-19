import os
import cv2
import numpy as np
import tensorflow as tf
import tensorflow_hub as hub

# Load the PoseNet model
pose_model = hub.load("https://tfhub.dev/tensorflow/tfjs-model/posenet/mobilenet/float/075/1/default/1")

dataset_directory = '/Users/mireiadegracia/Documents/UNI/Fugl Recovery 2/new_dataset_clips/'

# Placeholder for our data
sequences = []
labels = []

# Iterate through each folder in the dataset directory
for label, folder in enumerate(os.listdir(dataset_directory)):
    if folder != '.DS_Store':
        for video_name in os.listdir(os.path.join(dataset_directory, folder)):
            video_path = os.path.join(dataset_directory, folder, video_name)
            
            if video_path.lower().endswith(('.mp4', '.avi', '.mov')):
                cap = cv2.VideoCapture(video_path)
                
                sequence = []
                previous_keypoints = None
                
                while cap.isOpened():
                    ret, frame = cap.read()
                    if not ret:
                        break

                    frame_resized = cv2.resize(frame, (257, 257))
                    frame_normalized = (frame_resized / 255.0).astype(np.float32)
                    frame_expanded = np.expand_dims(frame_normalized, axis=0)
                    
                    # Using the model as a callable function
                    outputs = pose_model(frame_expanded)
                    keypoints = outputs['output_0']
                    
                    # If we have previous keypoints, compute the difference
                    if previous_keypoints is not None:
                        keypoint_diff = keypoints - previous_keypoints
                        sequence.append(keypoint_diff.numpy())
                    
                    previous_keypoints = keypoints
                
                cap.release()
                
                # Append the sequence and label
                if len(sequence) > 0:
                    sequences.append(sequence)
                    labels.append(label)

# Convert sequences and labels to numpy arrays
sequences = np.array(sequences, dtype=object)
labels = np.array(labels)

# LSTM for movement classification
classifier = tf.keras.Sequential([
    tf.keras.layers.LSTM(64, input_shape=(None, sequences[0][0].shape[-1])),
    tf.keras.layers.Dense(4, activation='softmax')  # Assuming you have 4 movement classes
])

classifier.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
classifier.fit(sequences, labels, epochs=10, validation_split=0.2)
