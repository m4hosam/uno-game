import 'package:equatable/equatable.dart';
import 'player_model.dart';
import 'game_state_model.dart';

enum RoomStatus { waiting, playing, finished }

class GameRoom extends Equatable {
  final String id;
  final String name;
  final String? password; // Hashed or plain (if simple)
  final String hostId;
  final List<Player> players;
  final int maxPlayers;
  final RoomStatus status;
  final GameState? gameState;

  const GameRoom({
    required this.id,
    required this.name,
    this.password,
    required this.hostId,
    required this.players,
    this.maxPlayers = 10,
    this.status = RoomStatus.waiting,
    this.gameState,
  });

  @override
  List<Object?> get props =>
      [id, name, hostId, players, maxPlayers, status, gameState];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'hostId': hostId,
      'players': players.map((x) => x.toMap()).toList(),
      'maxPlayers': maxPlayers,
      'status': status.name,
      'gameState': gameState?.toMap(),
    };
  }

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    return GameRoom(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      password: map['password'],
      hostId: map['hostId'] ?? '',
      players: List<Player>.from(
        (map['players'] as List<dynamic>? ?? []).map<Player>(
          (x) => Player.fromMap(Map<String, dynamic>.from(x as Map)),
        ),
      ),
      maxPlayers: map['maxPlayers'] ?? 10,
      status: RoomStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RoomStatus.waiting,
      ),
      gameState: map['gameState'] != null
          ? GameState.fromMap(
              Map<String, dynamic>.from(map['gameState'] as Map))
          : null,
    );
  }
}
