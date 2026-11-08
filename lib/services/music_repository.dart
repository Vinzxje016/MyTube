import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';

class MusicRepository extends ChangeNotifier {
  MusicRepository._();

  static final MusicRepository instance = MusicRepository._();

  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;

  Future<List<Song>> getSongs({String query = ''}) async {
    List<Map<String, dynamic>> rows;
    try {
      rows = await _client
          .from('songs')
          .select('*, song_genres(genre_code, genres(code, name))')
          .eq('is_active', true)
          .order('title');
    } on PostgrestException catch (error) {
      debugPrint('Could not load song genre relations: ${error.message}');
      try {
        rows = await _client
            .from('songs')
            .select('*')
            .eq('is_active', true)
            .order('title');
      } catch (fallbackError) {
        throw SongCatalogLoadException(
          genreQueryError: error,
          fallbackQueryError: fallbackError,
        );
      }
    }
    final normalizedQuery = query.trim().toLowerCase();
    final matchingRows = rows.where((row) {
      if (normalizedQuery.isEmpty) return true;
      final tags = _genreNamesFromRow(row);
      return (row['title'] as String).toLowerCase().contains(normalizedQuery) ||
          (row['artist'] as String).toLowerCase().contains(normalizedQuery) ||
          (row['album'] as String? ?? '').toLowerCase().contains(
            normalizedQuery,
          ) ||
          tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
    });

    return _songsFromRows(matchingRows);
  }

  Future<List<Song>> getSongsByGenre(String genreName) async {
    final rows = await _client
        .from('songs')
        .select('*, song_genres(genre_code, genres(code, name))')
        .eq('is_active', true)
        .order('title');
    final normalizedGenre = genreName.trim().toLowerCase();
    final matchingRows = rows.where(
      (row) => _genreNamesFromRow(
        row,
      ).any((name) => name.trim().toLowerCase() == normalizedGenre),
    );
    return _songsFromRows(matchingRows);
  }

  Future<List<String>> getGenres() async {
    final rows = await _client.from('genres').select('name').order('name');
    return rows.map((row) => row['name'] as String).toList();
  }

  Future<Song> _songFromRow(Map<String, dynamic> row) async {
    final audioPath = row['audio_path'] as String;
    final signedUrl = await _createSignedUrl(audioPath);
    final coverPath = row['cover_path'] as String?;

    return Song(
      id: row['id'] as String,
      title: row['title'] as String,
      artist: row['artist'] as String,
      album: row['album'] as String? ?? '',
      duration: Duration(seconds: row['duration_seconds'] as int? ?? 0),
      coverUrl: coverPath == null
          ? ''
          : _client.storage.from('covers').getPublicUrl(coverPath),
      audioUrl: signedUrl,
      tags: _genreNamesFromRow(row),
    );
  }

