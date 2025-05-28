# 📱 HealthCard

**HealthCard** is an iOS application designed to measure key health vitals—**heart rate** and **respiratory rate**—using just the smartphone camera. Built using **Swift**, the app applies camera-based signal processing techniques to deliver non-invasive, real-time wellness monitoring.

> ⚠️ This app is intended for wellness tracking only and not for medical or diagnostic purposes.

---

## 🔍 Features

- 📸 Measure **Heart Rate (BPM)** using the rear camera + flashlight.
- 🌬️ Estimate **Respiratory Rate** via camera-based motion tracking.
- 📈 Visualize your vitals in an intuitive UI.
- 🔄 Sync data securely with **Apple HealthKit**.
- 💡 Built using native iOS frameworks for performance and privacy.

---

## 🧠 How It Works

### ❤️ Heart Rate Monitoring
- Uses **Photoplethysmography (PPG)**: detects changes in blood volume by capturing the red light absorbed through the fingertip.
- Extracts red-channel intensity from each video frame.
- Processes signals using filtering and peak detection to calculate **BPM**.

### 🌬️ Respiratory Rate Estimation
- Uses either:
  - **Chest movement analysis** via front camera video.
  - Or **breathing pattern modulations** observed in the PPG signal.
- Measures inhalation/exhalation cycles per minute.

---

## 🛠️ Technologies Used

- **Swift (UIKit)**
- **AVFoundation** – for camera access and video processing
- **CoreImage** – for frame-by-frame analysis
- **Accelerate** – for efficient signal processing
- **HealthKit** – for syncing and storing health data securely

---

## 🚀 Future Enhancements

We are working on expanding the app with AI-powered analytics to:
- ⏱ Predict early signs of potential health issues
- 🛡 Provide personalized health advice and precautions
- 🔔 Alert users for preventive action before symptoms arise

---

## 📦 Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/HealthCard.git
