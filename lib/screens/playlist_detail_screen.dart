import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerController();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Dynamic Sliver App Bar
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppTheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    playlist.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: playlist.gradientColors,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.background.withAlpha(220),
                          AppTheme.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PLAYLIST CÔNG KHAI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          playlist.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          playlist.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${playlist.trackCount} bài hát • Khoảng 28 phút',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border_rounded),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {},
              ),
            ],
          ),

          // Play / Shuffle Control Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Play All Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 26),
                    label: const Text(
                      'Phát tất cả',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () {
                      if (playlist.songs.isNotEmpty) {
                        player.playSong(playlist.songs.first, newQueue: playlist.songs);
                      }
                    },
                  ),
                  const SizedBox(width: 14),

                  // Shuffle Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.shuffle_rounded, size: 20),
                    label: const Text(
                      'Trộn bài',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    onPressed: () {
                      if (playlist.songs.isNotEmpty) {
                        final shuffled = List<Song>.from(playlist.songs)..shuffle();
                        player.playSong(shuffled.first, newQueue: shuffled);
                      }
                    },
                  ),

                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.download_for_offline_rounded, color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Track List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = playlist.songs[index];
                  return SongTile(
                    song: song,
                    index: index + 1,
                    onTap: () {
                      player.playSong(song, newQueue: playlist.songs);
                    },
                  );
                },
                childCount: playlist.songs.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
