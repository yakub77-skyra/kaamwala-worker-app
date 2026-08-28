/// Connectivity awareness: offline banner state + auto-refresh on reconnect.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala_partner/features/shared/providers/shared_providers.dart';
import 'package:kaamwala_partner/features/worker/providers/worker_providers.dart';

/// True = assume online. Never blocks UI; failures still surface via
/// NetworkFailure from repositories.
class ConnectivityController extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  bool build() {
    ref.onDispose(() => unawaited(_sub?.cancel()));
    _listen();
    return true;
  }

  void _listen() {
    try {
      _sub = Connectivity().onConnectivityChanged.listen((results) {
        final online = !results.contains(ConnectivityResult.none);
        if (online == state) return;
        state = online;
        if (online) _refreshAll();
      }, onError: (_) {});
    } on Exception catch (_) {}
  }

  void _refreshAll() {
    ref.invalidate(unreadCountProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(workerJobsProvider);
    ref.invalidate(activeJobsProvider);
    ref.invalidate(completedJobsProvider);
  }
}

final connectivityProvider = NotifierProvider<ConnectivityController, bool>(
  ConnectivityController.new,
);