import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_game_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/game_logic_service.dart';
import '../../domain/repositories/game_repository.dart';
import '../../data/models/game_room_model.dart';
import '../../data/models/player_model.dart';

// Services
final authServiceProvider = Provider<IAuthService>((ref) => AuthService());
final gameLogicServiceProvider =
    Provider<GameLogicService>((ref) => GameLogicService());
final gameRepositoryProvider =
    Provider<IGameService>((ref) => FirebaseGameRepository());

// Auth State
final currentUserProvider = FutureProvider<Player?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

// Room State
final currentRoomIdProvider = StateProvider<String?>((ref) => null);

final roomStreamProvider = StreamProvider.autoDispose<GameRoom?>((ref) {
  final roomId = ref.watch(currentRoomIdProvider);
  final repository = ref.watch(gameRepositoryProvider);

  if (roomId == null) return Stream.value(null);

  return repository.roomStream(roomId);
});
