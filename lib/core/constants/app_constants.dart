class AppConstants {
  static const String appName = 'UNO Multiplayer';
  static const String fontFamily = 'Roboto'; // Or any other font you prefer

  // Firebase Collections
  static const String roomsCollection = 'rooms';
  static const String usersCollection = 'users';

  // Game Settings
  static const int minPlayers = 2;
  static const int maxPlayers = 10;
  static const int initialCards = 7;
  static const int unoPenaltyCards = 2;
  static const int turnDurationSeconds = 30;
  static const int unoCallWindowSeconds = 3;
}
