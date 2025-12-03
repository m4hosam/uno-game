import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/game_room_model.dart';
import '../providers/game_providers.dart';
import 'game_screen.dart';

class WaitingRoomScreen extends ConsumerWidget {
  final String roomId;
  final bool isHost;

  const WaitingRoomScreen({
    super.key,
    required this.roomId,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final roomAsyncValue = ref.watch(roomStreamProvider);

    // Listen for game start
    ref.listen(roomStreamProvider, (previous, next) {
      next.whenData((room) {
        if (room != null && room.status == RoomStatus.playing) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GameScreen()),
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.waitingRoom),
        centerTitle: true,
      ),
      body: roomAsyncValue.when(
        data: (room) {
          if (room == null) {
            return Center(child: Text(l10n.roomNotFound));
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Room Code Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            l10n.roomCode,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                roomId,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: AppTheme.unoRed,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: roomId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(l10n.copiedToClipboard)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Players List
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${l10n.players} (${room.players.length}/${room.maxPlayers})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: room.players.length,
                      itemBuilder: (context, index) {
                        final player = room.players[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: player.isReady
                                  ? AppTheme.unoGreen
                                  : Colors.grey,
                              child: Icon(
                                player.isHost ? Icons.star : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(player.name),
                            subtitle:
                                Text(player.isHost ? l10n.host : l10n.player),
                            trailing: isHost && !player.isHost
                                ? IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      ref
                                          .read(gameRepositoryProvider)
                                          .leaveRoom(roomId, player.id);
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),

                  // Start Game Button (Host only)
                  if (isHost)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: room.players.length >= 2
                            ? () {
                                ref
                                    .read(gameRepositoryProvider)
                                    .startGame(roomId);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.unoGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          l10n.startGame,
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        l10n.waitingForHost,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
