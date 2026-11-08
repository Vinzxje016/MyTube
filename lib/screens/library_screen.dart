import 'package:flutter/material.dart';
import '../controllers/music_player_controller.dart';
import '../models/song_model.dart';
import '../services/music_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import 'playlist_detail_screen.dart';
import '../widgets/cover_artwork.dart';
import '../services/offline_music_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _filters = [
    'Tất cả',
    'Danh sách phát',
    'Bài hát đã thích',
    'Lịch sử nghe',
    'Nghệ sĩ',
    'Đã tải về',
  ];

  int _selectedFilterIndex = 0;
  final List<Playlist> _optimisticPlaylists = [];
  late Future<List<Playlist>> _playlistsFuture;
  late Future<List<Song>> _likedSongsFuture;
  late Future<List<Song>> _historyFuture;
  int _historyRevision = 0;
  late Future<List<Song>> _downloadsFuture;
  Future<int>? _downloadBytesFuture;

  @override
  void initState() {
    super.initState();
    _loadFutures();
    _loadDownloads();
    MusicRepository.instance.addListener(_onPlaylistsChanged);
    OfflineMusicService.instance.addListener(_onDownloadsChanged);
    final player = MusicPlayerController();
    _historyRevision = player.historyRevision;
    player.addListener(_onPlayerChanged);
  }

  @override
  void dispose() {
    MusicPlayerController().removeListener(_onPlayerChanged);
    MusicRepository.instance.removeListener(_onPlaylistsChanged);
    OfflineMusicService.instance.removeListener(_onDownloadsChanged);
    super.dispose();
  }

  void _onDownloadsChanged() {
    _loadDownloads();
    if (_selectedFilterIndex == 5 && mounted) setState(() {});
  }

  void _loadDownloads() {
    _downloadsFuture = OfflineMusicService.instance.getDownloadedSongs();
    _downloadBytesFuture = OfflineMusicService.instance.usedBytes;
  }

  void _onPlayerChanged() {
    final player = MusicPlayerController();
    if (player.historyRevision == _historyRevision) return;
    _historyRevision = player.historyRevision;
    _historyFuture = MusicRepository.instance.getListeningHistory();
    if (_selectedFilterIndex == 3 && mounted) setState(() {});
  }

  void _loadFutures() {
    _playlistsFuture = MusicRepository.instance.getPlaylists();
    _likedSongsFuture = MusicRepository.instance.getLikedSongs();
    _historyFuture = MusicRepository.instance.getListeningHistory();
  }

  void _onPlaylistsChanged() {
    if (!mounted) return;
    setState(() {
      _playlistsFuture = MusicRepository.instance.getPlaylists();
    });
  }

  void _refresh() {
    setState(_loadFutures);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Thư Viện',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tạo playlist',
                    icon: const Icon(Icons.add_rounded, size: 28),
                    onPressed: _showCreatePlaylistDialog,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _selectedFilterIndex == index;
                  return ChoiceChip(
                    label: Text(_filters[index]),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedFilterIndex = index),
                    selectedColor: AppTheme.primary,
                    backgroundColor: context.surfaceColor,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : context.secondaryTextColor,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: selected
                          ? Colors.transparent
                          : context.borderColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildSelectedContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) {
      return _buildPlaylists();
    }
    if (_selectedFilterIndex == 2) {
      return _buildSongs(_likedSongsFuture, filterLiked: true);
    }
    if (_selectedFilterIndex == 3) {
      return _buildSongs(_historyFuture);
    }
    if (_selectedFilterIndex == 4) {
      return _buildEmpty('Chưa có nghệ sĩ theo dõi');
    }
    return _buildDownloads();
  }

  Widget _buildDownloads() => FutureBuilder<List<Song>>(
    future: _downloadsFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _buildEmpty('Không tải được danh sách offline.');
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final songs = snapshot.data!;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: FutureBuilder<int>(
                    future: _downloadBytesFuture,
                    builder: (context, bytes) => Text(
                      '${songs.length} bài · ${_formatBytes(bytes.data ?? 0)} / 1 GB',
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (songs.isNotEmpty)
                  IconButton(
                    tooltip: 'Xóa tất cả bản tải',
                    onPressed: _deleteAllDownloads,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
              ],
            ),
          ),
          if (songs.isEmpty)
            Expanded(child: _buildEmpty('Chưa có bài hát tải xuống.'))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 120),
                itemCount: songs.length,
                itemBuilder: (context, index) => SongTile(
                  song: songs[index],
                  index: index + 1,
                  onMorePressed: () => _deleteDownload(songs[index]),
                ),
              ),
            ),
        ],
      );
    },
  );

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _deleteDownload(Song song) async {
    await OfflineMusicService.instance.deleteSong(song.id);
    if (mounted) _showMessage('Đã xóa bản tải "${song.title}".');
  }

  Future<void> _deleteAllDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả bản tải?'),
        content: const Text('Các tệp nhạc offline sẽ bị xóa khỏi thiết bị.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
    if (confirmed == true) await OfflineMusicService.instance.deleteAll();
  }

  Widget _buildPlaylists() {
    return FutureBuilder<List<Playlist>>(
      future: _playlistsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError && _optimisticPlaylists.isEmpty) {
          return _buildEmpty('Không tải được playlist.');
        }
        if (!snapshot.hasData && _optimisticPlaylists.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final loadedPlaylists = snapshot.data ?? const <Playlist>[];
        final loadedIds = loadedPlaylists
            .map((playlist) => playlist.id)
            .toSet();
        final playlists = [
          ..._optimisticPlaylists.where(
            (playlist) => !loadedIds.contains(playlist.id),
          ),
          ...loadedPlaylists,
        ];
        if (playlists.isEmpty) {
          return _buildEmpty('Tạo playlist đầu tiên của bạn.');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CoverArtwork(
                    url: playlist.coverUrl,
                    width: 52,
                    height: 52,
                  ),
                ),
                title: Text(
                  playlist.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${playlist.trackCount} bài hát',
                  style: TextStyle(color: context.mutedTextColor),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'rename') _showRenamePlaylistDialog(playlist);
                    if (action == 'delete') _deletePlaylist(playlist);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa playlist')),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistDetailScreen(playlist: playlist),
                  ),
                ).then((_) => _refresh()),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSongs(Future<List<Song>> future, {bool filterLiked = false}) {
    return FutureBuilder<List<Song>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildEmpty('Không tải được danh sách bài hát.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListenableBuilder(
          listenable: MusicPlayerController(),
          builder: (context, _) {
            final songs = filterLiked
                ? snapshot.data!
                      .where((song) => MusicPlayerController().isLiked(song.id))
                      .toList()
                : snapshot.data!;
            if (songs.isEmpty) {
              return _buildEmpty(
                filterLiked
                    ? 'Chưa có bài hát yêu thích.'
                    : 'Chưa có lịch sử nghe.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 120),
              itemCount: songs.length,
              itemBuilder: (context, index) =>
                  SongTile(song: songs[index], index: index + 1),
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: TextStyle(color: context.secondaryTextColor),
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog() async {
    await _showPlaylistNameDialog(
      title: 'Tạo playlist mới',
      initialValue: '',
      onSave: (name) async {
        final playlist = await MusicRepository.instance.createPlaylist(name);
        if (!mounted) return;
        setState(() => _optimisticPlaylists.insert(0, playlist));
      },
    );
  }

  Future<void> _showRenamePlaylistDialog(Playlist playlist) async {
    await _showPlaylistNameDialog(
      title: 'Đổi tên playlist',
      initialValue: playlist.title,
      onSave: (name) async {
        await MusicRepository.instance.renamePlaylist(playlist.id, name);
        final optimisticIndex = _optimisticPlaylists.indexWhere(
          (item) => item.id == playlist.id,
        );
        if (optimisticIndex != -1) {
          final current = _optimisticPlaylists[optimisticIndex];
          _optimisticPlaylists[optimisticIndex] = Playlist(
            id: current.id,
            title: name,
            description: current.description,
            coverUrl: current.coverUrl,
            songs: current.songs,
          );
        }
      },
    );
  }

  Future<void> _showPlaylistNameDialog({
    required String title,
    required String initialValue,
    required Future<void> Function(String) onSave,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          _PlaylistNameDialog(title: title, initialValue: initialValue),
    );
    if (name == null || name.isEmpty) return;
    try {
      await onSave(name);
      if (!mounted) return;
      _refresh();
    } catch (_) {
      if (mounted) _showMessage('Không thể lưu playlist.');
    }
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    try {
      await MusicRepository.instance.deletePlaylist(playlist.id);
      if (mounted) {
        _optimisticPlaylists.removeWhere((item) => item.id == playlist.id);
        _refresh();
      }
    } catch (_) {
      if (mounted) _showMessage('Không thể xóa playlist.');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }
}

class _PlaylistNameDialog extends StatefulWidget {
  final String title;
  final String initialValue;

  const _PlaylistNameDialog({required this.title, required this.initialValue});

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.surfaceColor,
      title: Text(
        widget.title,
        style: TextStyle(color: context.primaryTextColor),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        style: TextStyle(color: context.primaryTextColor),
        decoration: const InputDecoration(hintText: 'Tên playlist'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
