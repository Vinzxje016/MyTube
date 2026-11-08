import 'dart:async';

import 'package:flutter/material.dart';

import '../services/premium_service.dart';
import '../theme/app_theme.dart';

class PremiumResultScreen extends StatefulWidget {
  const PremiumResultScreen({super.key, required this.status});

  final String status;

  @override
  State<PremiumResultScreen> createState() => _PremiumResultScreenState();
}

class _PremiumResultScreenState extends State<PremiumResultScreen> {
  DateTime? _expiresAt;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.status != 'failed') unawaited(_checkActivation());
  }

  Future<void> _checkActivation() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      for (var attempt = 0; attempt < 10 && mounted; attempt++) {
        final expiry = await PremiumService.activeExpiry();
        if (!mounted) return;
        if (expiry != null) {
          setState(() {
            _expiresAt = expiry;
            _checking = false;
          });
          return;
        }
        if (attempt < 9) await Future<void>.delayed(const Duration(seconds: 2));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Không kiểm tra được trạng thái Premium.');
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final activated = _expiresAt != null;
    final failed = widget.status == 'failed';
    final unverified = widget.status != 'success' && !failed && !_checking;
    final icon = activated
        ? Icons.check_circle_rounded
        : failed
            ? Icons.cancel_rounded
            : unverified
                ? Icons.help_rounded
                : Icons.hourglass_top_rounded;
    final color = activated
        ? Colors.green
        : failed
            ? Theme.of(context).colorScheme.error
            : AppTheme.primary;
    final title = activated
        ? 'Thanh toán thành công'
        : failed
            ? 'Thanh toán chưa thành công'
        : unverified
            ? 'Chưa xác minh được giao dịch'
                : 'Đang xác nhận thanh toán';
    final detail = activated
        ? 'Premium đã được kích hoạt đến ${_formatDate(_expiresAt!)}.'
        : failed
            ? 'Giao dịch không hoàn tất. Bạn có thể thử thanh toán lại trong MyTube.'
            : unverified
                ? 'Mở MyTube Premium để kiểm tra trạng thái giao dịch.'
                : _error ?? 'Đang chờ VNPay xác nhận giao dịch.';

    return Scaffold(
      backgroundColor: context.pageColor,
      appBar: AppBar(title: const Text('Kết quả thanh toán')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.primaryTextColor, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(detail, textAlign: TextAlign.center, style: TextStyle(color: context.secondaryTextColor)),
              if (_checking) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ] else if (widget.status != 'failed' && !activated) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _checkActivation,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Kiểm tra lại'),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Quay lại MyTube'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
