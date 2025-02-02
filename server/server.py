from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import cv2
import pickle
import numpy as np
from deepface import DeepFace
import base64

app = Flask(__name__)
CORS(app)

REGISTERED_FACES_DB = "registered_faces.pkl"
UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

def save_base64_image(base64_string, filename):
    img_data = base64.b64decode(base64_string.split(',')[1] if ',' in base64_string else base64_string)
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    with open(filepath, 'wb') as f:
        f.write(img_data)
    return filepath

@app.route('/register_face', methods=['POST'])
def register_face_endpoint():
    try:
        data = request.json
        if not data or 'image' not in data or 'username'({'error': 'Missing image or username'}):400

        image_path = save_base64_image(data['image'], f"{data['username']}.jpg")
        
        embedding = DeepFace.represent(img_path=image_path, model_name="Facenet")[0]["embedding"]
        
        try:
            with open(REGISTERED_FACES_DB, "rb") as f:
                registered_faces = pickle.load(f)
        except (FileNotFoundError, EOFError):
            registered_faces = {}
            
        registered_faces[data['username']] = embedding
        
        with open(REGISTERED_FACES_DB, "wb") as f:
            pickle.dump(registered_faces, f)
            
        return jsonify({'message': f"Face registered successfully for {data['username']}!"})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/detect_face', methods=['POST'])
def detect_face_endpoint():
    try:
        data = request.json
        if not data or 'image'({'error': 'Missing image'}): 400

        image_path = save_base64_image(data['image'], 'temp_detection.jpg')
        
        try:
            with open(REGISTERED_FACES_DB, "rb") as f:
                registered_faces = pickle.load(f)
        except (FileNotFoundError, EOFError):
            return jsonify({'error': 'No registered faces found!'}), 404

        try:
            # Anti-spoofing check
            DeepFace.analyze(
                img_path=image_path,
                actions=['emotion', 'race'],
                enforce_detection=False,
                anti_spoofing=True
            )
        except ValueError as ve:
            if "Spoof detected" in str(ve):
                return jsonify({'error': 'Spoofing detected!'}), 400
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
                return jsonify({'message': f'Access Granted: {best_match}', 'user': best_match})
            else:
                return jsonify({'error': 'Unknown Face! Access Denied.'}), 401
        else:
            return jsonify({'error': 'No faces detected in the image!'}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
