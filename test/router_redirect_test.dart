// Routing policy table - worker-only app.
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala_partner/core/routing/app_router.dart';
import 'package:kaamwala_partner/features/auth/providers/auth_controller.dart';

void main() {
  group('appRedirect', () {
    test('loading & startupError pin to splash', () {
      for (final stage in [AppStage.loading, AppStage.startupError]) {
        expect(appRedirect(stage, '/'), '/');
        expect(appRedirect(stage, '/w/home'), '/');
        expect(appRedirect(stage, '/wrong-app'), '/');
      }
    });

    test('onboarding allows only /onboarding', () {
      expect(appRedirect(AppStage.onboarding, '/onboarding'), isNull);
      expect(appRedirect(AppStage.onboarding, '/w/home'), '/onboarding');
      expect(appRedirect(AppStage.onboarding, '/login'), '/onboarding');
    });

    test('login allows any /login* route (incl. OTP)', () {
      expect(appRedirect(AppStage.login, '/login'), isNull);
      expect(appRedirect(AppStage.login, '/login/otp'), isNull);
      expect(appRedirect(AppStage.login, '/w/home'), '/login');
      expect(appRedirect(AppStage.login, '/role'), '/login');
    });

    test('roleSelection pins to /role', () {
      expect(appRedirect(AppStage.roleSelection, '/role'), isNull);
      expect(appRedirect(AppStage.roleSelection, '/w/home'), '/role');
      expect(appRedirect(AppStage.roleSelection, '/login/otp'), '/role');
    });

    test('workerApp: /w/* routes pass, auth/splash/client routes -> /w/home', () {
      for (final ok in [
        '/w/home',
        '/w/earnings',
        '/w/profile',
        '/w/jobs',
        '/w/job/x',
        '/w/active/y',
      ]) {
        expect(appRedirect(AppStage.workerApp, ok), isNull, reason: ok);
      }
      for (final blocked in [
        '/',
        '/login',
        '/login/otp',
        '/role',
        '/onboarding',
        '/home',
        '/search',
        '/bookings',
        '/profile',
        '/worker/abc',
        '/book/w1',
      ]) {
        expect(
          appRedirect(AppStage.workerApp, blocked),
          '/w/home',
          reason: blocked,
        );
      }
    });
  });
}