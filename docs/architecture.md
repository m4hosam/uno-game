# App Architecture & Development Guide

This project follows **Clean Architecture** principles combined with **Riverpod** for state management to ensure scalability, testability, and separation of concerns.

## 1. Architectural Overview

The application is divided into three main layers:

### **Domain Layer** (`lib/domain`)

- **Responsibility**: Contains the business logic and entities (interfaces) independent of any specific implementation or framework.
- **Components**:
  - **Repositories (Interfaces)**: Defines the contract for data operations (e.g., `IGameService`, `IAuthService`).
  - **Entities**: Pure Dart classes representing core business objects (though in this simple app, models are shared in `data/models` for pragmatism, strictly they belong here).

### **Data Layer** (`lib/data`)

- **Responsibility**: Handles data retrieval and storage. Implements the interfaces defined in the Domain layer.
- **Components**:
  - **Repositories (Implementations)**: Concrete implementations of domain interfaces (e.g., `FirebaseGameRepository`).
  - **Models**: Data transfer objects (DTOs) with `toMap`/`fromMap` methods for serialization (e.g., `Player`, `GameRoom`, `UnoCard`).
  - **Services**: External services or logic helpers (e.g., `GameLogicService`, `AuthService`).

### **Presentation Layer** (`lib/presentation`)

- **Responsibility**: Handles UI rendering and user interaction.
- **Components**:
  - **Screens**: Full-page widgets (e.g., `HomeScreen`, `GameScreen`).
  - **Widgets**: Reusable UI components (e.g., `UnoCardWidget`).
  - **Providers**: Riverpod providers that glue the Data layer to the UI (`game_providers.dart`).

## 2. Folder Structure

```
lib/
├── core/                   # Core utilities and constants
│   ├── constants/          # App-wide constants (e.g., AppConstants)
│   └── theme/              # Theme definitions (colors, styles)
├── data/                   # Data layer implementation
│   ├── models/             # Data models (Player, GameRoom, UnoCard)
│   ├── repositories/       # Concrete repositories (FirebaseGameRepository)
│   └── services/           # Services (AuthService, GameLogicService)
├── domain/                 # Domain layer definitions
│   └── repositories/       # Repository interfaces (IGameService)
├── l10n/                   # Localization files (.arb)
├── presentation/           # UI layer
│   ├── providers/          # Riverpod providers
│   ├── screens/            # Application screens
│   └── widgets/            # Reusable widgets
└── main.dart               # Entry point
```

## 3. State Management (Riverpod)

We use **Riverpod** for dependency injection and state management.

- **`ref.read`**: Used for one-time actions (e.g., calling a repository method).
- **`ref.watch`**: Used in `build` methods to listen to state changes and rebuild the UI.
- **`StreamProvider`**: Used heavily to listen to real-time updates from Firebase (e.g., `roomStreamProvider`).

### Key Providers (`lib/presentation/providers/game_providers.dart`)

- `gameRepositoryProvider`: Exposes the `FirebaseGameRepository`.
- `currentUserProvider`: Provides the currently authenticated `Player`.
- `currentRoomIdProvider`: Stores the ID of the active room.
- `roomStreamProvider`: Listens to the active room's data from Firebase.

## 4. Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **Backend**: Firebase Realtime Database (Game State), Firebase Authentication (Anonymous Auth)
- **State Management**: Flutter Riverpod
- **Localization**: flutter_localizations (ARB files)
