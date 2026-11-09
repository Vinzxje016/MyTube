import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileService extends ChangeNotifier {
  UserProfileService._();

  static final instance = UserProfileService._();

  String? _userId;
  String? _avatarUrl;
  RealtimeChannel? _channel;
  bool _loading = false;

  String? get avatarUrl => _avatarUrl;

  Future<void> load() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null || _loading) return;
    if (_userId == user.id && _channel != null) return;

    _loading = true;
    try {
      if (_userId != user.id) {
        final previousChannel = _channel;
        _channel = null;
        if (previousChannel != null) {
          await client.removeChannel(previousChannel);
        }
        _userId = user.id;
        _avatarUrl = user.userMetadata?['avatar_url'] as String?;
        notifyListeners();
      }

      final userId = user.id;
      _channel = client
          .channel('profile-avatar:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profiles',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: userId,
            ),
            callback: (payload) {
              if (_userId != userId) return;
              final value = payload.newRecord['avatar_url'];
              _avatarUrl = value is String ? value : null;
              notifyListeners();
            },
          )
          .subscribe();

      final row = await client
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) {
        final metadataAvatar = user.userMetadata?['avatar_url'] as String?;
        await client.from('profiles').insert({
          'id': userId,
          'avatar_url': metadataAvatar,
        });
        _avatarUrl = metadataAvatar;
      } else {
        _avatarUrl = row['avatar_url'] as String?;
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Could not load synchronized profile: $error');
      final failedChannel = _channel;
      _channel = null;
      if (failedChannel != null) {
        await client.removeChannel(failedChannel);
      }
    } finally {
      _loading = false;
    }
  }

  Future<void> updateAvatar(String avatarUrl) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Người dùng chưa đăng nhập.');

    await client.from('profiles').upsert({
      'id': user.id,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    _userId = user.id;
    _avatarUrl = avatarUrl;
    notifyListeners();
  }
}
