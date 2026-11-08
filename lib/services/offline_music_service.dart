import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song_model.dart';
import 'music_repository.dart';

class OfflineMusicService extends ChangeNotifier {
  OfflineMusicService._();

  static final instance = OfflineMusicService._();
  static const maxStorageBytes = 1024 * 1024 * 1024;
  static const _indexKey = 'offline_song_index_v1';

  Future<Directory> _directory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}music',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<Map<String, dynamic>> _index() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_indexKey);
    if (encoded == null) return {};
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) return {};
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _saveIndex(Map<String, dynamic> index) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_indexKey, jsonEncode(index));
  }

  Future<int> get usedBytes async {
    final directory = await _directory();
    var total = 0;
    await for (final entity in directory.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<List<Song>> getDownloadedSongs() async {
    final index = await _index();
    final directory = await _directory();
    final songs = <Song>[];
    final staleIds = <String>[];
    for (final entry in index.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      final path = data['path'] as String;
      if (!await File(path).exists()) {
        staleIds.add(entry.key);
        continue;
      }
      songs.add(
        Song(
          id: entry.key,
          title: data['title'] as String,
          artist: data['artist'] as String,
          album: data['album'] as String? ?? '',
          duration: Duration(seconds: data['durationSeconds'] as int? ?? 0),
          coverUrl: data['coverUrl'] as String? ?? '',
          localAudioPath:
              '${directory.path}${Platform.pathSeparator}${File(path).uri.pathSegments.last}',
          tags: List<String>.from(data['tags'] as List? ?? const []),
        ),
      );
    }
    if (staleIds.isNotEmpty) {
      for (final id in staleIds) {
        index.remove(id);
      }
      await _saveIndex(index);
    }
    return songs;
  }

  Future<bool> downloadSong(
    Song song, {
    void Function(int received, int? total)? onProgress,
  }) async {
    final index = await _index();
    final existing = index[song.id];
    if (existing is Map && existing['path'] is String) {
      if (await File(existing['path'] as String).exists()) return false;
      index.remove(song.id);
      await _saveIndex(index);
    }
    final directory = await _directory();
    final currentBytes = await usedBytes;
    final refreshedSong = await MusicRepository.instance.refreshSong(song.id);
    final uri = Uri.tryParse(refreshedSong.audioUrl ?? '');
    if (uri == null || !uri.hasScheme) {
      throw const HttpException('Không có URL tải bài hát.');
    }

    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      client.close(force: true);
      throw HttpException('Tải nhạc lỗi HTTP ${response.statusCode}.');
    }
    final contentLength = response.contentLength > 0
        ? response.contentLength
        : null;
    if (contentLength != null &&
        currentBytes + contentLength > maxStorageBytes) {
      client.close(force: true);
      throw const FileSystemException('Đã vượt hạn mức tải offline 1 GB.');
    }

    final safeId = song.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final target = File(
      '${directory.path}${Platform.pathSeparator}$safeId.mp3',
    );
    final sink = target.openWrite();
    var received = 0;
    try {
      await for (final chunk in response) {
        received += chunk.length;
        if (currentBytes + received > maxStorageBytes) {
          throw const FileSystemException('Đã vượt hạn mức tải offline 1 GB.');
        }
        sink.add(chunk);
        onProgress?.call(received, contentLength);
      }
      await sink.flush();
      await sink.close();
      index[song.id] = {
        'path': target.path,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'durationSeconds': song.duration.inSeconds,
        'coverUrl': song.coverUrl,
        'tags': song.tags,
      };
      await _saveIndex(index);
      notifyListeners();
      return true;
    } catch (_) {
      await sink.close();
      if (await target.exists()) await target.delete();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> deleteSong(String songId) async {
    final index = await _index();
    final data = index.remove(songId);
    if (data is Map && data['path'] is String) {
      final file = File(data['path'] as String);
      if (await file.exists()) await file.delete();
    }
    await _saveIndex(index);
    notifyListeners();
  }

  Future<void> deleteAll() async {
    final index = await _index();
    for (final data in index.values) {
      if (data is Map && data['path'] is String) {
        final file = File(data['path'] as String);
        if (await file.exists()) await file.delete();
      }
    }
    await _saveIndex({});
    notifyListeners();
  }
}
