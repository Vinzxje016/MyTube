import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/theme_preferences.dart';
import '../services/premium_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sleep_timer_sheet.dart';
import 'ai_chat_screen.dart';
import 'edit_profile_screen.dart';
import 'premium_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<DateTime?> _premiumFuture;

  @override
  void initState() {
    super.initState();
    unawaited(UserProfileService.instance.load());
    _premiumFuture = PremiumService.activeExpiry();
  }

  Future<void> _openPremium() async {
    final useAiDj = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const PremiumScreen()),
    );
    if (mounted) setState(() => _premiumFuture = PremiumService.activeExpiry());
    if (useAiDj == true && mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const AiChatScreen()),
      );
    }
  }

  Future<void> _editProfile() async {
    final emailChanged = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (!mounted || emailChanged == null) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          emailChanged
              ? 'Đã lưu thông tin. Hãy xác nhận email mới trong hộp thư.'
              : 'Đã cập nhật thông tin cá nhân.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final displayName =
        metadata['name'] as String? ??
        user?.email?.split('@').first ??
        'Tài khoản MyTube';
    final avatarUrl = metadata['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: context.pageColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cá nhân',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: context.primaryTextColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Đăng xuất',
                  onPressed: () => Supabase.instance.client.auth.signOut(),
                  icon: Icon(
                    Icons.logout_rounded,
                    color: context.iconTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Material(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _editProfile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      ListenableBuilder(
                        listenable: UserProfileService.instance,
                        builder: (context, _) => _ProfileAvatar(
                          url: UserProfileService.instance.avatarUrl ?? avatarUrl,
                          size: 64,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.primaryTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.mutedTextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_outlined, color: context.mutedTextColor),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<DateTime?>(
              future: _premiumFuture,
              builder: (context, snapshot) {
                final expiry = snapshot.data;
                final active = expiry != null;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: context.accentColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(active ? 'Premium đang hoạt động' : 'MyTube Premium',
                                style: TextStyle(color: context.primaryTextColor, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              snapshot.connectionState == ConnectionState.waiting
                                  ? 'Đang kiểm tra gói đăng ký'
                                  : active
                                      ? 'Có hiệu lực đến ${expiry.day.toString().padLeft(2, '0')}.${expiry.month.toString().padLeft(2, '0')}.${expiry.year}'
                                      : 'AI DJ và gợi ý âm nhạc cá nhân hóa',
                              style: TextStyle(color: context.mutedTextColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(onPressed: _openPremium, child: Text(active ? 'Chi tiết' : 'Nâng cấp')),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Cài đặt ứng dụng',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.primaryTextColor,
              ),
            ),
            const SizedBox(height: 10),
            ListenableBuilder(
              listenable: ThemePreferences.instance,
              builder: (context, _) => _SettingTile(
                icon: Icons.palette_outlined,
                title: 'Giao diện ứng dụng',
                subtitle: 'Sáng, tối hoặc theo hệ thống',
                trailing: switch (ThemePreferences.instance.mode) {
                  ThemeMode.light => 'Sáng',
                  ThemeMode.dark => 'Tối',
                  ThemeMode.system => 'Hệ thống',
                },
                onTap: _showThemePicker,
              ),
            ),
            ListenableBuilder(
              listenable: ThemePreferences.instance,
              builder: (context, _) => _SettingTile(
                icon: Icons.timer_outlined,
                title: 'Hẹn giờ ngủ',
                subtitle: 'Theo thời gian hoặc khi hết bài hiện tại',
                trailing: 'Mở',
                onTap: () => showSleepTimerSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showThemePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: ListenableBuilder(
            listenable: ThemePreferences.instance,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Giao diện ứng dụng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Hệ thống'),
                      icon: Icon(Icons.settings_suggest_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Sáng'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Tối'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {ThemePreferences.instance.mode},
                  onSelectionChanged: (selection) async {
                    await ThemePreferences.instance.setMode(selection.first);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? url;
  final double size;

  const _ProfileAvatar({required this.url, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.raisedSurfaceColor,
      shape: BoxShape.circle,
      border: Border.all(color: AppTheme.primary.withAlpha(110), width: 2),
      image: url == null || url!.isEmpty
          ? null
          : DecorationImage(
              image: NetworkImage(url!),
              fit: BoxFit.cover,
              onError: (_, _) {},
            ),
    ),
    child: url == null || url!.isEmpty
        ? Icon(
            Icons.person_rounded,
            color: context.iconTextColor,
            size: size * .58,
          )
        : null,
  );
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: context.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.accentColor, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trailing,
                style: TextStyle(color: context.accentColor, fontSize: 12),
              ),
              Icon(Icons.chevron_right_rounded, color: context.mutedTextColor),
            ],
          ),
        ),
      ),
    ),
  );
}
