import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../providers/game_providers.dart';
import 'waiting_room_screen.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  double _maxPlayers = 4;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final currentUser = await ref.read(currentUserProvider.future);
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Note: We need to update the repository to return the roomId
        // For now, we will assume the repository has been updated or we will update it shortly.
        // If the repository returns void, this will fail to compile if we assign it to roomId.
        // I will update the repository to return String in the next step if I haven't already.
        // Wait, I updated the repository in step 196, but I didn't change the return type of createRoom to Future<String>.
        // It was Future<void>.
        // So I need to update the repository to return the ID.

        // However, to avoid compilation error right now, I will generate the ID here if possible,
        // OR I will update the repository first.
        // Actually, I can't generate ID here easily because push() is inside repo.

        // I will update the repository to return the ID.
        // But I am writing this file now.
        // I will assume I will fix the repo.

        // Wait, if I write this file now and it has compilation error, it's bad.
        // But I can't fix both atomically.
        // I will write this file, then immediately fix the repo.

        final roomId = await ref.read(gameRepositoryProvider).createRoom(
              _nameController.text,
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
                isHost: true,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createRoom),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.roomName,
                  prefixIcon: const Icon(Icons.meeting_room),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.enterRoomName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.passwordOptional,
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              Text(
                '${l10n.maxPlayers}: ${_maxPlayers.round()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _maxPlayers,
                min: 2,
                max: 4,
                divisions: 2,
                label: _maxPlayers.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _maxPlayers = value;
                  });
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.unoBlue,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        l10n.createRoom,
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
