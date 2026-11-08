import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/premium_service.dart';
import '../theme/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with WidgetsBindingObserver {
  DateTime? _expiresAt;
  bool _loading = true;
  bool _paying = false;
  bool _paymentStarted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _paymentStarted) {
      _paymentStarted = false;
      _pollForActivation();
    }
  }

  Future<void> _refresh() async {
    try {
      final expiry = await PremiumService.activeExpiry();
      if (!mounted) return;
      setState(() {
        _expiresAt = expiry;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được trạng thái Premium. Hãy thử làm mới.';
      });
    }
  }

  Future<void> _pollForActivation() async {
    for (var attempt = 0; attempt < 10 && mounted; attempt++) {
      await _refresh();
      if (_expiresAt != null) return;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (mounted && _expiresAt == null) {
      setState(() => _error = 'Chưa nhận được xác nhận từ VNPay. Trạng thái sẽ cập nhật khi hệ thống xử lý xong.');
    }
  }

  Future<void> _startPayment() async {
    setState(() {
      _paying = true;
      _error = null;
      _paymentStarted = false;
    });
    try {
      final uri = await PremiumService.createPayment();
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw const FormatException('Không mở được trang thanh toán VNPay.');
      if (mounted) setState(() => _paymentStarted = true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _expiresAt != null;
    return Scaffold(
      backgroundColor: context.pageColor,
      appBar: AppBar(title: const Text('MyTube Premium')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      active ? 'Premium đang hoạt động' : 'Mở khóa AI DJ',
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '10.000đ',
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('30 ngày Premium', style: TextStyle(color: context.secondaryTextColor)),
                if (active) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Có hiệu lực đến ${_formatDate(_expiresAt!)}',
                    style: TextStyle(color: context.secondaryTextColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (active)
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Dùng AI DJ'),
            )
          else
            FilledButton.icon(
              onPressed: _paying ? null : _startPayment,
              icon: _paying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payment_rounded),
              label: Text(_paying ? 'Đang tạo giao dịch' : 'Thanh toán qua VNPay'),
            ),
          if (!_loading && !active && _paymentStarted) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Kiểm tra trạng thái'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
