import tensorflow as tf
import tensorflow_hub as hub
import cv2
import os

# Load the MoveNet "thunder" model from TensorFlow Hub
#model_url = "https://tfhub.dev/google/movenet/singlepose/thunder/1"
model_url = "https://tfhub.dev/google/movenet/singlepose/lightning/4"
model = hub.load(model_url)

def movenet(input_image):
    input_tensor = tf.image.convert_image_dtype(input_image, dtype=tf.int32)[tf.newaxis, ...]
    keypoints_with_scores = model.signatures['serving_default'](input_tensor)
    return keypoints_with_scores['output_0']

def process_video(video_path):
    cap = cv2.VideoCapture(video_path)
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        
        # Convert the BGR image to RGB
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        #for thunder:
        #frame_rgb = cv2.resize(frame_rgb, (256,256))
        #for lightning:
        frame_rgb = cv2.resize(frame_rgb, (192,192))
        # Predict the pose
        keypoints_with_scores = movenet(frame_rgb)
        keypoints = keypoints_with_scores[0].numpy()[0, :, :2]
        
        # Visualize the keypoints on the image
        for kp in keypoints:
            y, x = kp
            cv2.circle(frame, (int(x * frame.shape[1]), int(y * frame.shape[0])), 3, (0, 255, 0), -1)
        
        cv2.imshow("MoveNet Pose Estimation", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

# Assuming your dataset is organized as "base_dir/ClassName/video_file.mp4"
base_dir = "/Users/mireiadegracia/Documents/UNI/Fugl Recovery 2/new_dataset_clips"
for class_folder in os.listdir(base_dir):
    if class_folder != '.DS_Store':

        class_path = os.path.join(base_dir, class_folder)
    
        for video_file in os.listdir(class_path):
            if video_file != '.DS_Store':
                video_path = os.path.join(class_path, video_file)
                process_video(video_path)
