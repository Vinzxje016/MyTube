import 'package:flutter/material.dart';
import '../controllers/music_player_controller.dart';
import '../theme/app_theme.dart';

Future<void> showSleepTimerSheet(BuildContext context) async {
  final player = MusicPlayerController();
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.surfaceColor,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: ListenableBuilder(
          listenable: player,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Text(
                  'Hẹn giờ ngủ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              if (player.sleepTimerLabel != null)
                ListTile(
                  leading: const Icon(
                    Icons.timer_rounded,
                    color: AppTheme.primaryLight,
                  ),
                  title: Text(player.sleepTimerLabel!),
                  trailing: TextButton(
                    onPressed: () {
                      player.cancelSleepTimer();
                      Navigator.pop(context);
                    },
                    child: const Text('Hủy hẹn'),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Sau 15 phút'),
                onTap: () {
                  player.startSleepTimer(const Duration(minutes: 15));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Sau 30 phút'),
                onTap: () {
                  player.startSleepTimer(const Duration(minutes: 30));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Sau 60 phút'),
                onTap: () {
                  player.startSleepTimer(const Duration(minutes: 60));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: const Text('Khi hết bài hiện tại'),
                onTap: () {
                  player.sleepAfterCurrentTrack();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
