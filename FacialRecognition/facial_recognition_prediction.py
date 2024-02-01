# %%
from deepface import DeepFace
import cv2
import numpy as np
import pickle
import os
from mtcnn import MTCNN
from PIL import Image

def getLabels(dataset_dir):
    labels = {}
    for person in os.listdir(dataset_dir):
        person_dir = os.path.join(dataset_dir, person)
        if os.path.isdir(person_dir):
            labels[person] = len(labels)
    return labels

def DetectAndResizeFace(face_path):
    # Load the image
    image = Image.open(face_path)
    image = image.convert("RGB")
    image = np.array(image)
    
    # Initialize the face detector
    detector = MTCNN()
    
    # Detect faces in the image
    result = detector.detect_faces(image)
    
    # If a face is detected
    if result:
        # Get the bounding box coordinates of the face
        x1, y1, width, height = result[0]['box']
        x2, y2 = x1 + width, y1 + height
        
        # Extract the face from the image
        face_image = image[y1:y2, x1:x2]
        
        # Resize the face image to 152x152
        face_image = cv2.resize(face_image, (152, 152))
        
        return face_image
    else:
        print(f"No face detected in {face_path}")
        return None

def recognize_face(face_image):

    # Load the trained classifier
    with open('trained_classifier.pkl', 'rb') as file:
        classifier = pickle.load(file)
    
    result = DeepFace.represent(img_path=face_image, model_name='Facenet', enforce_detection=False)
    
    # Check if result is a list
    if isinstance(result, list):
        # If result is a list, get the first item in the list
        result = result[0]
    
    embedding = result['embedding']
    prediction = classifier.predict_proba([np.array(embedding)])
    predicted_label = [name for name, label in labels.items() if label == np.argmax(prediction)]
    
    # Format the probabilities
    formatted_probabilities = ["{:.4f}".format(proba) for proba in prediction[0]]
    
    print(f"Predicted label: {predicted_label}, Prediction probabilities: {formatted_probabilities}")
    
    # Write the predicted label to a text file in the test_dataset directory
    with open(os.path.join(os.path.dirname(testimage_dir), 'predicted_labels.txt'), 'a') as file:
        file.write(f"{os.path.basename(testimage_dir)}: {predicted_label}\n")
        
    return predicted_label


dataset_dir = 'C:\\Users\\brsteel\\Downloads\\test_dataset'
labels_dir = 'C:\\Users\\brsteel\\Downloads\\dataset'

for testimage in os.listdir(dataset_dir):
    testimage_dir = os.path.join(dataset_dir, testimage)
    face_image = DetectAndResizeFace(testimage_dir)
    if face_image is not None:
        recognize_face(face_image)

# %%
