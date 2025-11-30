import 'package:firebase_database/firebase_database.dart';
import '../../domain/repositories/game_repository.dart';
import '../models/game_room_model.dart';
import '../models/player_model.dart';
import '../models/card_model.dart';
import '../models/game_state_model.dart';
import '../services/game_logic_service.dart';
import '../../core/constants/app_constants.dart';

class FirebaseGameRepository implements IGameService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final _gameLogic = GameLogicService();

  DatabaseReference get _roomsRef => _db.ref(AppConstants.roomsCollection);

  @override
  Future<String> createRoom(String name, String? password, Player host) async {
    final newRoomRef = _roomsRef.push();
    final roomId = newRoomRef.key!;

    final hostPlayer = host.copyWith(isHost: true, isReady: true);

    final room = GameRoom(
      id: roomId,
      name: name,
      password: password,
      hostId: host.id,
      players: [hostPlayer],
      status: RoomStatus.waiting,
    );

    await newRoomRef.set(room.toMap());
    return roomId;
  }

  @override
  Future<void> joinRoom(String roomId, String? password, Player player) async {
    final roomRef = _roomsRef.child(roomId);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      throw Exception('Room not found');
    }

    final roomMap = Map<String, dynamic>.from(snapshot.value as Map);
    final room = GameRoom.fromMap(roomMap);

    // Password check
    if (room.password != null &&
        room.password!.isNotEmpty &&
        room.password != password) {
      throw Exception('Incorrect password');
    }

    if (room.players.length >= room.maxPlayers) {
      throw Exception('Room is full');
    }

    // Check if game already started
    if (room.status != RoomStatus.waiting) {
      throw Exception('Game already started');
    }

    List<Player> updatedPlayers = List.from(room.players);

    // Check if player already exists
    final existingIndex = updatedPlayers.indexWhere((p) => p.id == player.id);
    if (existingIndex == -1) {
      updatedPlayers.add(player);
      await roomRef
          .child('players')
          .set(updatedPlayers.map((p) => p.toMap()).toList());
    }
  }

  @override
  Future<void> leaveRoom(String roomId, String playerId) async {
    final roomRef = _roomsRef.child(roomId);
    final snapshot = await roomRef.get();

    if (snapshot.exists) {
      final roomMap = Map<String, dynamic>.from(snapshot.value as Map);
      final room = GameRoom.fromMap(roomMap);

      List<Player> updatedPlayers = List.from(room.players);
      updatedPlayers.removeWhere((p) => p.id == playerId);

      if (updatedPlayers.isEmpty) {
        // Delete room if empty
        await roomRef.remove();
      } else {
        // If host left, assign new host
        if (room.hostId == playerId) {
          final newHost = updatedPlayers.first.copyWith(isHost: true);
          updatedPlayers[0] = newHost;
          await roomRef.update({
            'hostId': newHost.id,
            'players': updatedPlayers.map((p) => p.toMap()).toList(),
          });
        } else {
          await roomRef
              .child('players')
              .set(updatedPlayers.map((p) => p.toMap()).toList());
        }
      }
    }
  }

  @override
  Future<void> startGame(String roomId) async {
    final roomRef = _roomsRef.child(roomId);
    final snapshot = await roomRef.get();

    if (snapshot.exists) {
      // Initialize Game State
      final roomMap = Map<String, dynamic>.from(snapshot.value as Map);
      final room = GameRoom.fromMap(roomMap);

      // Generate Deck and Deal Cards
      final deck = _gameLogic.generateDeck();
      final shuffledDeck = _gameLogic.shuffleDeck(deck);

      List<Player> players = List.from(room.players);
      // Deal 7 cards to each player
      for (var i = 0; i < players.length; i++) {
        final hand = shuffledDeck.take(7).toList();
        shuffledDeck.removeRange(0, 7);
        players[i] = players[i].copyWith(hand: hand, cardCount: 7);
      }

      // Top card
      UnoCard topCard = shuffledDeck.removeAt(0);
      // Ensure top card is not Wild Draw Four (standard rule, but for simplicity allow anything or redraw)
      // For MVP, allow anything.

      final gameState = GameState(
        currentPlayerId:
            players.first.id, // Host starts or random? Host starts for now.
        currentColor: topCard.color == CardColor.black
            ? CardColor.red
            : topCard.color, // Default red for wild start
        topCard: topCard,
        drawPileCount: shuffledDeck.length,
        isClockwise: true,
      );

      await roomRef.update({
        'status': RoomStatus.playing.name,
        'gameState': gameState.toMap(),
        'players': players.map((p) => p.toMap()).toList(),
      });
    }
  }

  @override
  Future<void> playCard(String roomId, UnoCard card,
      {CardColor? chosenColor}) async {
    final roomRef = _roomsRef.child(roomId);

    await roomRef.runTransaction((currentData) {
      if (currentData == null) {
        return Transaction.success(currentData);
      }

      final roomMap = Map<String, dynamic>.from(currentData as Map);
      final room = GameRoom.fromMap(roomMap);

      if (room.gameState == null) return Transaction.abort();

      final gameState = room.gameState!;

      // Validate Move
      if (!_gameLogic.canPlayCard(
          card, gameState.topCard, gameState.currentColor)) {
        return Transaction.abort(); // Invalid move
      }

      // Update State
      var newTopCard = card;
      var newCurrentColor =
          card.isWild ? (chosenColor ?? CardColor.red) : card.color;
      var newIsClockwise = gameState.isClockwise;
      var drawPileCount = gameState.drawPileCount;

      // Handle Action Cards
      if (card.type == CardType.reverse) {
        if (room.players.length == 2) {
          // In 2 player game, reverse acts like skip
        } else {
          newIsClockwise = !newIsClockwise;
        }
      }

      // Update Players (Remove card)
      List<Player> players = List.from(room.players);
      final playerIndex =
          players.indexWhere((p) => p.id == gameState.currentPlayerId);
      if (playerIndex == -1) return Transaction.abort();

      var currentPlayer = players[playerIndex];
      List<UnoCard> newHand = List.from(currentPlayer.hand ?? []);
      newHand.removeWhere((c) => c.id == card.id);
      players[playerIndex] = currentPlayer.copyWith(
        hand: newHand,
        cardCount: newHand.length,
      );

      // Check for Winner
      String? winnerId;
      if (newHand.isEmpty) {
        winnerId = currentPlayer.id;
      }

      // Determine next player
      int skipCount = 0;
      if (card.type == CardType.skip ||
          (card.type == CardType.reverse && players.length == 2)) {
        skipCount = 1;
      }

      String tempNextPlayerId = _gameLogic.getNextPlayerId(
          players, gameState.currentPlayerId, newIsClockwise);
      if (skipCount > 0) {
        tempNextPlayerId = _gameLogic.getNextPlayerId(
            players, tempNextPlayerId, newIsClockwise);
      }

      // Handle Draw Effects
      if (card.type == CardType.drawTwo) {
        final nextPIndex = players.indexWhere((p) => p.id == tempNextPlayerId);
        if (nextPIndex != -1) {
          var nextP = players[nextPIndex];
          var drawnCards = _generateRandomCards(2);
          List<UnoCard> nextHand = List.from(nextP.hand ?? [])
            ..addAll(drawnCards);
          players[nextPIndex] =
              nextP.copyWith(hand: nextHand, cardCount: nextHand.length);
          drawPileCount = (drawPileCount - 2).clamp(0, 108);

          tempNextPlayerId = _gameLogic.getNextPlayerId(
              players, tempNextPlayerId, newIsClockwise);
        }
      } else if (card.type == CardType.wildDrawFour) {
        final nextPIndex = players.indexWhere((p) => p.id == tempNextPlayerId);
        if (nextPIndex != -1) {
          var nextP = players[nextPIndex];
          var drawnCards = _generateRandomCards(4);
          List<UnoCard> nextHand = List.from(nextP.hand ?? [])
            ..addAll(drawnCards);
          players[nextPIndex] =
              nextP.copyWith(hand: nextHand, cardCount: nextHand.length);
          drawPileCount = (drawPileCount - 4).clamp(0, 108);

          tempNextPlayerId = _gameLogic.getNextPlayerId(
              players, tempNextPlayerId, newIsClockwise);
        }
      }

      final nextPlayerId = tempNextPlayerId;

      final newGameState = GameState(
        currentPlayerId: nextPlayerId,
        isClockwise: newIsClockwise,
        currentColor: newCurrentColor,
        topCard: newTopCard,
        drawPileCount: drawPileCount,
        winnerId: winnerId,
      );

      roomMap['gameState'] = newGameState.toMap();
      roomMap['players'] = players.map((p) => p.toMap()).toList();
      if (winnerId != null) {
        roomMap['status'] = RoomStatus.finished.name;
      }

      return Transaction.success(roomMap);
    });
  }

  @override
  Future<void> drawCard(String roomId) async {
    final roomRef = _roomsRef.child(roomId);

    await roomRef.runTransaction((currentData) {
      if (currentData == null) return Transaction.success(currentData);

      final roomMap = Map<String, dynamic>.from(currentData as Map);
      final room = GameRoom.fromMap(roomMap);

      if (room.gameState == null) return Transaction.abort();
      final gameState = room.gameState!;

      List<Player> players = List.from(room.players);
      final playerIndex =
          players.indexWhere((p) => p.id == gameState.currentPlayerId);
      if (playerIndex == -1) return Transaction.abort();

      var currentPlayer = players[playerIndex];
      var drawnCards = _generateRandomCards(1);
      List<UnoCard> newHand = List.from(currentPlayer.hand ?? [])
        ..addAll(drawnCards);
      players[playerIndex] = currentPlayer.copyWith(
        hand: newHand,
        cardCount: newHand.length,
      );

      String nextPlayerId = _gameLogic.getNextPlayerId(
          players, gameState.currentPlayerId, gameState.isClockwise);

      final newGameState = GameState(
        currentPlayerId: nextPlayerId,
        isClockwise: gameState.isClockwise,
        currentColor: gameState.currentColor,
        topCard: gameState.topCard,
        drawPileCount: (gameState.drawPileCount - 1).clamp(0, 108),
        winnerId: gameState.winnerId,
      );

      roomMap['gameState'] = newGameState.toMap();
      roomMap['players'] = players.map((p) => p.toMap()).toList();

      return Transaction.success(roomMap);
    });
  }

  @override
  Future<void> callUno(String roomId) async {
    // Placeholder for UNO call logic
  }

  @override
  Stream<GameRoom> roomStream(String roomId) {
    return _roomsRef.child(roomId).onValue.map((event) {
      if (event.snapshot.value == null) {
        throw Exception('Room deleted');
      }
      final map = Map<String, dynamic>.from(event.snapshot.value as Map);
      return GameRoom.fromMap(map);
    });
  }

  List<UnoCard> _generateRandomCards(int count) {
    final deck = _gameLogic.generateDeck();
    deck.shuffle();
    return deck.take(count).toList();
  }
}
