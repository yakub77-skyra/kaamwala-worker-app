/// KaamWala Partner (worker app) bootstrap.
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaamwala_partner/core/env/env.dart';
import 'package:kaamwala_partner/core/routing/app_router.dart';
import 'package:kaamwala_partner/core/theme/app_theme.dart';
import 'package:kaamwala_partner/features/shared/providers/connectivity_provider.dart';
import 'package:kaamwala_partner/services/analytics_service.dart';
import 'package:kaamwala_partner/services/fcm_service.dart';
import 'package:kaamwala_partner/services/supabase_service.dart';
import 'package:kaamwala_partner/l10n/app_localizations.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode && !Env.isConfigured) {
    runApp(const _MisconfiguredApp());
    return;
  }
  await SupabaseService.init();
  await AnalyticsService.ensureInitialized();
  unawaited(AnalyticsService.logEvent('app_open', {'role': 'worker'}));
  runApp(const ProviderScope(child: KaamWalaPartnerApp()));
}

/// Shown instead of the app when a release build ships without KW_* env vars.
class _MisconfiguredApp extends StatelessWidget {
  const _MisconfiguredApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Build configuration error',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This build was compiled without backend configuration '
                  '(KW_SUPABASE_URL / KW_SUPABASE_ANON_KEY missing). '
                  'Please rebuild with --dart-define-from-file=.env.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KaamWalaPartnerApp extends ConsumerStatefulWidget {
  const KaamWalaPartnerApp({super.key});

  @override
  ConsumerState<KaamWalaPartnerApp> createState() => _KaamWalaPartnerAppState();
}

class _KaamWalaPartnerAppState extends ConsumerState<KaamWalaPartnerApp> {
  StreamSubscription<RemoteMessage>? _tapSub;

  @override
  void initState() {
    super.initState();
    unawaited(_initPushRouting());
  }

  Future<void> _initPushRouting() async {
    await FcmService.ensureInitialized();
    if (!FcmService.isAvailable) return;
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null && mounted) {
        _routeFromPush(initial.data);
      }
      _tapSub = FirebaseMessaging.onMessageOpenedApp.listen((m) {
        if (mounted) _routeFromPush(m.data);
      });
    } on Exception catch (_) {}
  }

  void _routeFromPush(Map<String, dynamic> data) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final explicit = data['route'];
    if (explicit is String && explicit.startsWith('/')) {
      ctx.go(explicit);
      return;
    }
    ctx.go('/w/jobs');
  }

  @override
  void dispose() {
    unawaited(_tapSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'KaamWala Partner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) => _OfflineBoundary(child: child),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
      ],
    );
  }
}

/// Shows a persistent banner above the app while offline.
class _OfflineBoundary extends ConsumerWidget {
  const _OfflineBoundary({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider);
    final content = child ?? const SizedBox.shrink();
    if (online) return content;
    return Column(
      children: [
        Material(
          color: KwColors.red,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}