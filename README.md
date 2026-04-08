<div align="center">
  <img src="https://raw.githubusercontent.com/hamedtareqhamed/UniTask/main/unitask_logo_2.png" alt="UniTask Logo" width="150" height="auto" />
  <h1>UniTask</h1>
  <p><strong>Your Ultimate University Companion App</strong></p>
  
  [![Flutter](https://img.shields.io/badge/Made_with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Powered_by-Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
  [![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)]()
</div>

<hr />

## 📖 About The Project

**UniTask** is a comprehensive academic tracking and management system designed to make university life seamless. Built from the ground up with a cross-platform architecture, it allows students to track their coursework, predict their GPA, maintain weekly schedules, and sync all their data securely to the cloud.

### ✨ Key Features

*   📚 **Course & Semester Management**: Organize your university journey semester by semester with dedicated metrics and customized grade weighting.
*   📊 **Smart GPA Predictor**: Dynamically calculates your current GPA and assesses minimum/maximum potential scores based on pending coursework (`Pass/Fail` logic included).
*   📅 **Interactive Calendar & Weekly Schedule**: Visual layout of all your exams, assignments deadlines, and repeating course lectures.
*   ☁️ **Cloud Backup & Restore**: Robust synchronization with Google Firebase, featuring intelligent merging that prevents data overwriting across devices.
*   💼 **Admin Dashboard**: Powerful standalone Admin Console built utilizing FireCMS, empowering system administrators to seamlessly manage catalogs and templates.
*   📱 **Cross-Platform Delivery**: Supports iOS, Android, and Web platforms natively. Fully automated CI/CD pipelines generate production artifacts (IPA, APK, AAB, ZIP) automatically upon new releases.

---

## 🛠️ Technology Stack

*   **Frontend**: Flutter / Dart
*   **Backend & Database**: Firebase Authentication, Cloud Firestore
*   **Admin Console**: FireCMS (React / Vite)
*   **CI/CD Pipeline**: GitHub Actions
*   **State Management / Architecture**: (Add your architecture here, e.g., Provider/Riverpod)

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (v3.x or higher)
*   Firebase Project setup internally via `.env` credentials

### Installation (Local Development)
1. Clone the repository:
   ```bash
   git clone https://github.com/hamedtareqhamed/UniTask.git
   cd UniTask
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Prepare the environment variables (`.env` file required at root).
4. Run the project:
   ```bash
   flutter run
   ```

---

## 👤 Author

**hamed albazeli**
- GitHub: [@hamedtareqhamed](https://github.com/hamedtareqhamed)

## 📜 Copyright
**© 2026 hamed albazeli. All rights reserved.**

This project and its source code are strictly private and proprietary. No license is granted for reading, copying, modifying, compiling, or distributing this code without explicit prior permission from the author.
