import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  bool _seededFields = false;

  static ButtonStyle get _btnStyle => FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      );

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save(UserProfile? existing, String accountLabel) async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    setState(() => _saving = true);
    try {
      final next = UserProfile(
        name: _name.text.trim(),
        email: existing?.email ?? (accountLabel.contains('@') ? accountLabel : ''),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        avatarPath: existing?.avatarPath,
      );
      await ref.read(profileActionsProvider).save(next);
      await ref.read(authRepositoryProvider).updateSessionName(next.name);
      await ref.read(authProvider.notifier).refreshSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final session = ref.watch(authProvider).valueOrNull;
    final mq = MediaQuery.of(context);
    final bottomPad = mq.viewInsets.bottom + mq.padding.bottom + 24;
    final accountLabel = session?.displayIdentifier ?? '—';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.deferToChild,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('Edit profile')),
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (p) {
            if (!_seededFields && p != null) {
              _seededFields = true;
              _name.text = p.name;
              _phone.text = p.phone ?? '';
            }
            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: bottomPad,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone (optional)'),
                        ),
                        const SizedBox(height: 20),
                        Text('Account', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 6),
                        Text(
                          accountLabel,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email or phone used to sign in can’t be changed here.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Save changes',
                          isLoading: _saving,
                          style: _btnStyle,
                          onPressed: () => _save(p, accountLabel),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
