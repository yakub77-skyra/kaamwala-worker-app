/// Profile setup after first OTP login - creates worker profile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaamwala_partner/core/error/failure.dart';
import 'package:kaamwala_partner/core/theme/app_theme.dart';
import 'package:kaamwala_partner/features/auth/providers/auth_controller.dart';
import 'package:kaamwala_partner/services/location_service.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _busy = false;
  bool _locating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectCity() async {
    if (_locating || _busy) return;
    setState(() => _locating = true);
    final res = await LocationService.detectCity();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (res) {
      case Success(:final data):
        _cityCtrl.text = data;
      case Error(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name first')),
      );
      return;
    }
    setState(() => _busy = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .finishRoleSelection(
          name: _nameCtrl.text.trim(),
          asWorker: true,
          city: _cityCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your profile. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome!')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KwSpacing.xl),
          children: [
            Text(
              'Create your work profile',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: KwSpacing.sm),
            Text(
              'Tell customers who you are. Next you will pick your '
              'trade and get verified.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: KwColors.muted),
            ),
            const SizedBox(height: KwSpacing.xl),
            Text('Your name', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: KwSpacing.sm),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Ramesh Kumar',
                labelText: 'Your name',
              ),
            ),
            const SizedBox(height: KwSpacing.md),
            TextFormField(
              controller: _cityCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Pune (helps us find nearby jobs)',
                labelText: 'City',
                prefixIcon: const Icon(Icons.location_city_rounded),
                suffixIcon: IconButton(
                  onPressed: _detectCity,
                  tooltip: 'Use my current location',
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ),
            ),
            const SizedBox(height: KwSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _detectCity,
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: const Text('Use my current location'),
              ),
            ),
            const SizedBox(height: KwSpacing.lg),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue as worker'),
            ),
            const SizedBox(height: KwSpacing.sm),
            Text(
              'One phone number = one KaamWala Partner account.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: KwColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}