import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../controllers/music_player_controller.dart';
import '../services/music_repository.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player.dart';
import '../services/offline_music_service.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late Playlist playlist;

  bool get _isUserPlaylist => playlist.id.length == 36;

  @override
  void initState() {
    super.initState();
    playlist = widget.playlist;
  }

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerController();
    final totalDuration = playlist.songs.fold<Duration>(
      Duration.zero,
      (total, song) => total + song.duration,
    );

    return Scaffold(
      bottomNavigationBar: const MiniPlayer(),
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
                  playlist.coverUrl.isEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: playlist.gradientColors,
                            ),
                          ),
                        )
                      : Image.network(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isUserPlaylist ? 'PLAYLIST CỦA BẠN' : 'PLAYLIST',
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
                          '${playlist.trackCount} bài hát • ${_formatDuration(totalDuration)}',
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
              if (_isUserPlaylist)
                IconButton(
                  tooltip: 'Thêm bài hát',
                  icon: const Icon(Icons.playlist_add_rounded),
                  onPressed: _addSong,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 26),
                    label: const Text(
                      'Phát tất cả',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () {
                      if (playlist.songs.isNotEmpty) {
                        player.playSong(
                          playlist.songs.first,
                          newQueue: playlist.songs,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 14),

                  // Shuffle Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.shuffle_rounded, size: 20),
                    label: const Text(
                      'Trộn bài',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () {
                      if (playlist.songs.isNotEmpty) {
                        final shuffled = List<Song>.from(playlist.songs)
                          ..shuffle();
                        player.playSong(shuffled.first, newQueue: shuffled);
                      }
                    },
                  ),

                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: 'Tải toàn bộ playlist',
                    onPressed: playlist.songs.isEmpty
                        ? null
                        : _downloadPlaylist,
                    icon: const Icon(Icons.download_for_offline_outlined),
                  ),
                ],
              ),
            ),
          ),

          // Track List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final song = playlist.songs[index];
                return SongTile(
                  song: song,
                  index: index + 1,
                  onMorePressed: _isUserPlaylist
                      ? () => _removeSong(song)
                      : null,
                  onTap: () {
                    player.playSong(song, newQueue: playlist.songs);
                  },
                );
              }, childCount: playlist.songs.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadPlaylist() async {
    var downloaded = 0;
    var alreadySaved = 0;
    var failed = 0;
    for (final song in playlist.songs) {
      try {
        if (await OfflineMusicService.instance.downloadSong(song)) {
          downloaded++;
        } else {
          alreadySaved++;
        }
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    final text = failed == 0
        ? 'Đã tải $downloaded bài${alreadySaved > 0 ? ', $alreadySaved bài đã có sẵn' : ''}.'
        : 'Đã tải $downloaded bài, $alreadySaved bài đã có sẵn, $failed bài gặp lỗi.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _addSong() async {
    final allSongs = await MusicRepository.instance.getSongs();
    if (!mounted) return;
    final existingIds = playlist.songs.map((song) => song.id).toSet();
    final candidates = allSongs
        .where((song) => !existingIds.contains(song.id))
        .toList();
    if (candidates.isEmpty) {
      _showMessage('Tất cả bài hát đã có trong playlist.');
      return;
    }
    final selectedSongs = await showModalBottomSheet<List<Song>>(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      builder: (context) => _SongPickerSheet(songs: candidates),
    );
    if (selectedSongs == null || selectedSongs.isEmpty) return;
    try {
      var addedCount = 0;
      for (final song in selectedSongs) {
        if (await MusicRepository.instance.addSongToPlaylist(
          playlist.id,
          song.id,
        )) {
          addedCount++;
        }
      }
      await _reloadPlaylist();
      if (mounted) {
        _showMessage('Đã thêm $addedCount bài hát vào playlist.');
      }
    } catch (_) {
      if (mounted) _showMessage('Không thể thêm bài hát vào playlist.');
    }
  }

  Future<void> _removeSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Xóa bài khỏi playlist?'),
        content: Text(song.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await MusicRepository.instance.removeSongFromPlaylist(
        playlist.id,
        song.id,
      );
      await _reloadPlaylist();
    } catch (_) {
      if (mounted) _showMessage('Không thể xóa bài hát khỏi playlist.');
    }
  }

  Future<void> _reloadPlaylist() async {
    final playlists = await MusicRepository.instance.getPlaylists();
    if (!mounted) return;
    setState(() {
      playlist = playlists.firstWhere((item) => item.id == playlist.id);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _SongPickerSheet extends StatefulWidget {
  final List<Song> songs;

  const _SongPickerSheet({required this.songs});

  @override
  State<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<_SongPickerSheet> {
  final Set<String> _selectedIds = {};

  void _toggleSong(Song song) {
    setState(() {
      if (!_selectedIds.add(song.id)) _selectedIds.remove(song.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thêm bài hát',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _selectedIds.isEmpty
                              ? 'Nhấn giữ một bài để bắt đầu chọn nhiều bài'
                              : '${_selectedIds.length} bài đã chọn',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.songs.length,
                itemBuilder: (context, index) {
                  final song = widget.songs[index];
                  final selected = _selectedIds.contains(song.id);
                  return ListTile(
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primaryLight,
                          )
                        : const Icon(
                            Icons.music_note_rounded,
                            color: AppTheme.textMuted,
                          ),
                    onLongPress: () => _toggleSong(song),
                    onTap: () => _toggleSong(song),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          widget.songs
                              .where((song) => _selectedIds.contains(song.id))
                              .toList(),
                        ),
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: Text('Thêm ${_selectedIds.length} bài'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
