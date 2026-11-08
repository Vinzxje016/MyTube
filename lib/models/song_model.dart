import 'package:flutter/material.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String coverUrl;
  final String? audioUrl;
  final String? localAudioPath;
  final Color accentColor;
  final List<String> lyrics;
  final bool isExplicit;
  final List<String> tags;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.coverUrl,
    this.audioUrl,
    this.localAudioPath,
    this.accentColor = const Color(0xFF7C3AED),
    this.lyrics = const [],
    this.isExplicit = false,
    this.tags = const [],
  });

  String get durationString {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Song withLocalAudioPath(String? path) => Song(
    id: id,
    title: title,
    artist: artist,
    album: album,
    duration: duration,
    coverUrl: coverUrl,
    audioUrl: audioUrl,
    localAudioPath: path,
    accentColor: accentColor,
    lyrics: lyrics,
    isExplicit: isExplicit,
    tags: tags,
  );
}

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<Song> songs;
  final List<Color> gradientColors;

  const Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.songs,
    this.gradientColors = const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  });

  int get trackCount => songs.length;
}

class MusicData {
  static const List<Map<String, dynamic>> musicGenres = [
    {
      'title': 'V-Pop',
      'colors': [Color(0xFFEC4899), Color(0xFFBE185D)],
      'icon': Icons.music_note_rounded,
    },
    {
      'title': 'Lo-Fi & Chill',
      'colors': [Color(0xFF6366F1), Color(0xFF4338CA)],
      'icon': Icons.nightlight_round,
    },
    {
      'title': 'Hip-Hop & Rap',
      'colors': [Color(0xFFF59E0B), Color(0xFFD97706)],
      'icon': Icons.mic_external_on_rounded,
    },
    {
      'title': 'EDM & Dance',
      'colors': [Color(0xFF06B6D4), Color(0xFF0284C7)],
      'icon': Icons.graphic_eq_rounded,
    },
    {
      'title': 'Indie & Acoustic',
      'colors': [Color(0xFF10B981), Color(0xFF047857)],
      'icon': Icons.radio_rounded,
    },
    {
      'title': 'K-Pop',
      'colors': [Color(0xFFA855F7), Color(0xFF7E22CE)],
      'icon': Icons.favorite_rounded,
    },
    {
      'title': 'Rock & Metal',
      'colors': [Color(0xFFEF4444), Color(0xFFB91C1C)],
      'icon': Icons.electric_bolt_rounded,
    },
    {
      'title': 'Podcast & Radio',
      'colors': [Color(0xFF64748B), Color(0xFF334155)],
      'icon': Icons.podcasts_rounded,
    },
  ];
}
