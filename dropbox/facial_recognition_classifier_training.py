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
    faces = []
    labels = []
    for person in os.listdir(dataset_dir):
        person_dir = os.path.join(dataset_dir, person)
        if os.path.isdir(person_dir):
            for image_file in os.listdir(person_dir):
                image_path = os.path.join(person_dir, image_file)
                faces.append(image_path)
                labels.append(person)
    return faces, labels

dataset_dir = 'C:\\Users\\brsteel\\Downloads\\dataset'
#dataset_dir  = 'C:\\Users\\brsteel\\Downloads\\dataset-processed'
faces, labels = LoadFacesLabels(dataset_dir)



# %%
def DetectAndResizeFaces(faces, dataset_dir):
    detector = MTCNN()
    failed_images = []
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
                person_dir = os.path.join(processed_dir, os.path.basename(os.path.dirname(face_path)))
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
DetectAndResizeFaces(faces, dataset_dir)
dataset_dir = processed_dir

# %%
def GenerateEmbeddings(dataset_dir, embeddings_dir):
    faces, _ = LoadFacesLabels(dataset_dir)
    embeddings = []
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
myembeddings = GenerateEmbeddings(dataset_dir, embeddings_dir)
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

