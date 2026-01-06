# Project LonelyReminder

**LonelyReminder is an intelligent, offline-first, cross-platform application designed to instantly capture events from images and screenshots, keeping your schedule effortlessly in sync across all your devices.**

## 🎯 Problem Statement

Manually entering event details from screenshots, posters, or whiteboards into a digital calendar is tedious and error-prone. This project aims to eliminate that friction by creating a seamless "scan-to-event" workflow that works reliably online and offline, and syncs perfectly between mobile and desktop clients (Android, iOS, Windows, macOS).

## ✨ Core Features

* **📸 Image-to-Event Capture:** Instantly create events by taking a photo or selecting a screenshot.
* **🧠 Intelligent Text Analysis:** On-device AI automatically detects event titles, dates, times, and descriptions from text.
* **🚫 Offline-First Functionality:** Core features—scanning and parsing—work entirely without an internet connection.
* **🔄 Seamless Cross-Device Sync:** All events are stored locally and automatically synced with a central server when online, keeping Android, iOS, Windows, and macOS clients up-to-date.
* **📅 Calendar Integration:** Export captured events directly to your device's local calendar (Google Calendar, Apple Calendar).
* **🔒 Secure & Private:** Your data is synced securely to your private backend, giving you full ownership.

## 🛠️ Technology Stack

This project uses a modern and robust tech stack chosen for performance, scalability, and cross-platform capabilities.

| Component          | Technology                                                                                                  | Rationale                                                                        |
| ------------------ | ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Mobile & Desktop** | [**Flutter**](https://flutter.dev/) (Dart)                                                                  | A single codebase for building beautiful, natively compiled apps for all 4 platforms. |
| **Local Database** | [**Isar Database**](https://isar.dev/)                                                                      | A super-fast, cross-platform, and easy-to-use NoSQL database for Flutter.         |
| **On-Device AI** | [**Google ML Kit**](https://developers.google.com/ml-kit) (Text Recognition)                                | Provides fast, accurate, and reliable on-device OCR without needing a server.       |
| **Backend API** | [**Go (Golang)**](https://go.dev/) with [Gin](https://github.com/gin-gonic/gin)                             | Highly performant, concurrent, and simple language ideal for building scalable APIs. |
| **Cloud Database** | [**MongoDB**](https://www.mongodb.com/)                                                                     | A flexible, scalable NoSQL database that works well with Go and syncs easily.       |

## 🏗️ Architecture Overview

The application is built on an **Offline-First** architecture. This ensures a smooth and reliable user experience, regardless of network connectivity.

1.  **Client App (Flutter):** The user captures an image. The on-device ML Kit engine performs OCR. A custom parsing service then analyzes this text to structure it into an event object.
2.  **Local Storage (Isar):** The structured event is immediately saved to the local Isar database on the device. The UI reads exclusively from this local database, making the app feel instantaneous.
3.  **Sync Service:** A background service in the Flutter app detects network availability.
    * **Push:** When online, it sends any new or modified local events to the backend API.
    * **Pull:** It periodically fetches the latest event data from the server to get changes made on other devices.
4.  **Backend API (Go):** The API acts as the central hub. It handles authentication, validates incoming data from the clients, and persists it in the MongoDB database.
5.  **Database (MongoDB):** The single source of truth for all synced data.

```
[Flutter App] <--> [Local Isar DB] <--> [Sync Service] <--> [Go API] <--> [MongoDB]
     ^                                       |
     |--(Works Offline)----------------------|
```

## 🚀 Getting Started (Development)

### Prerequisites

* Flutter SDK (latest stable version)
* Go (version 1.18+)
* MongoDB Server (or a MongoDB Atlas account)
* Android Studio / VS Code for Flutter development
* An IDE for Go development (e.g., GoLand, VS Code)

### Client Setup (Flutter)

```bash
# Clone the repository
git clone https://github.com/lonelyguy12/lonelyreminder/
cd lonelyreminder

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Backend Setup (Go)

```bash
# Navigate to the server directory
cd ../server

# Install Go dependencies
go mod tidy

# Create a .env file with your database credentials
# PORT=8080
# MONGO_URI="your_mongodb_connection_string"

# Run the server
go run main.go
```

## 📝 Preliminary API Endpoints

The following REST API endpoints will be implemented to facilitate data synchronization.

| Method   | Endpoint              | Description                               |
| -------- | --------------------- | ----------------------------------------- |
| `POST`   | `/api/auth/register`  | Register a new user.                      |
| `POST`   | `/api/auth/login`     | Log in a user and receive a JWT.          |
| `POST`   | `/api/events`         | Create a new event.                       |
| `GET`    | `/api/events`         | Get all events for the authenticated user.|
| `PUT`    | `/api/events/:id`     | Update an existing event by its ID.       |
| `DELETE` | `/api/events/:id`     | Delete an event by its ID.                |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any bugs or feature requests.

## 📄 License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.
"""