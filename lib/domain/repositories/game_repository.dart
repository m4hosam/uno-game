import '../../data/models/game_room_model.dart';
import '../../data/models/player_model.dart';
import '../../data/models/card_model.dart';

abstract class IGameService {
  Future<String> createRoom(String name, String? password, Player host);
  Future<void> joinRoom(String roomId, String? password, Player player);
  Future<void> leaveRoom(String roomId, String playerId);
  Future<void> startGame(String roomId);
  Future<void> playCard(String roomId, UnoCard card, {CardColor? chosenColor});
  Future<void> drawCard(String roomId);
  Future<void> callUno(String roomId);
  Stream<GameRoom> roomStream(String roomId);
}

abstract class IAuthService {
  Future<Player> signInAnonymously(String displayName);
  Future<void> updateDisplayName(String newName);
  Player? get currentUser;
}
