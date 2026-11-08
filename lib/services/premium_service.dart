import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumService {
  static final _client = Supabase.instance.client;

  static Future<DateTime?> activeExpiry() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client
        .from('premium_subscriptions')
        .select('expires_at')
        .eq('user_id', user.id)
        .maybeSingle();
    final value = row?['expires_at'];
    if (value is! String) return null;
    final expiry = DateTime.tryParse(value)?.toLocal();
    if (expiry == null || !expiry.isAfter(DateTime.now())) return null;
    return expiry;
  }

  static Future<Uri> createPayment() async {
    late final dynamic response;
    try {
      response = await _client.functions
          .invoke('vnpay-create-payment')
          .timeout(const Duration(seconds: 35));
    } on FunctionException catch (error) {
      final details = error.details;
      final code = details is Map ? details['code'] : null;
      switch (code) {
        case 'VNPAY_NOT_CONFIGURED':
          throw const FormatException('VNPay Sandbox chưa được cấu hình trên Supabase.');
      }
      rethrow;
    }
    final data = response.data;
    final url = data is Map ? data['paymentUrl'] : null;
    if (url is! String) throw const FormatException('VNPay không trả về đường dẫn thanh toán.');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host != 'sandbox.vnpayment.vn') {
      throw const FormatException('Đường dẫn VNPay không hợp lệ.');
    }
    return uri;
  }
}
