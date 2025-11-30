import 'package:firebase_database/firebase_database.dart';
import '../../domain/repositories/game_repository.dart';
import '../models/game_room_model.dart';
import '../models/player_model.dart';
import '../models/card_model.dart';
import '../../core/constants/app_constants.dart';

class FirebaseGameRepository implements IGameService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

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
      await roomRef.update({'status': RoomStatus.playing.name});
    }
  }

  @override
  Future<void> playCard(String roomId, UnoCard card) async {
    final roomRef = _roomsRef.child(roomId);
    final gameStateRef = roomRef.child('gameState');

    await gameStateRef.runTransaction((currentData) {
      if (currentData == null) {
        return Transaction.success(currentData);
      }

      final currentState = Map<String, dynamic>.from(currentData as Map);
      currentState['topCard'] = card.toMap();

      return Transaction.success(currentState);
    });
  }

  @override
  Future<void> drawCard(String roomId) async {
    final roomRef = _roomsRef.child(roomId);
    final gameStateRef = roomRef.child('gameState');

    await gameStateRef.runTransaction((currentData) {
      if (currentData == null) {
        return Transaction.success(currentData);
      }

      final currentState = Map<String, dynamic>.from(currentData as Map);
      int drawPileCount = currentState['drawPileCount'] ?? 0;
      if (drawPileCount > 0) {
        currentState['drawPileCount'] = drawPileCount - 1;
      }

      return Transaction.success(currentState);
    });
  }

  @override
  Future<void> callUno(String roomId) async {
    // Placeholder
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
}
