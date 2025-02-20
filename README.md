# 🏠🔒 Smart Home Security System  
_A Secure, AI-Powered Face Recognition System for Home Automation_  

## 📌 Overview  
The Smart Home Security System is an advanced security solution that leverages AI-driven **anti-spoofing face detection** to allow only registered users to access the home. The system ensures **high security** by preventing spoofing attacks using images, videos, or masks. It also supports **dynamic face enrollment and deletion**, allowing users to update their access control seamlessly.  

## ✨ Features  
✅ **Anti-Spoofing Face Detection** - Prevents unauthorized access using images, videos, or masks.  
✅ **Registered Face Detection** - Only recognized users can unlock and access the system.  
✅ **Dynamic Face Enrollment & Deletion** - Users can register or remove faces anytime.  
✅ **Real-time Monitoring** - Detects faces in real-time and alerts for unregistered access attempts.  
✅ **Secure Access Control** - Ensures safety by restricting entry to verified individuals.  

## 🏗️ Tech Stack  
- **Frontend:** Flutter (Mobile App for User Control)  
- **Backend:** Flask (Face Recognition & Security Processing)  
- **Machine Learning:** Anti-Spoofing & Face Detection Model (CNN, OpenCV, TensorFlow)  
- **Database:** SQLite  

## 🚀 Installation & Setup  

### Prerequisites  
Ensure you have the following installed:  
- Flutter SDK  
- Python (with Flask and required dependencies)  
- Camera Module for Face Detection (if running on hardware)  

### Steps  

1. **Clone the Repository**
   ```bash
   git clone https://github.com/VISWA68/SignLanguage-App.git
   cd server
   ```
2. **Setup the Backend**
   - Navigate to the `backend` folder.
   - Install dependencies:
     ```bash
     pip install -r requirements.txt
     ```
   - Run the server:
     ```bash
     python app.py
     ```

3. **Setup the Frontend**
   - Navigate to the `security_app` folder.
   - Install dependencies:
     ```bash
     flutter pub get
     ```
   - Run the app:
     ```bash
     flutter run
     ```
