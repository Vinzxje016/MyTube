import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../controllers/music_player_controller.dart';
import '../screens/now_playing_screen.dart';
import 'equalizer_bars.dart';
import 'cover_artwork.dart';

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
                        final tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));
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
                    color: context.surfaceColor.withAlpha(245),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor, width: 1),
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
                              child: CoverArtwork(
                                url: currentSong.coverUrl,
                                width: 46,
                                height: 46,
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
                                          style: TextStyle(
                                            color: context.primaryTextColor,
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
                                    player.playbackError ?? currentSong.artist,
                                    style: TextStyle(
                                      color: player.playbackError == null
                                          ? context.secondaryTextColor
                                          : Colors.redAccent,
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
                                    : context.mutedTextColor,
                                size: 22,
                              ),
                              onPressed: () =>
                                  player.toggleLike(currentSong.id),
                            ),

                            // Play / Pause Button
                            GestureDetector(
                              onTap: () => player.playbackError != null
                                  ? player.retryPlayback()
                                  : player.togglePlayPause(),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [accentColor, AppTheme.accent],
                                  ),
                                ),
                                child: player.isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        player.playbackError != null
                                            ? Icons.refresh_rounded
                                            : player.isPlaying
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
                              icon: Icon(
                                Icons.skip_next_rounded,
                                color: context.iconTextColor,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accentColor,
                            ),
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
