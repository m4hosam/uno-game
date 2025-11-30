import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/game_repository.dart';
import '../models/player_model.dart';

class AuthService implements IAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<Player> signInAnonymously(String displayName) async {
    final userCredential = await _auth.signInAnonymously();
    final user = userCredential.user!;

    // Update display name if provided (though anonymous users don't persist this well across re-installs without linking,
    // for this session it's fine, or we store it in local storage/DB)
    // We'll return a Player object.
    return Player(
      id: user.uid,
      name: displayName,
      isReady: false,
      isHost: false,
    );
  }

  @override
  Future<void> updateDisplayName(String newName) async {
    // For anonymous auth, we might just want to update it locally or in the DB user record.
    // Firebase Auth user.updateDisplayName(newName) is possible too.
    await _auth.currentUser?.updateDisplayName(newName);
  }

  @override
  Player? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return Player(
      id: user.uid,
      name: user.displayName ?? 'Player',
    );
  }
}
