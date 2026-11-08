import 'song_model.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Song> recommendedSongs;
  final List<String> quickReplies;
  final String? playlistTitle;
  final bool isPlaylistDraft;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.recommendedSongs = const [],
    this.quickReplies = const [],
    this.playlistTitle,
    this.isPlaylistDraft = false,
  });
}
