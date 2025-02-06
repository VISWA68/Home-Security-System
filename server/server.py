import cv2
import pickle
import numpy as np
import asyncio
from deepface import DeepFace
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, File, Form, UploadFile
import json
import os

app = FastAPI()

REGISTERED_FACES_DB = "registered_faces.pkl"
clients = set()

def load_registered_faces():
    """Load registered faces from the database."""
    try:
        with open(REGISTERED_FACES_DB, "rb") as f:
            return pickle.load(f)
    except (FileNotFoundError, EOFError):
        return {}

def save_registered_faces(data):
    """Save registered faces to the database."""
    with open(REGISTERED_FACES_DB, "wb") as f:
        pickle.dump(data, f)

@app.post("/register")
async def register_face(
    images: list[UploadFile] = File(...),
    user_name: str = Form(...)
):
    """Register a new face using multiple images."""
    try:
        embeddings = []
        for image in images:
            temp_path = f"temp_{image.filename}"
            with open(temp_path, "wb") as buffer:
                content = await image.read()
                buffer.write(content)

            face_data = DeepFace.represent(img_path=temp_path, model_name="Facenet", enforce_detection=False)
            if face_data:
                embeddings.append(face_data[0]["embedding"])

            os.remove(temp_path)

        if not embeddings:
            return {"error": "No face detected in the uploaded images."}

        avg_embedding = np.mean(embeddings, axis=0).tolist()

        registered_faces = load_registered_faces()
        if user_name in registered_faces:
            return {"warning": f"{user_name} is already registered. Updating face data."}

        registered_faces[user_name] = avg_embedding
        save_registered_faces(registered_faces)

        return {"success": f"Face registered successfully for {user_name}!"}
    
    except Exception as e:
        return {"error": f"Face registration failed: {str(e)}"}

@app.delete("/delete")
async def delete_user(user_name: str):
    """Delete a registered face."""
    registered_faces = load_registered_faces()

    if user_name not in registered_faces:
        return {"success": f"User '{user_name}' not found in the database."}

    del registered_faces[user_name]
    save_registered_faces(registered_faces)
    return {"success": f"User '{user_name}' has been deleted."}

async def recognize_and_anti_spoof(websocket: WebSocket):
    """Real-time face recognition & spoof detection with live video feed."""
    registered_faces = load_registered_faces()

    if not registered_faces:
        await websocket.send_text(json.dumps({"error": "No registered faces found!"}))
        return

    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        await websocket.send_text(json.dumps({"error": "Failed to access webcam"}))
        return

    try:
        while True:
            ret, frame = cap.read()
            if not ret or frame is None:
                await websocket.send_text(json.dumps({"error": "Frame capture failed!"}))
                continue

            temp_path = "temp_frame.jpg"
            cv2.imwrite(temp_path, frame)

            try:
                try:
                    DeepFace.analyze(img_path=temp_path, actions=['emotion', 'race'], enforce_detection=False, anti_spoofing=True)
                except ValueError as ve:
                    if "Spoof detected" in str(ve):
                        await websocket.send_text(json.dumps({"alert": "Spoofing Detected!"}))
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
                        result = {"status": "Access Granted", "user": best_match}
                    else:
                        result = {"status": "Unknown Face"}

                    await websocket.send_text(json.dumps(result))

                # Display the live feed with the recognition result
                cv2.putText(frame, result["status"], (30, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2, cv2.LINE_AA)
                cv2.imshow("Live Face Recognition", frame)

                # Check for user input to stop detection
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    await websocket.send_text(json.dumps({"info": "Detection stopped by user"}))
                    break

            except Exception as e:
                await websocket.send_text(json.dumps({"error": str(e)}))

        cap.release()
        cv2.destroyAllWindows()

    except WebSocketDisconnect:
        print("Client disconnected, stopping detection.")
        cap.release()
        cv2.destroyAllWindows()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket connection handler for real-time recognition."""
    await websocket.accept()
    clients.add(websocket)

    try:
        while True:
            data = await websocket.receive_text()
            command = json.loads(data)

            if command.get("action") == "start":
                await recognize_and_anti_spoof(websocket)
            elif command.get("action") == "stop":
                await websocket.send_text(json.dumps({"info": "Detection stopped by client"}))
                break

    except WebSocketDisconnect:
        print("Client disconnected")

    finally:
        clients.remove(websocket)
