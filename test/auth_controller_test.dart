import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kaamwala_partner/features/auth/providers/auth_controller.dart';
import 'package:kaamwala_partner/models/user_profile.dart';

void main() {
  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('AuthController.authenticatedAs (post-OTP routing)', () {
    test('null profile -> role selection', () {
      final c = container();
      c.read(authControllerProvider.notifier).authenticatedAs(null);
      expect(c.read(authControllerProvider).stage, AppStage.roleSelection);
    });

    test('unnamed profile -> role selection', () {
      final c = container();
      c
          .read(authControllerProvider.notifier)
          .authenticatedAs(const UserProfile(id: 'u1', phone: '+911234567890'));
      expect(c.read(authControllerProvider).stage, AppStage.roleSelection);
    });

    test('named worker -> worker shell', () {
      final c = container();
      c
          .read(authControllerProvider.notifier)
          .authenticatedAs(
            const UserProfile(
              id: 'u2',
              phone: '+919876543210',
              name: 'Ramesh',
              role: UserRole.worker,
            ),
          );
      expect(c.read(authControllerProvider).stage, AppStage.workerApp);
    });

    test('named client -> role selection (wrong app)', () {
      final c = container();
      c
          .read(authControllerProvider.notifier)
          .authenticatedAs(
            const UserProfile(
              id: 'u1',
              phone: '+911234567890',
              name: 'Rohit',
              role: UserRole.client,
            ),
          );
      expect(c.read(authControllerProvider).stage, AppStage.roleSelection);
    });
  });
}