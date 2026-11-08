import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  static const _avatarPicker = MethodChannel('com.example.mytube/profile');
  Uint8List? _avatarBytes;
  String? _avatarExtension;
  String? _avatarUrl;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _nameController.text = user?.userMetadata?['name'] as String? ?? '';
    _emailController.text = user?.email ?? '';
    _avatarUrl = user?.userMetadata?['avatar_url'] as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await _avatarPicker.invokeMapMethod<String, dynamic>(
        'pickAvatar',
      );
      if (image == null) return;
      final bytes = image['bytes'] as Uint8List?;
      final mimeType = image['mimeType'] as String?;
      if (bytes == null || mimeType == null) {
        _showMessage('Không thể đọc ảnh đã chọn.');
        return;
      }
      final extension = switch (mimeType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        'image/jpeg' => 'jpg',
        _ => null,
      };
      if (extension == null) {
        _showMessage('Ảnh cần có định dạng JPG, PNG hoặc WebP.');
        return;
      }
      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('Ảnh đại diện không được vượt quá 5 MB.');
        return;
      }
      setState(() {
        _avatarBytes = bytes;
        _avatarExtension = extension;
      });
    } on PlatformException catch (error) {
      if (mounted) _showMessage(error.message ?? 'Không thể mở thư viện ảnh.');
    } catch (_) {
      if (mounted) _showMessage('Không thể mở thư viện ảnh.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    setState(() => _loading = true);

    try {
      var avatarUrl = _avatarUrl;
      if (_avatarBytes != null) {
        final extension = _avatarExtension!;
        final path = '${user.id}/avatar.$extension';
        final mimeType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };
        await client.storage
            .from('profile-avatars')
            .uploadBinary(
              path,
              _avatarBytes!,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );
        avatarUrl =
            '${client.storage.from('profile-avatars').getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
      }

      final metadata = <String, dynamic>{...?user.userMetadata};
      metadata['name'] = _nameController.text.trim();
      if (avatarUrl != null) metadata['avatar_url'] = avatarUrl;

      final newEmail = _emailController.text.trim();
      final emailChanged =
          newEmail.toLowerCase() != (user.email ?? '').toLowerCase();
      final password = _passwordController.text;
      await client.auth.updateUser(
        UserAttributes(
          data: metadata,
          email: emailChanged ? newEmail : null,
          password: password.isEmpty ? null : password,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, emailChanged);
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } on StorageException catch (error) {
      if (mounted) {
        _showMessage('Không thể tải ảnh lên. ${error.message}');
      }
    } catch (_) {
      if (mounted) _showMessage('Không thể lưu thay đổi. Hãy thử lại.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object>? avatarProvider = _avatarBytes != null
        ? MemoryImage(_avatarBytes!)
        : (_avatarUrl == null || _avatarUrl!.isEmpty
              ? null
              : NetworkImage(_avatarUrl!));

    return Scaffold(
      backgroundColor: context.pageColor,
      appBar: AppBar(
        title: Text(
          'Chỉnh sửa cá nhân',
          style: TextStyle(color: context.primaryTextColor),
        ),
        backgroundColor: context.pageColor,
        iconTheme: IconThemeData(color: context.primaryTextColor),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: context.raisedSurfaceColor,
                      backgroundImage: avatarProvider,
                      child: avatarProvider == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 54,
                              color: context.iconTextColor,
                            )
                          : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: 0,
                      child: IconButton.filled(
                        tooltip: 'Chọn ảnh đại diện',
                        onPressed: _loading ? null : _pickAvatar,
                        icon: const Icon(Icons.photo_camera_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tên hiển thị.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                  border: OutlineInputBorder(),
                  helperText: 'Email mới cần được xác nhận qua hộp thư.',
                ),
                validator: (value) =>
                    value == null || !value.trim().contains('@')
                    ? 'Nhập địa chỉ email hợp lệ.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  hintText: 'Để trống nếu không muốn đổi',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) =>
                    value != null && value.isNotEmpty && value.length < 6
                    ? 'Mật khẩu cần ít nhất 6 ký tự.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_passwordController.text.isEmpty) {
                    return value == null || value.isEmpty
                        ? null
                        : 'Nhập mật khẩu mới trước.';
                  }
                  return value == _passwordController.text
                      ? null
                      : 'Mật khẩu xác nhận chưa khớp.';
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_loading ? 'Đang lưu' : 'Lưu thay đổi'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
