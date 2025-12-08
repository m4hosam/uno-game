import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../providers/game_providers.dart';
import 'waiting_room_screen.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomCodeController = TextEditingController(); // Used as Server Name
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _roomCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final currentUser = await ref.read(currentUserProvider.future);
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        final roomId = _roomCodeController.text;
        // Logic for joining by room name (which acts as ID/code for now)
        await ref.read(gameRepositoryProvider).joinRoom(
              roomId,
              _passwordController.text.isEmpty
                  ? null
                  : _passwordController.text,
              currentUser,
            );

        ref.read(currentRoomIdProvider.notifier).state = roomId;

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WaitingRoomScreen(
                roomId: roomId,
                isHost: false,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final headerStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 14,
    );

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFF2C2121), // reddish dark
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.unoRed),
      ),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      contentPadding: const EdgeInsets.all(16),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.joinGameChannel, // Matches design text
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                Text(l10n.joinGameTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    )),

                const SizedBox(height: 32),

                // Server Name
                Text(l10n.serverNameHeader, style: headerStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _roomCodeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(
                    hintText: l10n.roomCodeHint,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterRoomCode;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Password
                Text(l10n.passwordHeader, style: headerStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration.copyWith(
                    hintText: l10n.enterPasswordHint,
                    suffixIcon:
                        const Icon(Icons.remove_red_eye, color: Colors.white38),
                  ),
                  obscureText: true,
                ),

                const Spacer(),

                // Join Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _joinRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE81E32), // Uno Red
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            l10n.join, // "Join"
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
