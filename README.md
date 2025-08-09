# DataKeeper

This is my CRUD (Create, Read, Update, Delete) application with local SQLite database integration, designed to manage user records efficiently.

## Key Features

### **User Management**
- Add, edit, view, and delete user profiles with details like **name, phone, city, postal code, and street**.
- Responsive data table with horizontal scrolling for large datasets.

### **Data Export**
- **PDF Export**: Generate printable reports of user data in tabular format.
- **Database Backup**: Export the SQLite database to device storage for backup or transfer.

### **Modern UI**
- Clean, intuitive interface with:
  - Floating action buttons (PDF/DB export).
  - Empty state prompts.
  - Top-aligned snackbar notifications.
  - Bottom navigation for quick actions.

### **Error Handling**
- Robust validation and user-friendly error messages.

### **Technical Highlights**
- **SQLite Database**: Local storage with `sqflite`.
- **PDF Generation**: Using `pdf` package.
- **File Handling**: Export/import DB files with `path_provider` and `open_file`.

---

## Purpose
Ideal for small businesses or personal use to digitally manage contact lists or similar structured data **offline**, with options to export for record-keeping.
