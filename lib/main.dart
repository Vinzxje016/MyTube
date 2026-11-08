import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth_gate.dart';
import 'screens/premium_result_screen.dart';
import 'theme/app_theme.dart';
import 'services/theme_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive status bar and navigation bar colors
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  if (defaultTargetPlatform == TargetPlatform.android) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.mytube.channel.audio',
      androidNotificationChannelName: 'MyTube playback',
      androidNotificationOngoing: true,
    );
  }

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  await ThemePreferences.instance.load();

  runApp(const MyTubeMusicApp());
}

class MyTubeMusicApp extends StatefulWidget {
  const MyTubeMusicApp({super.key});

  @override
  State<MyTubeMusicApp> createState() => _MyTubeMusicAppState();
}

class _MyTubeMusicAppState extends State<MyTubeMusicApp> {
  static const _paymentChannel = MethodChannel('com.example.mytube/payment');
  final _navigatorKey = GlobalKey<NavigatorState>();
  String? _lastPaymentUri;
  String? _pendingPaymentUri;

  @override
  void initState() {
    super.initState();
    _paymentChannel.setMethodCallHandler(_handleNativeCall);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialPaymentUri());
  }

  Future<void> _loadInitialPaymentUri() async {
    try {
      final uri = await _paymentChannel.invokeMethod<String>('getInitialPaymentUri');
      if (uri != null) _openPaymentResult(uri);
    } on PlatformException {
      // The payment callback is optional; the app can still open normally.
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'paymentReturn' && call.arguments is String) {
      _openPaymentResult(call.arguments as String);
    }
  }

  void _openPaymentResult(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'mytube' || uri.host != 'payment-return') return;
    if (_lastPaymentUri == value) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      _pendingPaymentUri = value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pending = _pendingPaymentUri;
        _pendingPaymentUri = null;
        if (pending != null) _openPaymentResult(pending);
      });
      return;
    }

    _lastPaymentUri = value;
    navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PremiumResultScreen(
          status: uri.queryParameters['status'] ?? 'unverified',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemePreferences.instance,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'MyTube Music',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemePreferences.instance.mode,
        home: SupabaseConfig.isConfigured
            ? const AuthGate()
            : const _SupabaseSetupScreen(),
      ),
    );
  }
}

class _SupabaseSetupScreen extends StatelessWidget {
  const _SupabaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chưa cấu hình Supabase. Chạy ứng dụng với SUPABASE_URL và '
            'SUPABASE_PUBLISHABLE_KEY qua --dart-define.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
