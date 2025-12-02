# Implemented Features

## 1. Multiplayer System (Firebase)

- **Real-time Synchronization**: Game state is synced instantly across all clients using Firebase Realtime Database.
- **Room Management**:
  - **Create Room**: Users can create a room with a custom name, optional password, and max player limit.
  - **Join Room**: Users can join existing rooms using a Room ID (and password if required).
  - **Leave Room**: Handles clean disconnects. If the host leaves, the room is either assigned a new host or deleted if empty.
  - **Lobby System**: A `WaitingRoomScreen` where players gather before the host starts the game.

## 2. Game Logic (UNO Rules)

- **Deck Management**:
  - Full UNO deck generation (Numbers, Skips, Reverses, Draw Twos, Wilds, Wild Draw Fours).
  - Shuffling and Dealing (7 cards per player).
- **Turn System**:
  - Turn validation (can only play if it matches color, number, or is Wild).
  - Clockwise/Counter-clockwise play direction (handled by Reverse cards).
  - Next player calculation logic.
- **Special Cards**:
  - **Skip**: Skips the next player's turn.
  - **Reverse**: Reverses the order of play.
  - **Draw Two**: Forces the next player to draw 2 cards.
  - **Wild**: Allows changing the current color.
  - **Wild Draw Four**: Changes color and forces next player to draw 4.
- **Winning Condition**: Detects when a player has 0 cards.

## 3. User Interface (UI)

- **Home Screen**: Entry point with options to Create or Join a room.
- **Game Screen**:
  - **Visual Cards**: Custom `UnoCardWidget` that renders cards beautifully.
  - **Opponent View**: Shows opponents and their card counts (cards are hidden).
  - **Player Hand**: Scrollable list of the player's own cards.
  - **Game Table**: Displays the Draw Pile and the Top Card (Discard Pile).
- **Localization**: Full support for English (`en`) and Arabic (`ar`).
- **Theming**: Light and Dark mode support (system default).

## 4. Authentication

- **Anonymous Login**: Uses Firebase Anonymous Auth to create temporary user sessions without requiring email/password.