  Future<String> _createSignedUrl(String path) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await _client.storage.from('tracks').createSignedUrl(path, 3600);
      } catch (error) {
        lastError = error;
        if (attempt < 2) {
          await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
        }
      }
    }
    throw lastError!;
  }

  Future<List<Song>> _songsFromRows(Iterable<Map<String, dynamic>> rows) async {
    final songs = <Song>[];
    final rowList = rows.toList();
    const batchSize = 6;
    for (var start = 0; start < rowList.length; start += batchSize) {
      final batch = rowList.skip(start).take(batchSize);
      final results = await Future.wait(batch.map((row) async {
        try {
          return await _songFromRow(row);
        } catch (error, stackTrace) {
          debugPrint('Skipping song ${row['id']} (${row['title']}): $error');
          debugPrintStack(stackTrace: stackTrace);
          return null;
        }
      }));
      songs.addAll(results.whereType<Song>());
    }
    return songs;
  }

  List<String> _genreNamesFromRow(Map<String, dynamic> row) {
    final relations = row['song_genres'] as List? ?? const [];
    final names = <String>[];
    for (final relation in relations) {
      if (relation is! Map<String, dynamic>) continue;
      final genre = relation['genres'];
      if (genre is Map<String, dynamic> && genre['name'] is String) {
        names.add(genre['name'] as String);
      }
    }
    return names.isNotEmpty
        ? names
        : List<String>.from(row['tags'] as List? ?? const []);
  }

  Future<Song> refreshSong(String songId) async {
    final row = await _client
        .from('songs')
        .select('*, song_genres(genre_code, genres(code, name))')
        .eq('id', songId)
        .eq('is_active', true)
        .single();
    return _songFromRow(row);
  }

  Future<void> recordPlay(String songId) async {
    await _client.from('listening_history').insert({
      'user_id': _userId,
      'song_id': songId,
    });
  }

  Future<int> getListeningTimeMilliseconds() async {
    final row = await _client
        .from('user_listening_time')
        .select('total_milliseconds')
        .eq('user_id', _userId)
        .maybeSingle();
    return row?['total_milliseconds'] as int? ?? 0;
  }

  Future<int> addListeningTime(Duration duration) async {
    final milliseconds = duration.inMilliseconds;
    if (milliseconds <= 0 || milliseconds > 30000) {
      throw ArgumentError.value(duration, 'duration');
    }
    final total = await _client.rpc(
      'add_listening_time',
      params: {'p_milliseconds': milliseconds},
    );
    return total as int;
  }

  Future<Set<String>> getLikedSongIds() async {
    final rows = await _client
        .from('liked_songs')
        .select('song_id')
        .eq('user_id', _userId);
    return rows.map((row) => row['song_id'] as String).toSet();
  }

  Future<void> setSongLiked(String songId, bool isLiked) async {
    final query = _client.from('liked_songs');
    if (isLiked) {
      await query.upsert({'user_id': _userId, 'song_id': songId});
    } else {
      await query.delete().eq('user_id', _userId).eq('song_id', songId);
    }
  }

  Future<List<Song>> getLikedSongs() async {
    final likedIds =
        (await _client
                .from('liked_songs')
                .select('song_id, created_at')
                .eq('user_id', _userId)
                .order('created_at', ascending: false))
            .map((row) => row['song_id'] as String)
            .toList();
    return _songsInOrder(likedIds);
  }

  Future<List<Song>> getListeningHistory({int limit = 100}) async {
    final ids =
        (await _client
                .from('listening_history')
                .select('song_id')
                .eq('user_id', _userId)
                .order('started_at', ascending: false)
                .limit(limit))
            .map((row) => row['song_id'] as String)
            .toList();
    return _songsInOrder(ids);
  }

  Future<List<Song>> _songsInOrder(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from('songs')
        .select('*, song_genres(genre_code, genres(code, name))')
        .eq('is_active', true)
        .inFilter('id', ids);
    final byId = <String, Map<String, dynamic>>{
      for (final row in rows) row['id'] as String: row,
    };
    return _songsFromRows(ids.where(byId.containsKey).map((id) => byId[id]!));
  }

  Future<List<Playlist>> getPlaylists() async {
    final rows = await _client
        .from('playlists')
        .select('id, name, created_at')
        .eq('user_id', _userId)
        .order('updated_at', ascending: false);

    return Future.wait(
      rows.map((row) async {
        final playlistSongs = await _client
            .from('playlist_songs')
            .select('song_id')
            .eq('playlist_id', row['id'] as String)
            .order('position');
        final songs = await _songsInOrder(
          playlistSongs.map((item) => item['song_id'] as String).toList(),
        );
        return Playlist(
          id: row['id'] as String,
          title: row['name'] as String,
          description: '',
          coverUrl: songs.isEmpty ? '' : songs.first.coverUrl,
          songs: songs,
        );
      }),
    );
  }

  Future<Playlist> createPlaylist(String name) async {
    final row = await _client
        .from('playlists')
        .insert({'user_id': _userId, 'name': name.trim()})
        .select('id, name')
        .single();
    final playlist = Playlist(
      id: row['id'] as String,
      title: row['name'] as String,
      description: '',
      coverUrl: '',
      songs: const [],
    );
    notifyListeners();
    return playlist;
  }

  Future<void> renamePlaylist(String playlistId, String name) async {
    await _client
        .from('playlists')
        .update({
          'name': name.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', playlistId)
        .eq('user_id', _userId);
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _client
        .from('playlists')
        .delete()
        .eq('id', playlistId)
        .eq('user_id', _userId);
    notifyListeners();
  }

  Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    final currentRows = await _client
        .from('playlist_songs')
        .select('song_id, position')
        .eq('playlist_id', playlistId)
        .order('position');
    if (currentRows.any((row) => row['song_id'] == songId)) return false;

    final nextPosition = currentRows.isEmpty
        ? 0
        : (currentRows.last['position'] as int) + 1;
    try {
      await _client.from('playlist_songs').insert({
        'playlist_id': playlistId,
        'song_id': songId,
        'position': nextPosition,
      });
    } on PostgrestException catch (error) {
      if (error.code == '23505') return false;
      rethrow;
    }
    await _client
        .from('playlists')
        .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', playlistId)
        .eq('user_id', _userId);
    notifyListeners();
    return true;
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _client
        .from('playlist_songs')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('song_id', songId);
    await _client
        .from('playlists')
        .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', playlistId)
        .eq('user_id', _userId);
    notifyListeners();
  }
}

class SongCatalogLoadException implements Exception {
  final PostgrestException genreQueryError;
  final Object fallbackQueryError;

  const SongCatalogLoadException({
    required this.genreQueryError,
    required this.fallbackQueryError,
  });

  @override
  String toString() =>
      'Song catalog query failed. '
      'Query with genres: ${_describePostgrestError(genreQueryError)}; '
      'fallback query: ${_describeError(fallbackQueryError)}';
}

String _describeError(Object error) => error is PostgrestException
    ? _describePostgrestError(error)
    : error.toString();

String _describePostgrestError(PostgrestException error) =>
    'code=${error.code ?? 'unknown'}, message=${error.message}, '
    'details=${error.details ?? 'none'}, hint=${error.hint ?? 'none'}';
