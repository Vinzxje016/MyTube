import 'package:flutter/material.dart';

import '../screens/ai_chat_screen.dart';
import '../screens/premium_screen.dart';
import '../services/premium_service.dart';

Future<void> openAiDj(BuildContext context) async {
  try {
    final expiry = await PremiumService.activeExpiry();
    if (!context.mounted) return;
    final upgraded = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => expiry == null ? const PremiumScreen() : const AiChatScreen(),
      ),
    );
    if (expiry == null && upgraded == true && context.mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const AiChatScreen()),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không kiểm tra được trạng thái Premium. Hãy thử lại.')),
    );
  }
}
