/// Shown when a customer account opens the Partner app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala_partner/core/theme/app_theme.dart';
import 'package:kaamwala_partner/features/auth/providers/auth_controller.dart';

class WrongAppScreen extends ConsumerWidget {
  const WrongAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KwSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KwColors.primaryLight,
                  borderRadius: BorderRadius.circular(KwRadius.lg),
                ),
                child: Icon(
                  Icons.home_work_outlined,
                  size: 44,
                  color: KwColors.primary,
                ),
              ),
              const SizedBox(height: KwSpacing.xl),
              Text(
                'This is the Work Partner app',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: KwSpacing.md),
              Text(
                'This number is registered as a customer. Download the '
                'KaamWala app to book verified workers near you.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: KwColors.muted, height: 1.4),
              ),
              const SizedBox(height: KwSpacing.xxl),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Use a different number'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}