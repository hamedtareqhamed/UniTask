# UniTask - The Ultimate Student Companion

![UniTask Banner](assets/screenshots/dashboard.png)

**UniTask** is a powerful, beautifully designed Flutter application built to help university students manage their academic life with ease. From tracking grades with precision to managing deadlines with visual urgency, UniTask is your personal academic assistant.

## ✨ Features

### 📊 Advanced Grading System
- **Customizable Weights**: Set your Coursework vs. Final Project weights (e.g., 60/40) per course.
- **Absolute Point Tracking**: Track your grades based on actual points earned, not just confusing percentages.
- **Visual Breakdown**: See exactly where you stand with our custom circular charts showing points **Acquired**, **Lost**, and **Remaining**.

![Course Details](assets/screenshots/course_detail.png)

### 📅 Smart Academic Calendar
- **Busy Window Detection**: The calendar automatically highlights "Busy Windows" (5+ deadlines in 5 days) in red, giving you a heads-up on tough weeks.
- **Deadline Management**: Never miss a due date with clear, color-coded urgency indicators.

![Calendar](assets/screenshots/calendar.png)

### 🚀 Productivity Dashboard
- **Session Timer**: Keep track of your study sessions.
- **Visual Progress**: Track your overall task completion and academic progress at a glance.
- **Quick Actions**: Add tasks and assessments in seconds.

## 🛠️ Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/unitask.git
    cd unitask
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the app**:
    ```bash
    flutter run
    ```

## 📱 Usage

1.  **Add Courses**: Go to the "Courses" tab and add your subjects. Set the grading weights (e.g., 60 points for Coursework, 40 for Final).
2.  **Add Assessments**: Inside a course, add your Quizzes, Midterms, and Assignments. Enter the max score and the points they are worth.
3.  **Track Deadlines**: Set due dates for your assessments. They will appear on your Dashboard and Calendar.
4.  **Monitor Progress**: Watch your "Acquired" (Green) ring grow as you ace your exams!

## 💻 Technologies

-   **Flutter** (Dart)
-   **TableCalendar**
-   **Intl**
-   **Shared_Preferences** (Local Storage)

---

Built with ❤️ for Students.
