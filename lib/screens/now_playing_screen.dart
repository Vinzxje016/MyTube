import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/equalizer_bars.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerController();

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final currentSong = player.currentSong;
        if (currentSong == null) {
          return const Scaffold(
            body: Center(child: Text('Chưa có bài hát nào')),
          );
        }

        final isLiked = player.isLiked(currentSong.id);
        final accentColor = currentSong.accentColor;

        return Scaffold(
          body: Stack(
            children: [
              // Dynamic Ambient Glow Background
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.background,
                ),
              ),
              Positioned(
                top: -100,
                left: -50,
                right: -50,
                height: 500,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withAlpha(90),
                        accentColor.withAlpha(30),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                ),
              ),

              // Frosted Glass Blur
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  color: Colors.black.withAlpha(70),
                ),
              ),

              // Main Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Top Navigation Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Column(
                            children: [
                              const Text(
                                'ĐANG PHÁT TỪ DANH SÁCH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentSong.album,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              size: 26,
                              color: Colors.white,
                            ),
                            onPressed: () => _showMoreModal(context, currentSong),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Center: Album Art OR Lyrics View
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: _showLyrics
                            ? _buildLyricsView(currentSong)
                            : _buildArtworkView(currentSong, accentColor, player.isPlaying),
                      ),

                      const Spacer(),

                      // Title & Favorite Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentSong.artist,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isLiked ? AppTheme.accent : Colors.white70,
                              size: 28,
                            ),
                            onPressed: () => player.toggleLike(currentSong.id),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Slider & Time
                      Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: accentColor,
                              thumbColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                            ),
                            child: Slider(
                              value: player.currentPosition.inSeconds.toDouble().clamp(
                                    0.0,
                                    currentSong.duration.inSeconds.toDouble(),
                                  ),
                              max: currentSong.duration.inSeconds.toDouble(),
                              onChanged: (value) {
                                player.seekTo(Duration(seconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(player.currentPosition),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDuration(currentSong.duration),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Main Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: player.isShuffle ? AppTheme.accent : Colors.white54,
                              size: 24,
                            ),
                            onPressed: () => player.toggleShuffle(),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                            onPressed: () => player.previousSong(),
                          ),

                          // Glowing Circular Play/Pause Button
                          GestureDetector(
                            onTap: () => player.togglePlayPause(),
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [accentColor, AppTheme.accent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withAlpha(120),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                            onPressed: () => player.nextSong(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.repeat_rounded,
                              color: player.isRepeat ? AppTheme.accent : Colors.white54,
                              size: 24,
                            ),
                            onPressed: () => player.toggleRepeat(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Bottom Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Bluetooth / Device indicator
                          InkWell(
                            onTap: () => _showDevicePicker(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.bluetooth_audio_rounded,
                                    color: AppTheme.emerald,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Tai nghe Bluetooth',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Row(
                            children: [
                              // Lyrics Toggle
                              IconButton(
                                icon: Icon(
                                  Icons.lyrics_rounded,
                                  color: _showLyrics ? AppTheme.accent : Colors.white70,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showLyrics = !_showLyrics;
                                  });
                                },
                              ),

                              // Queue Sheet
                              IconButton(
                                icon: const Icon(
                                  Icons.queue_music_rounded,
                                  color: Colors.white70,
                                  size: 24,
                                ),
                                onPressed: () => _showQueueModal(context, player),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtworkView(Song song, Color accentColor, bool isPlaying) {
    return Column(
      key: const ValueKey('artwork'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 290,
          height: 290,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha(100),
                blurRadius: 30,
                spreadRadius: 4,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              song.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppTheme.surfaceLight,
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isPlaying)
          EqualizerBars(
            isPlaying: true,
            color: accentColor,
            height: 20,
            barCount: 5,
          ),
      ],
    );
  }

  Widget _buildLyricsView(Song song) {
    return Container(
      key: const ValueKey('lyrics'),
      height: 310,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: song.lyrics.isEmpty
          ? const Center(
              child: Text(
                'Chưa có lời bài hát cho bài này',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          : ListView.builder(
              itemCount: song.lyrics.length,
              itemBuilder: (context, index) {
                final isCurrentLine = index == 1; // Highlight mock active lyric line
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    song.lyrics[index],
                    style: TextStyle(
                      fontSize: isCurrentLine ? 20 : 16,
                      fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.w500,
                      color: isCurrentLine ? Colors.white : AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showQueueModal(BuildContext context, MusicPlayerController player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Danh Sách Phát Tiếp Theo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: player.queue.length,
                  itemBuilder: (context, index) {
                    final item = player.queue[index];
                    final isCur = player.currentSong?.id == item.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.coverUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isCur ? AppTheme.accent : Colors.white,
                          fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        item.artist,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: isCur
                          ? const EqualizerBars(isPlaying: true, height: 16)
                          : Text(
                              item.durationString,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                      onTap: () {
                        player.playSong(item);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDevicePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thiết bị phát âm thanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone_android_rounded, color: Colors.white70),
              title: const Text('Loa ngoài điện thoại'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.headphones_rounded, color: AppTheme.emerald),
              title: const Text(
                'Tai nghe Bluetooth (Đang kết nối)',
                style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.check_rounded, color: AppTheme.emerald),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreModal(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Thêm vào Playlist'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Chia sẻ bài hát'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded),
              title: const Text('Hẹn giờ tắt nhạc'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.album_rounded),
              title: const Text('Xem album'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
