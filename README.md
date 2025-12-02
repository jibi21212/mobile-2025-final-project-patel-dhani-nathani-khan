# 📱 Mobile Task Manager
A simple, clean, and feature-rich Flutter application designed to help users manage daily tasks with scheduling, notifications, recurring tasks, cloud sync, and visual progress tracking.

---

## 👥 Group Members
**Eva Hanif Nathani — 100814690**  
**Saahir Dhani — 100818300**  
**Yash Patel — 100785833**  
**Muhammad Jibran Khan — 100877086**

---

## 📝 Project Overview
The **Mobile Task Manager** is a Flutter application built for the CSCI 4100U Mobile Devices course.  
The app allows users to:

- Create, edit, delete, and view tasks
- Assign due dates and priorities
- Receive scheduled local notifications
- Use recurring tasks (daily, weekly, weekdays, monthly)
- Sync data to the cloud
- Log in and sign up using Firebase Authentication
- View task analytics using a dashboard
- Undo deleted tasks with snackbars

The project fulfills **all core functional requirements** and includes multiple optional features.

---

## 👤 Group Responsibilities

### **Eva Hanif Nathani (100814690)**
- UI refinement & theme adjustments
- Dashboard layout verification
- Testing and user flow checks
- Documentation support

### **Saahir Dhani (100818300)**
- Notifications system
- Recurring tasks implementation
- Search & sorting
- Undo delete functionality
- Bug fixes & merge conflict resolution

### **Yash Patel (100785833)**
- Project setup & environment configuration
- Running app on emulator/device
- README documentation
- UML diagrams
- Testing and feedback

### **Muhammad Jibran Khan (100877086)**
- Firebase authentication (login & signup)
- Cloud sync implementation
- Firestore integration
- Merge conflict fixes
- Code review and backend testing

All group members worked together on planning, debugging, testing, and validating the app.

---

# ✅ Features Implemented (Complete)

## ⭐ Core Required Features
- Add, edit, delete tasks
- Mark tasks complete/incomplete
- View task details
- Persistent local storage (SQLite)
- Multiple screens + navigation
- Task sorting & filtering
- Task search bar
- Task priority selection
- Due date selection
- Undo delete using Snackbars
- Scheduled notifications
- Authentication (Login + Sign Up)
- Cloud sync module

---

# 🚀 Additional Features (Above Requirements)

### 🔁 Recurring Tasks
- Daily
- Weekly
- Weekdays
- Monthly

### 🔍 Search & Sorting
- Search by task title
- Sort by due date, priority, status

### ✨ UI Enhancements
- Task list with priority colors
- Bottom sheet for editing
- Stylish dashboard with charts
- Status summary

### 🔔 Notifications
- Local scheduled reminders
- “Test Notification” button
- “Schedule notification in 10 seconds” demo
- Background reminder scheduling

### 🎛 Settings
- Theme selection (Light / System)
- Cloud sync status
- Reminder toggle
- User account info

---

# 🗂 App Architecture

### 📁 `/lib` Structure  
lib/
data/
task.dart
task_repo.dart
features/
auth/
auth_screen.dart
list/
task_list_screen.dart
edit/
task_edit_sheet.dart
details/
task_details_screen.dart
dashboard/
dashboard_screen.dart
settings/
services/
auth_service.dart
cloud_sync_service.dart
notification_service.dart
widgets/
app_router.dart
main.dart
firebase_options.dart


---

# 💾 Storage

### **Local Storage – SQLite**
Stores:
- title
- description
- due date
- status
- priority
- recurrence

### **Cloud Storage – Firestore**
Used for syncing tasks across devices.

### **Firebase Authentication**
Used for login and signup.

---

# 📊 Dashboard Features
- Total tasks
- Completed tasks
- In-progress tasks
- Overdue tasks
- Task status pie chart
- Priority distribution bar chart
- Completion rate summary

---

# 🎨 UI Highlights
- Clean pastel color palette
- Material Design 3 styling
- Smooth navigation
- Bottom sheet for editing
- Confirmation dialogs
- Snackbar messages

---

# 🛠 Installation & Running
### 1. Clone the repository  
git clone https://github.com/jibi21212/mobile-2025-final-project-patel-dhani-nathani-khan.git

### 2. Install dependencies  

### 3. Run the app  

---

# ✔ Final Notes
This project includes all required features for CSCI 4100U Mobile Devices final project and multiple advanced enhancements such as recurring tasks, cloud sync, and dashboard analytics.
The app is fully tested on Android emulator and physical devices.

---

# 🎉 Thank You
Submitted by:  
**Eva Hanif Nathani**,  
**Saahir Dhani**,  
**Yash Patel**,  
**Muhammad Jibran Khan**

