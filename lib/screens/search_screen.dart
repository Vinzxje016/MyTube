import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/music_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import '../widgets/ai_dj_entry.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGenre;
  late Future<List<String>> _genresFuture;

  final List<String> _recentSearches = [
    'Đen Vâu',
    'Cắt Đôi Nỗi Sầu',
    'Lo-Fi Học Tập',
    'The Weeknd',
    'Acoustic Chill',
  ];

  @override
  void initState() {
    super.initState();
    _genresFuture = MusicRepository.instance.getGenres();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageColor,
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
                  Text(
                    'Tìm Kiếm',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: context.primaryTextColor,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primary.withAlpha(30),
                      foregroundColor: context.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: AppTheme.primary.withAlpha(80)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text(
                      'Hỏi AI DJ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () => openAiDj(context),
                  ),
                ],
              ),
            ),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Bài hát, nghệ sĩ, hoặc album...',
                    hintStyle: TextStyle(
                      color: context.mutedTextColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: context.mutedTextColor,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: context.mutedTextColor,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : Icon(
                            Icons.mic_none_rounded,
                            color: context.mutedTextColor,
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _selectedGenre = null;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content Area
            Expanded(
              child: _searchQuery.isNotEmpty || _selectedGenre != null
                  ? _buildSearchResults()
                  : _buildBrowseContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Song>>(
      future: _selectedGenre == null
          ? MusicRepository.instance.getSongs(query: _searchQuery)
          : MusicRepository.instance.getSongsByGenre(_selectedGenre!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Không thể tải kết quả tìm kiếm.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final songs = snapshot.data!;
        if (songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: context.mutedTextColor.withAlpha(150),
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy bài hát${_selectedGenre == null ? ' cho "$_searchQuery"' : ' thuộc "$_selectedGenre"'}',
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hãy thử tìm kiếm với từ khóa khác',
                  style: TextStyle(color: context.mutedTextColor, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 110),
          itemCount: songs.length + (_selectedGenre == null ? 0 : 1),
          itemBuilder: (context, index) {
            if (_selectedGenre != null && index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedGenre!,
                        style: TextStyle(
                          color: context.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bỏ lọc thể loại',
                      onPressed: () => setState(() => _selectedGenre = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              );
            }
            return SongTile(
              song: songs[index - (_selectedGenre == null ? 0 : 1)],
            );
          },
        );
      },
    );
  }

  Widget _buildBrowseContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      children: [
        // Recent Searches
        Text(
          'Tìm Kiếm Gần Đây',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.primaryTextColor,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 14,
                      color: context.mutedTextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tag,
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Browse Genres Grid
        Text(
          'Khám Phá Thể Loại',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.primaryTextColor,
          ),
        ),
        const SizedBox(height: 14),

        _buildGenreGrid(),
      ],
    );
  }

  Widget _buildGenreGrid() {
    return FutureBuilder<List<String>>(
      future: _genresFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Không tải được thể loại.',
            style: TextStyle(color: context.mutedTextColor),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final genres = snapshot.data!;
        if (genres.isEmpty) {
          return Text(
            'Chưa có thể loại trong catalog.',
            style: TextStyle(color: context.mutedTextColor),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: genres.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 94,
          ),
          itemBuilder: (context, index) {
            final genreName = genres[index];
            final style =
                MusicData.musicGenres[index % MusicData.musicGenres.length];
            final colors = style['colors'] as List<Color>;
            final icon = style['icon'] as IconData;
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedGenre = genreName;
                  });
                },
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Text(
                        genreName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}
