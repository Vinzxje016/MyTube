import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../controllers/music_player_controller.dart';
import 'equalizer_bars.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final int? index;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;

  const SongTile({
    super.key,
    required this.song,
    this.index,
    this.onTap,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerController();

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final isCurrentSong = player.currentSong?.id == song.id;
        final isPlaying = isCurrentSong && player.isPlaying;
        final isLiked = player.isLiked(song.id);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => player.playSong(song),
            borderRadius: BorderRadius.circular(12),
            splashColor: AppTheme.primary.withAlpha(35),
            highlightColor: AppTheme.primary.withAlpha(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isCurrentSong
                    ? AppTheme.primary.withAlpha(20)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  // Track index or playing animation
                  if (index != null) ...[
                    SizedBox(
                      width: 28,
                      child: isPlaying
                          ? EqualizerBars(isPlaying: true, color: AppTheme.accent, height: 16)
                          : Text(
                              '${index!}',
                              style: TextStyle(
                                color: isCurrentSong
                                    ? AppTheme.accent
                                    : AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Artwork thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.network(
                          song.coverUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 48,
                            height: 48,
                            color: AppTheme.surfaceLight,
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                        if (isPlaying && index == null)
                          Container(
                            width: 48,
                            height: 48,
                            color: Colors.black45,
                            child: const Center(
                              child: EqualizerBars(
                                isPlaying: true,
                                color: Colors.white,
                                height: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title and Artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                song.title,
                                style: TextStyle(
                                  color: isCurrentSong
                                      ? AppTheme.accent
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (song.isExplicit) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'E',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          song.artist,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Like button
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isLiked ? AppTheme.accent : AppTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: () => player.toggleLike(song.id),
                    tooltip: isLiked ? 'Bỏ thích' : 'Yêu thích',
                  ),

                  // More options
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: onMorePressed ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tùy chọn: ${song.title}'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
