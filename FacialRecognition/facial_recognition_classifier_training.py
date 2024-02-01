# %%
from deepface import DeepFace
import pickle
from mtcnn import MTCNN
from sklearn.svm import SVC
import cv2
import os
import numpy as np
from PIL import Image
import json

# %%
def LoadFacesLabels(dataset_dir):
    label_to_faces = {}
    for person in os.listdir(dataset_dir):
        person_dir = os.path.join(dataset_dir, person)
        if os.path.isdir(person_dir):
            for image_file in os.listdir(person_dir):
                image_path = os.path.join(person_dir, image_file)
                if person not in label_to_faces:
                    label_to_faces[person] = []
                label_to_faces[person].append(image_path)
    return label_to_faces

dataset_dir = 'C:\\Users\\brsteel\\Downloads\\dataset'
label_to_faces = LoadFacesLabels(dataset_dir)

# Display the label to faces mapping
for label, faces in label_to_faces.items():
    print(f"Label: {label}")
    for face in faces:
        print(f"\t{face}")



# %%
def DetectAndResizeFaces(label_to_faces, dataset_dir):
    detector = MTCNN()
    failed_images = []
    for label, faces in label_to_faces.items():
        for face_path in faces:
            image = Image.open(face_path)
            image = image.convert("RGB")
            image = np.array(image)
            try:
                result = detector.detect_faces(image)
                if result:
                    x1, y1, width, height = result[0]['box']
                    x2, y2 = x1 + width, y1 + height
                    face_image = image[y1:y2, x1:x2]
                    face_image = cv2.resize(face_image, (152, 152))
                    
                    # Save the resized face image to a separate directory structure
                    processed_dir = os.path.join(os.path.dirname(dataset_dir), 'dataset-processed')
                    person_dir = os.path.join(processed_dir, label)
                    os.makedirs(person_dir, exist_ok=True)
                    cv2.imwrite(os.path.join(person_dir, os.path.basename(face_path)), face_image)
                else:
                    failed_images.append(face_path)
            except ValueError:
                failed_images.append(face_path)
    failed_images_file = os.path.join(os.path.dirname(dataset_dir), 'failed_images.txt')
    with open(failed_images_file, 'w') as file:
        for image_path in failed_images:
            file.write(f"{image_path}\n")
    return processed_dir

dataset_dir = 'C:\\Users\\brsteel\\Downloads\\dataset'
processed_dir = DetectAndResizeFaces(label_to_faces, dataset_dir)


# %%
def GenerateEmbeddings(label_to_faces, dataset_dir, embeddings_dir):
    embeddings = []
    for label, faces in label_to_faces.items():
        for face_path in faces:
            # Create a similar directory structure in embeddings_dir
            relative_path = os.path.relpath(face_path, dataset_dir)
            embedding_path = os.path.join(embeddings_dir, relative_path + '.txt')

            # Check if embedding already exists
            if os.path.exists(embedding_path) and os.path.getsize(embedding_path) > 0:
                with open(embedding_path, 'r') as f:
                    embedding = np.array(json.load(f))
            else:
                face_image = cv2.imread(face_path)
                result = DeepFace.represent(img_path=face_image, model_name='Facenet', enforce_detection=False)
                # Check if result is a list
                if isinstance(result, list):
                    # If result is a list, get the first item in the list
                    result = result[0]
                embedding = result['embedding']

                # Save the embedding to a file
                os.makedirs(os.path.dirname(embedding_path), exist_ok=True)
                with open(embedding_path, 'w') as f:
                    json.dump(embedding, f)

            embeddings.append(np.array(embedding))
    return embeddings

dataset_dir  = 'C:\\Users\\brsteel\\Downloads\\dataset-processed'
embeddings_dir = 'C:\\Users\\brsteel\\Downloads\\embeddings'
label_to_faces = LoadFacesLabels(dataset_dir)
myembeddings = GenerateEmbeddings(label_to_faces, dataset_dir, embeddings_dir)
print(len(myembeddings))





# %%
def LoadEmbeddings(embeddings_dir):
    embeddings = []
    labels = []
    for root, dirs, files in os.walk(embeddings_dir):
        for file in files:
            if file.endswith('.txt'):
                with open(os.path.join(root, file), 'r') as f:
                    embedding = np.array(json.load(f))
                    embeddings.append(embedding)
                    # Assuming the label is the name of the parent directory
                    label = os.path.basename(os.path.dirname(os.path.join(root, file)))
                    labels.append(label)
    return embeddings, labels

def ClassifyFaces(embeddings_dir):
    embeddings, labels = LoadEmbeddings(embeddings_dir)
    print("Starting the training process...")
    classifier = SVC(kernel='rbf', probability=True)
    classifier.fit(embeddings, labels)
    print("Training completed successfully.")
    with open('trained_classifier.pkl', 'wb') as file:
        pickle.dump(classifier, file)
    print("The trained classifier has been saved to 'trained_classifier.pkl'.")

embeddings_dir = 'C:\\Users\\brsteel\\Downloads\\embeddings'
ClassifyFaces(embeddings_dir)


# %%
def getLabels(labels_dir):
    labels = {}
    for person in os.listdir(labels_dir):
        person_dir = os.path.join(labels_dir, person)
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
    
     #select the highest probability
    highest_probability = max(formatted_probabilities)

    print(f"Predicted label: {predicted_label}, Highest prediction probability: {highest_probability}")

    # Write the predicted label and the highest probability to a text file in the test_dataset directory
    with open(os.path.join(os.path.dirname(testimage_dir), 'predicted_labels.txt'), 'a') as file:
        file.write(f"{os.path.basename(testimage_dir)}: {predicted_label}, Highest prediction probability: {highest_probability}\n")

    return predicted_label

# Clean up previous predictions, if exist
# Define the path to the file
file_path = os.path.join(os.path.dirname(dataset_dir), 'predicted_labels.txt')

# Delete the file if it exists
if os.path.exists(file_path):
    os.remove(file_path)

dataset_dir = 'C:\\Users\\brsteel\\Downloads\\test_dataset'
labels_dir = 'C:\\Users\\brsteel\\Downloads\\dataset'

labels = getLabels(labels_dir)

for testimage in os.listdir(dataset_dir):
    testimage_dir = os.path.join(dataset_dir, testimage)
    face_image = DetectAndResizeFace(testimage_dir)
    if face_image is not None:
        recognize_face(face_image)
# %%
