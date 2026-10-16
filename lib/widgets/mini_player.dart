import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../controllers/music_player_controller.dart';
import '../screens/now_playing_screen.dart';
import 'equalizer_bars.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerController();

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final currentSong = player.currentSong;
        if (currentSong == null) return const SizedBox.shrink();

        final accentColor = currentSong.accentColor;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const NowPlayingScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutCubic;
                    final tween =
                        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withAlpha(220),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withAlpha(40),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Main row content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                currentSong.coverUrl,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 46,
                                  height: 46,
                                  color: AppTheme.surfaceLight,
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Song Title & Artist
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          currentSong.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (player.isPlaying) ...[
                                        const SizedBox(width: 6),
                                        EqualizerBars(
                                          isPlaying: true,
                                          color: accentColor,
                                          height: 12,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentSong.artist,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Favorite Icon
                            IconButton(
                              icon: Icon(
                                player.isLiked(currentSong.id)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: player.isLiked(currentSong.id)
                                    ? AppTheme.accent
                                    : AppTheme.textMuted,
                                size: 22,
                              ),
                              onPressed: () => player.toggleLike(currentSong.id),
                            ),

                            // Play / Pause Button
                            GestureDetector(
                              onTap: () => player.togglePlayPause(),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [accentColor, AppTheme.accent],
                                  ),
                                ),
                                child: Icon(
                                  player.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Next Song Button
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                color: Colors.white70,
                                size: 24,
                              ),
                              onPressed: () => player.nextSong(),
                            ),
                          ],
                        ),
                      ),

                      // Linear Progress Bar at bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                          child: LinearProgressIndicator(
                            value: player.progressFraction,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            minHeight: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
