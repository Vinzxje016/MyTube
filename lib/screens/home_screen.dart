import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';
import '../services/ai_music_service.dart';
import '../services/music_repository.dart';
import '../theme/app_theme.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/song_card.dart';
import '../widgets/song_tile.dart';
import '../widgets/cover_artwork.dart';
import '../widgets/ai_dj_entry.dart';
import 'playlist_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Song>> _songsFuture;
  Future<List<Playlist>>? _playlistsFuture;
  String? _selectedGenre;

  // Habit Recommendation State
  String _selectedHabitMood = 'chill_night';
  final List<Map<String, String>> _habitMoods = [
    {'key': 'chill_night', 'label': '🌙 Đêm Chill (Thường nghe)'},
    {'key': 'workout', 'label': '⚡ Năng lượng Gym'},
    {'key': 'focus', 'label': '☕ Tập trung làm việc'},
    {'key': 'rainy_mood', 'label': '🌧️ Chiều mưa'},
    {'key': 'love', 'label': '❤️ Lãng mạn'},
  ];

  @override
  void initState() {
    super.initState();
    MusicRepository.instance.addListener(_onPlaylistsChanged);
    _songsFuture = MusicRepository.instance.getSongs();
    if (Supabase.instance.client.auth.currentUser != null) {
      _playlistsFuture = MusicRepository.instance.getPlaylists();
    }
    _songsFuture.then(MusicPlayerController().setQueue, onError: (Object _) {});
  }

  @override
  void dispose() {
    MusicRepository.instance.removeListener(_onPlaylistsChanged);
    super.dispose();
  }

  void _onPlaylistsChanged() {
    if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
    setState(() {
      _playlistsFuture = MusicRepository.instance.getPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerController();
    return Scaffold(
      backgroundColor: context.pageColor,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Song>>(
          future: _songsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Home catalog load failed: ${snapshot.error}');
              debugPrintStack(stackTrace: snapshot.stackTrace);
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Không tải được danh sách bài hát.'),
                    if (kDebugMode && snapshot.error != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    TextButton(
                      onPressed: () => setState(
                        () =>
                            _songsFuture = MusicRepository.instance.getSongs(),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final songs = snapshot.data!;
            if (songs.isEmpty) {
              return const Center(
                child: Text('Chưa có bài hát trong thư viện.'),
              );
            }
            final habitInsights = AiMusicService.getHabitInsights(songs);
            final habitSongs = AiMusicService.getSongsByMood(
              _selectedHabitMood,
              songs,
            );
            final genres =
                songs
                    .expand((song) => song.tags)
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort(
                    (left, right) =>
                        left.toLowerCase().compareTo(right.toLowerCase()),
                  );
            if (_selectedGenre != null && !genres.contains(_selectedGenre)) {
              _selectedGenre = null;
            }
            final visibleSongs = _filterSongs(songs);
            final currentUser = Supabase.instance.client.auth.currentUser;
            final email = currentUser?.email;
            final avatarUrl =
                currentUser?.userMetadata?['avatar_url'] as String?;
            final displayName =
                currentUser?.userMetadata?['name'] as String? ??
                email?.split('@').first ??
                'bạn';

            return CustomScrollView(
              slivers: [
                // Top App Bar / Greeting Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.raisedSurfaceColor,
                                  border: Border.all(
                                    color: AppTheme.primaryLight,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: avatarUrl == null || avatarUrl.isEmpty
                                      ? Icon(
                                          Icons.person_rounded,
                                          color: context.iconTextColor,
                                        )
                                      : Image.network(
                                          avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Icon(
                                            Icons.person_rounded,
                                            color: context.iconTextColor,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Xin chào, $displayName',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: context.primaryTextColor,
                                      ),
                                    ),
                                    Text(
                                      'Cùng thưởng thức âm nhạc hôm nay',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.mutedTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Actions with Glowing AI DJ Button
                        Row(
                          children: [
                            // AI DJ Quick Chat Button
                            GestureDetector(
                              onTap: () => openAiDj(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withAlpha(90),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'AI DJ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Badge(
                                smallSize: 8,
                                backgroundColor: AppTheme.accent,
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  color: context.iconTextColor,
                                ),
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (genres.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 38,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: genres.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final genre = index == 0 ? null : genres[index - 1];
                          final isSelected = _selectedGenre == genre;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedGenre = genre),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : context.surfaceColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : context.borderColor,
                                ),
                              ),
                              child: Text(
                                genre ?? 'Tất cả',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : context.secondaryTextColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Interactive AI DJ Assistant Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                          onTap: () => openAiDj(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4F46E5),
                              Color(0xFF9333EA),
                              Color(0xFFDB2777),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withAlpha(80),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.psychology_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Trợ lý âm nhạc AI DJ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Nói cảm xúc hoặc hoạt động, AI sẽ gợi ý ngay bài hát phù hợp!',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_rounded,
                                color: Color(0xFF7C3AED),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 22)),

                // GỢI Ý THEO THÓI QUEN NGƯỜI DÙNG (Personalized Habit Recommendations)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Gợi Ý Theo Thói Quen',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: context.primaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cyan.withAlpha(30),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.cyan.withAlpha(80),
                                    ),
                                  ),
                                  child: const Text(
                                    'Dành riêng cho bạn',
                                    style: TextStyle(
                                      color: AppTheme.cyan,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          habitInsights['insightText'] as String,
                          style: TextStyle(
                            color: context.mutedTextColor,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Mood & Vibe Chips
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _habitMoods.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final mood = _habitMoods[index];
                              final isSelected =
                                  _selectedHabitMood == mood['key'];

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedHabitMood = mood['key']!;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : context.surfaceColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : context.borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    mood['label']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : context.secondaryTextColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // Habit Songs List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = habitSongs[index];
                      return SongTile(song: song, index: index + 1);
                    }, childCount: habitSongs.length.clamp(0, 3)),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Quick Play 2-column Grid (Gần đây)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nghe Nhanh',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleSongs.length.clamp(0, 4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                mainAxisExtent: 56,
                              ),
                          itemBuilder: (context, index) {
                            final song = visibleSongs[index];
                            return _buildQuickPlayCard(context, song, player);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                SliverToBoxAdapter(
                  child: FutureBuilder<List<Playlist>>(
                    future: _playlistsFuture,
                    builder: (context, snapshot) {
                      final playlists = snapshot.data ?? const <Playlist>[];
                      if (playlists.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Playlist của bạn',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: context.primaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 240,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlists[index];
                                return PlaylistCard(
                                  playlist: playlist,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlaylistDetailScreen(
                                          playlist: playlist,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Gợi ý bài hát mới (Song Cards Carousel)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Bài Hát Trong Thư Viện',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 230,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: visibleSongs.length,
                          itemBuilder: (context, index) {
                            return SongCard(song: visibleSongs[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Bảng xếp hạng thịnh hành (Trending List)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tất Cả Bài Hát',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return SongTile(
                        song: visibleSongs[index],
                        index: index + 1,
                      );
                    }, childCount: visibleSongs.length),
                  ),
                ),

                if (visibleSongs.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Chưa có bài hát thuộc thể loại này.'),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Song> _filterSongs(List<Song> songs) {
    final selectedGenre = _selectedGenre;
    if (selectedGenre == null) return songs;
    return songs.where((song) => song.tags.contains(selectedGenre)).toList();
  }

  Widget _buildQuickPlayCard(
    BuildContext context,
    Song song,
    MusicPlayerController player,
  ) {
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final isCur = player.currentSong?.id == song.id;

        return GestureDetector(
          onTap: () => player.playSong(song),
          child: Container(
            decoration: BoxDecoration(
              color: isCur
                  ? AppTheme.primary.withAlpha(30)
                  : context.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCur ? AppTheme.primary : context.borderColor,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
                  child: CoverArtwork(
                    url: song.coverUrl,
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isCur ? AppTheme.accent : context.primaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isCur && player.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: isCur ? AppTheme.accent : context.iconTextColor,
                    size: 26,
                  ),
                  onPressed: () {
                    if (isCur) {
                      player.togglePlayPause();
                    } else {
                      player.playSong(song);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
