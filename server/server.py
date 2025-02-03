import cv2
import pickle
import numpy as np
import asyncio
from deepface import DeepFace
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import json

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
async def register_face(image_path: str, user_name: str):
    """Register a new face."""
    try:
        embedding = DeepFace.represent(img_path=image_path, model_name="Facenet")[0]["embedding"]
        registered_faces = load_registered_faces()

        if user_name in registered_faces:
            return {"warning": f"{user_name} is already registered. Updating face data."}
        
        registered_faces[user_name] = embedding
        save_registered_faces(registered_faces)
        return {"success": f"Face registered successfully for {user_name}!"}
    
    except Exception as e:
        return {"error": f"Face registration failed: {str(e)}"}

@app.delete("/delete")
async def delete_user(user_name: str):
    """Delete a registered face."""
    registered_faces = load_registered_faces()

    if user_name not in registered_faces:
        return {"error": f"User '{user_name}' not found in the database."}

    del registered_faces[user_name]
    save_registered_faces(registered_faces)
    return {"success": f"User '{user_name}' has been deleted."}

async def recognize_and_anti_spoof(websocket: WebSocket):
    """Real-time face recognition & spoof detection. Sends results via WebSocket."""
    registered_faces = load_registered_faces()

    if not registered_faces:
        await websocket.send_text(json.dumps({"error": "No registered faces found!"}))
        return

    cap = cv2.VideoCapture(0)

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
                    await websocket.send_text(json.dumps({"alert": "🚨 Spoofing Detected!"}))
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

        except Exception as e:
            await websocket.send_text(json.dumps({"error": str(e)}))

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket connection handler."""
    await websocket.accept()
    clients.add(websocket)

    try:
        while True:
            data = await websocket.receive_text()
            command = json.loads(data)

            if command.get("action") == "start":
                await recognize_and_anti_spoof(websocket)

    except WebSocketDisconnect:
        clients.remove(websocket)
        print("Client disconnected")

    finally:
        clients.remove(websocket)
