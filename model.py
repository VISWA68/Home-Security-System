import cv2
import pickle
import numpy as np
from deepface import DeepFace
import pandas as pd

REGISTERED_FACES_DB = "registered_faces.pkl"

def register_face(image_path, user_name):
    """Register a new user's face by saving their face embedding."""
    try:
        embedding = DeepFace.represent(img_path=image_path, model_name="Facenet")[0]["embedding"]

        try:
            with open(REGISTERED_FACES_DB, "rb") as f:
                registered_faces = pickle.load(f)
        except (FileNotFoundError, EOFError):
            registered_faces = {}

        registered_faces[user_name] = embedding
        with open(REGISTERED_FACES_DB, "wb") as f:
            pickle.dump(registered_faces, f)

        print(f"Face registered successfully for {user_name}!")
    except Exception as e:
        print(f"Error in face registration: {e}")

def recognize_and_anti_spoof():
    """Recognize registered users and check for spoofing in real-time."""
    try:
        with open(REGISTERED_FACES_DB, "rb") as f:
            registered_faces = pickle.load(f)
    except (FileNotFoundError, EOFError):
        print("[ERROR] No registered faces found! Register a face first.")
        return

    cap = cv2.VideoCapture(0)

    while True:
        ret, frame = cap.read()
        if not ret or frame is None:
            print("[ERROR] Frame capture failed!")
            continue

        temp_path = "temp_frame.jpg"
        cv2.imwrite(temp_path, frame)

        try:
            try:
                DeepFace.analyze(
                    img_path=temp_path, 
                    actions=['emotion', 'race'], 
                    enforce_detection=False, 
                    anti_spoofing=True  
                )
            except ValueError as ve:
                if "Spoof detected" in str(ve):
                    label = "[ALERT] Spoofing Detected!"
                    color = (0, 0, 255)  
                    print(label)
                    cv2.putText(frame, label, (30, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)
                    cv2.imshow("Smart Home Security", frame)
                    continue
                else:
                    raise ve  
            face_data = DeepFace.represent(img_path=temp_path, model_name="Facenet", enforce_detection=False)

            if face_data and len(face_data) > 0:
                face_embedding = face_data[0]["embedding"]

                best_match = None
                min_distance = float("inf")

                for user, reg_embedding in registered_faces.items():
                    distance = np.linalg.norm(np.array(face_embedding) - np.array(reg_embedding))

                    if distance < min_distance:
                        min_distance = distance
                        best_match = user

                if min_distance < 10: 
                    label = f"[ACCESS GRANTED] Welcome {best_match}"
                    color = (0, 255, 0) 
                else:
                    label = "[WARNING] Unknown Face!"
                    color = (255, 0, 0)  
                cv2.putText(frame, label, (30, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)

            cv2.imshow("Smart Home Security", frame)

        except Exception as e:
            print(f"[ERROR] Issue processing frame: {str(e)}")

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

def detect_face_from_image(image_path):
    """Detects a face in an image and verifies if it is registered, with anti-spoofing."""

    try:
        with open(REGISTERED_FACES_DB, "rb") as f:
            registered_faces = pickle.load(f)
    except (FileNotFoundError, EOFError):
        print("No registered faces found! Register a face first.")
        return

    try:
        try:
            result = DeepFace.analyze(
                img_path=image_path, 
                actions=['emotion', 'race'], 
                enforce_detection=False, 
                anti_spoofing=True  
            )
        except ValueError as ve:
            if "Spoof detected" in str(ve):
                print("[ALERT] Spoofing Detected! Access Denied.")
                return
            else:
                raise ve  

        face_data = DeepFace.represent(img_path=image_path, model_name="Facenet", enforce_detection=False)

        if face_data and len(face_data) > 0:
            face_embedding = face_data[0]["embedding"]

            best_match = None
            min_distance = float("inf")

            for user, reg_embedding in registered_faces.items():
                distance = np.linalg.norm(np.array(face_embedding) - np.array(reg_embedding))

                if distance < min_distance:
                    min_distance = distance
                    best_match = user

            if min_distance < 10:  
                print(f"Access Granted: {best_match}")
            else:
                print("Unknown Face! Access Denied.")
        else:
            print("[WARNING] No faces detected in the image!")

    except Exception as e:
        print(f"[ERROR] An issue occurred: {str(e)}")

# Example Usage
# Register a face (Run this once per user)
# register_face("C:/Users/viswa/Downloads/viswa_img.jpg", "Viswa") 

# Run real-time detection & anti-spoofing
#recognize_and_anti_spoof()

# Detect from an image
detect_face_from_image("C:/Users/viswa/Downloads/viswa_img.jpg")
