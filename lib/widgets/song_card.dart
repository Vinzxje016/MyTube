import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../controllers/music_player_controller.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerController();

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final isCurrent = player.currentSong?.id == song.id;
        final isPlaying = isCurrent && player.isPlaying;

        return GestureDetector(
          onTap: onTap ?? () => player.playSong(song),
          child: Container(
            width: 145,
            margin: const EdgeInsets.only(right: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artwork with gradient overlay & play button
                Stack(
                  children: [
                    Container(
                      height: 145,
                      width: 145,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: song.accentColor.withAlpha(50),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          song.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppTheme.surfaceLight,
                            child: const Icon(
                              Icons.album_rounded,
                              size: 48,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Quick Play floating icon
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(90),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  song.title,
                  style: TextStyle(
                    color: isCurrent ? AppTheme.accent : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // Artist
                Text(
                  song.artist,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 170,
              width: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: playlist.gradientColors.first.withAlpha(60),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      playlist.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: playlist.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            playlist.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${playlist.trackCount} bài hát',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
