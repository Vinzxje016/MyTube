import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../models/song_model.dart';
import '../services/ai_music_service.dart';
import '../services/music_repository.dart';
import '../theme/app_theme.dart';
import '../controllers/music_player_controller.dart';
import '../widgets/mini_player.dart';
import '../widgets/cover_artwork.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  late Future<List<Song>> _catalogFuture;
  bool _isTyping = false;
  int _requestRevision = 0;

  @override
  void initState() {
    super.initState();
    _messages.add(AiMusicService.getInitialMessage());
    _catalogFuture = MusicRepository.instance.getSongs();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _textController.clear();

    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();
    final requestRevision = ++_requestRevision;

    ChatMessage aiResponse;
    try {
      final catalog = await _catalogFuture;
      aiResponse = await AiMusicService.generateResponse(
        trimmed,
        catalog,
        conversation: _messages,
      );
    } catch (error) {
      _catalogFuture = MusicRepository.instance.getSongs();
      aiResponse = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: error is AiMusicException
            ? error.message
            : 'AI DJ chưa kết nối được. Hãy kiểm tra cấu hình Gemini và thử lại.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    if (mounted && requestRevision == _requestRevision) {
      setState(() {
        _isTyping = false;
        _messages.add(aiResponse);
      });
      _scrollToBottom();
    }
  }

  void _resetChat() {
    _requestRevision++;
    setState(() {
      _messages.clear();
      _messages.add(AiMusicService.getInitialMessage());
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayerController();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(90),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI DJ Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.verified_rounded, color: AppTheme.cyan, size: 14),
                  ],
                ),
                Text(
                  'Gợi ý bài hát theo thói quen & tâm trạng',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.emerald,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Làm mới cuộc trò chuyện',
            onPressed: _resetChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _buildMessageItem(message, player);
              },
            ),
          ),

          // Mini Player if active
          const MiniPlayer(),

          // Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message, MusicPlayerController player) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // AI Message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Bubble
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),

                  // Recommended Songs inside bubble
                  if (message.recommendedSongs.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    Text(
                      'Gợi ý bài hát dành cho bạn (${message.recommendedSongs.length}):',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...message.recommendedSongs.map(
                      (song) => _buildSongRecommendationCard(song, player),
                    ),
                  ],
                  if (message.isPlaylistDraft) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _editAndSavePlaylist(message),
                        icon: const Icon(Icons.playlist_add_rounded),
                        label: const Text('Chỉnh và lưu playlist'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Quick Reply Chips
            if (message.quickReplies.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.quickReplies.map((reply) {
                  return ActionChip(
                    backgroundColor: AppTheme.surfaceLight,
                    side: BorderSide(color: AppTheme.primary.withAlpha(80)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    label: Text(
                      reply,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () => _sendMessage(reply),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSongRecommendationCard(Song song, MusicPlayerController player) {
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final isCur = player.currentSong?.id == song.id;
        final isPlaying = isCur && player.isPlaying;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCur ? AppTheme.primary.withAlpha(25) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCur ? AppTheme.primary : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CoverArtwork(
                  url: song.coverUrl,
                  width: 44,
                  height: 44,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        color: isCur ? AppTheme.accent : Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${song.artist} • ${song.durationString}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(34, 34),
                ),
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
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
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'AI DJ đang kết nối Gemini...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: Colors.white12, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _textController,
                enabled: !_isTyping,
                maxLength: 1200,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Nói tâm trạng của bạn (ví dụ: cần tập trung, buồn...)...',
                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _isTyping ? null : () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editAndSavePlaylist(ChatMessage message) async {
    final draft = await showDialog<_PlaylistDraftResult>(
      context: context,
      builder: (_) => _PlaylistDraftDialog(
        title: message.playlistTitle ?? 'Playlist AI gợi ý',
        songs: message.recommendedSongs,
      ),
    );
    if (draft == null) return;

    String? createdPlaylistId;
    try {
      final playlist = await MusicRepository.instance.createPlaylist(draft.title);
      createdPlaylistId = playlist.id;
      for (final song in draft.songs) {
        await MusicRepository.instance.addSongToPlaylist(playlist.id, song.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu playlist "${draft.title}" vào Thư viện.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (createdPlaylistId != null) {
        try {
          await MusicRepository.instance.deletePlaylist(createdPlaylistId);
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu playlist. Hãy thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _PlaylistDraftResult {
  final String title;
  final List<Song> songs;

  const _PlaylistDraftResult(this.title, this.songs);
}

class _PlaylistDraftDialog extends StatefulWidget {
  final String title;
  final List<Song> songs;

  const _PlaylistDraftDialog({required this.title, required this.songs});

  @override
  State<_PlaylistDraftDialog> createState() => _PlaylistDraftDialogState();
}

class _PlaylistDraftDialogState extends State<_PlaylistDraftDialog> {
  late final TextEditingController _titleController;
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _selectedIds = widget.songs.map((song) => song.id).toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh playlist'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              maxLength: 100,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Tên playlist'),
            ),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.38,
              child: ListView(
                children: widget.songs.map((song) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selectedIds.contains(song.id),
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
                    onChanged: (selected) => setState(() {
                      if (selected == true) {
                        _selectedIds.add(song.id);
                      } else {
                        _selectedIds.remove(song.id);
                      }
                    }),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _titleController.text.trim().isEmpty ||
                  _selectedIds.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    _PlaylistDraftResult(
                      _titleController.text.trim(),
                      widget.songs
                          .where((song) => _selectedIds.contains(song.id))
                          .toList(),
                    ),
                  ),
          child: const Text('Lưu vào Thư viện'),
        ),
      ],
    );
  }
}
