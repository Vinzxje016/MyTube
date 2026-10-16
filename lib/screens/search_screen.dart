import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import 'ai_chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _recentSearches = [
    'Đen Vâu',
    'Cắt Đôi Nỗi Sầu',
    'Lo-Fi Học Tập',
    'The Weeknd',
    'Acoustic Chill',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = MusicData.sampleSongs.where((song) {
      final query = _searchQuery.toLowerCase().trim();
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          song.album.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Title & AI DJ button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tìm Kiếm',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primary.withAlpha(30),
                      foregroundColor: AppTheme.primaryLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: AppTheme.primary.withAlpha(80)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Hỏi AI DJ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiChatScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Bài hát, nghệ sĩ, hoặc album...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : const Icon(Icons.mic_none_rounded, color: AppTheme.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content Area
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults(filteredSongs)
                  : _buildBrowseContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Song> songs) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textMuted.withAlpha(120)),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả cho "$_searchQuery"',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hãy thử tìm kiếm với từ khóa khác',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 110),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        return SongTile(song: songs[index]);
      },
    );
  }

  Widget _buildBrowseContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      children: [
        // Recent Searches
        const Text(
          'Tìm Kiếm Gần Đây',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((tag) {
            return GestureDetector(
              onTap: () {
                _searchController.text = tag;
                setState(() {
                  _searchQuery = tag;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      tag,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Browse Genres Grid
        const Text(
          'Khám Phá Thể Loại',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: MusicData.musicGenres.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 94,
          ),
          itemBuilder: (context, index) {
            final genre = MusicData.musicGenres[index];
            final List<Color> colors = genre['colors'];
            final IconData icon = genre['icon'];

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Text(
                    genre['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Transform.rotate(
                      angle: 0.25,
                      child: Icon(
                        icon,
                        color: Colors.white.withAlpha(90),
                        size: 44,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
