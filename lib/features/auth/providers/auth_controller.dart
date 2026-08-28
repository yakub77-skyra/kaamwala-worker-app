/// Auth state - Riverpod controller (worker-only app).
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala_partner/core/error/failure.dart';
import 'package:kaamwala_partner/features/auth/repositories/auth_repository.dart';
import 'package:kaamwala_partner/models/user_profile.dart';
import 'package:kaamwala_partner/services/analytics_service.dart';
import 'package:kaamwala_partner/services/fcm_service.dart';
import 'package:kaamwala_partner/services/supabase_service.dart';

enum AppStage {
  loading,
  startupError,
  onboarding,
  login,
  roleSelection,
  workerApp,
}

class AuthState {
  const AuthState({this.stage = AppStage.loading, this.profile});

  final AppStage stage;
  final UserProfile? profile;
}

class AuthController extends Notifier<AuthState> {
  final _repo = const AuthRepository();

  @override
  AuthState build() => const AuthState();

  /// Splash logic - session -> worker dashboard, else onboarding/login.
  Future<void> restoreSession({bool firstRun = false}) async {
    state = const AuthState();
    if (!SupabaseService.isReady) {
      state = const AuthState(stage: AppStage.workerApp);
      return;
    }
    final session = SupabaseService.currentSession;
    if (session == null) {
      state = AuthState(stage: firstRun ? AppStage.onboarding : AppStage.login);
      return;
    }
    final result = await _repo.fetchMyProfile();
    final UserProfile? profile;
    switch (result) {
      case Success(:final data):
        profile = data;
      case Error(:final failure)
          when failure is NetworkFailure || failure is ServerFailure:
        state = const AuthState(stage: AppStage.startupError);
        return;
      case Error():
        profile = null;
    }
    if (profile == null || profile.name.isEmpty) {
      state = AuthState(stage: AppStage.roleSelection, profile: profile);
    } else if (profile.role == UserRole.worker) {
      state = AuthState(stage: AppStage.workerApp, profile: profile);
    } else {
      // Client logged into worker app -> wrong app
      state = AuthState(stage: AppStage.roleSelection, profile: profile);
    }
    unawaited(_registerPushToken());
  }

  Future<void> _registerPushToken() async {
    try {
      final uid = SupabaseService.currentUserId;
      if (uid == null) return;
      await FcmService.ensureInitialized();
      final token = await FcmService.getToken();
      if (token == null) return;
      await FcmService.registerToken(uid, token);
    } on Exception catch (_) {}
  }

  void authenticatedAs(UserProfile? profile) {
    if (profile == null || profile.name.isEmpty) {
      state = AuthState(stage: AppStage.roleSelection, profile: profile);
    } else if (profile.role == UserRole.worker) {
      state = AuthState(stage: AppStage.workerApp, profile: profile);
    } else {
      state = AuthState(stage: AppStage.roleSelection, profile: profile);
    }
    unawaited(_registerPushToken());
  }

  Future<bool> finishRoleSelection({
    required String name,
    required bool asWorker,
    required String city,
  }) async {
    final result = await _repo.completeOnboarding(
      name: name,
      role: asWorker ? UserRole.worker : UserRole.client,
      city: city,
    );
    if (result is Success<UserProfile>) {
      state = AuthState(
        stage: asWorker ? AppStage.workerApp : AppStage.roleSelection,
        profile: result.data,
      );
      unawaited(_registerPushToken());
      unawaited(AnalyticsService.setUserRole(asWorker ? 'worker' : 'client'));
      unawaited(
        AnalyticsService.logEvent('onboarding_completed', {
          'role': asWorker ? 'worker' : 'client',
        }),
      );
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(stage: AppStage.login);
  }

  Future<bool> updateAvatar(Uint8List bytes) async {
    final result = await _repo.uploadAvatar(bytes);
    if (result is Success<UserProfile>) {
      state = AuthState(stage: state.stage, profile: result.data);
      return true;
    }
    return false;
  }

  Future<String?> updateDetails({String? name, String? city}) async {
    final result = await _repo.updateDetails(name: name, city: city);
    switch (result) {
      case Success(:final data):
        state = AuthState(stage: state.stage, profile: data);
        return null;
      case Error(:final failure):
        return failure.message;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);