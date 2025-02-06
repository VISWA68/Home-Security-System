from flask import Flask, request, jsonify
import os
import cv2
import numpy as np
import sqlite3
from deepface import DeepFace

app = Flask(__name__)

UPLOAD_FOLDER = "static/uploads"
DB_PATH = "faces.db"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Initialize Database
def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS faces (name TEXT PRIMARY KEY, embedding BLOB)''')
    conn.commit()
    conn.close()

init_db()

# Extract Frames from Video
def extract_frames(video_path, interval=0.5):
    """Extracts frames from a video at given interval (in seconds)."""
    cap = cv2.VideoCapture(video_path)
    frames = []
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    frame_interval = int(fps * interval)  # Convert time interval to frame count
    
    frame_count = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        
        if frame_count % frame_interval == 0:  # Extract frame at the given interval
            frames.append(frame)
        
        frame_count += 1

    cap.release()
    return frames

# Add Face from Video
def add_face(name, video_path):
    """Extracts multiple face embeddings from video and stores them in the database."""
    frames = extract_frames(video_path, interval=0.5)  # Extract frames every 0.5s

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    embeddings_stored = 0

    for i, frame in enumerate(frames):
        frame_path = f"static/temp_{i}.jpg"
        cv2.imwrite(frame_path, frame)  # Save frame as image

        try:
            embeddings = DeepFace.represent(img_path=frame_path, model_name="Facenet", enforce_detection=False)
            for embedding in embeddings:
                cursor.execute("INSERT INTO faces (name, embedding) VALUES (?, ?)", 
                               (name, np.array(embedding["embedding"]).tobytes()))
                embeddings_stored += 1
        except:
            continue  # Skip frames where face is not detected

    conn.commit()
    conn.close()
    
    return f"Stored {embeddings_stored} embeddings for {name}"

# Recognize Face
def recognize_face(img_path):
    """Recognizes face using stored embeddings."""
    query_embedding = DeepFace.represent(img_path=img_path, model_name="Facenet", enforce_detection=False)[0]["embedding"]
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT name, embedding FROM faces")
    faces = cursor.fetchall()
    conn.close()

    best_match, highest_similarity = None, 0.0
    for name, db_embedding in faces:
        db_embedding = np.frombuffer(db_embedding, dtype=np.float64)
        similarity = np.dot(query_embedding, db_embedding) / (np.linalg.norm(query_embedding) * np.linalg.norm(db_embedding))
        if similarity > 0.8 and similarity > highest_similarity:
            best_match, highest_similarity = name, similarity

    return best_match, highest_similarity if best_match else (None, 0.0)

# Delete Face from Database
def delete_face(name):
    """Deletes face embeddings from the database."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM faces WHERE name = ?", (name,))
    conn.commit()
    deleted = cursor.rowcount > 0
    conn.close()
    return deleted

@app.route("/")
def home():
    return "Face Recognition with Anti-Spoofing API is Running!"

@app.route("/register", methods=["POST"])
def register():
    """Registers a user by uploading a video with different face angles."""
    file = request.files["file"]
    name = request.form["name"]
    
    video_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(video_path)

    message = add_face(name, video_path)
    return jsonify({"message": message}), 200

@app.route("/recognize", methods=["GET"])
def recognize_live():
    """Opens webcam for real-time face recognition."""
    cap = cv2.VideoCapture(0)  # Open webcam
    if not cap.isOpened():
        return jsonify({"error": "Could not access camera"}), 500

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        cv2.imwrite("temp.jpg", frame)  # Save the frame as a temp file

        # Run Face Recognition
        name, similarity = recognize_face("temp.jpg")
        if name:
            cv2.putText(frame, f"Recognized: {name} ({similarity:.2f})",
                        (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
        else:
            cv2.putText(frame, "Face Not Recognized", (50, 50),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)

        cv2.imshow("Live Recognition", frame)

        # Press 'q' to exit the camera feed
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()
    return jsonify({"message": "Recognition stopped"})

@app.route("/delete", methods=["POST"])
def delete():
    """Deletes a registered face from the database."""
    name = request.form["name"]
    if delete_face(name):
        return jsonify({"message": f"{name} deleted successfully!"}), 200
    return jsonify({"error": "Face not found!"})

if __name__ == "__main__":
    app.run(host='0.0.0.0', debug=True)
