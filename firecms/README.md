# UniTask FireCMS Configuration (Self-Hosted)

This directory contains the configuration files to set up [FireCMS](https://firecms.co/) to manage your UniTask database directly from a web interface.

## Prerequisites
- Node.js & npm
- A Firebase project with Firestore enabled.
- Administrative email: `hamedalbazly70@gmail.com`

## Setup Instructions

1.  **Initialize FireCMS Project**:
    ```bash
    npx create-firecms-app@latest
    ```
    Follow the prompt and choose "Self-hosted".

2.  **Apply Schema**:
    Copy the files from this directory into your new FireCMS project's `src/` folder.

3.  **Deploy**:
    ```bash
    npm run build
    firebase deploy --only hosting
    ```

## Collection Structure

### 1. Semesters (`semesters`)
- `name`: String
- `startDate`: Date
- `endDate`: Date
- `active`: Boolean

### 2. Courses (`courses`)
- `name`: String
- `professor`: String
- `credits`: Number
- `isPassFail`: Boolean
- `colorValue`: Number (ARGB)
- `semesterId`: Reference (to semesters)
- `courseworkWeight`: Number (Default: 60)
- `finalWeight`: Number (Default: 40)
- `lectureTime`: String (Format: "Day HH:mm")
- `hasLab`: Boolean
- `hasTutorial`: Boolean

### 3. Assessments (`courses/{courseId}/assessments`)
- `title`: String
- `type`: Enum (quiz, assignment, midterm, finalExam, project, other)
- `category`: Enum (coursework, finalProject)
- `weight`: Number (Absolute points)
- `maxScore`: Number
- `score`: Number (Optional)
- `deadline`: Date
- `isCompleted`: Boolean

---
*Generated for hamedalbazly70@gmail.com*
