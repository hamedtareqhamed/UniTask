# Student Management Dashboard

A Flutter application designed for university students to manage their tasks and track their progress.

## Features

*   **Task Management**: Add tasks with names and grades using a validated form.
*   **Progress Tracking**: Visualize your overall progress with a Circular Progress Indicator.
*   **Task List**: View all tasks in a DataTable with options to mark them as completed.
*   **Calendar**: A built-in calendar view using `table_calendar` to manage your schedule.
*   **Session Timer**: specific timer to track your current study session duration.

## Technologies Used

*   **Flutter & Dart**: Core framework and language.
*   **Material 3**: Modern UI design.
*   **Packages**:
    *   `table_calendar`: For the calendar widget.
    *   `intl`: For date and time formatting.

## Code Structure Highlights

*   **Data Types**: Usage of `String`, `int`, `double`, `bool`, `List`, `final`, `const`.
*   **Control Structures**: `if-else` for validation, `for` loops/`map()` for generating UI lists.
*   **Subprograms**: Separate functions for adding tasks (`_addTask`) and calculating progress (`_calculateProgress`).

## How to Run

1.  **Get Dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Run the App**:
    ```bash
    flutter run
    ```
