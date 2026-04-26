import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/services/local_file_store.dart';
import '../../../../shared/providers/theme_mode_provider.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../vehicle/presentation/screens/add_vehicle_screen.dart';
import '../../../vehicle/presentation/screens/manage_vehicles_screen.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static String _accountSubtitle(UserProfile? p, AuthSession? s) {
    if (p?.email != null && p!.email.isNotEmpty) return p.email;
    if (p?.phone != null && p!.phone!.isNotEmpty) return p.phone!;
    return s?.displayIdentifier ?? '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final session = ref.watch(authProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);
    final notificationsAsync = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
        data: (p) {
          final name = p?.name ?? session?.name ?? 'Driver';
          final subtitle = _accountSubtitle(p, session);
          final avatarPath = p?.avatarPath;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileGradientHeader(
                  name: name,
                  subtitle: subtitle.isEmpty ? 'Signed in' : subtitle,
                  avatarPath: avatarPath,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _SectionLabel(label: 'Account'),
                    const SizedBox(height: 10),
                    _ProfileTileCard(
                      icon: Icons.edit_outlined,
                      title: 'Edit profile',
                      subtitle: 'Name, phone',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ProfileTileCard(
                      icon: Icons.face_retouching_natural_outlined,
                      title: 'Change avatar',
                      subtitle: 'Update photo from gallery',
                      onTap: () => _pickAndSaveAvatar(context, ref, p, session),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel(label: 'Vehicles'),
                    const SizedBox(height: 10),
                    _ProfileTileCard(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Add vehicle',
                      subtitle: 'Register a new vehicle',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const AddVehicleScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ProfileTileCard(
                      icon: Icons.directions_car_filled_outlined,
                      title: 'Manage vehicles',
                      subtitle: 'View and open vehicle details',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const ManageVehiclesScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel(label: 'App settings'),
                    const SizedBox(height: 10),
                    CustomCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          notificationsAsync.when(
                            loading: () => const ListTile(
                              leading: Icon(Icons.notifications_outlined),
                              title: Text('Notifications'),
                              trailing: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            error: (e, _) => ListTile(
                              leading: const Icon(Icons.notifications_outlined),
                              title: const Text('Notifications'),
                              subtitle: Text('Error: $e'),
                            ),
                            data: (enabled) {
                              return SwitchListTile.adaptive(
                                secondary: const Icon(Icons.notifications_outlined),
                                title: const Text('Notifications'),
                                subtitle: const Text('Trip and document reminders'),
                                value: enabled,
                                onChanged: (v) {
                                  ref.read(authProvider.notifier).setNotificationsEnabled(v);
                                },
                              );
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            secondary: const Icon(Icons.dark_mode_outlined),
                            title: const Text('Dark theme'),
                            subtitle: const Text('Switch between dark and light appearance'),
                            value: themeMode == ThemeMode.dark,
                            onChanged: (v) {
                              ref.read(themeModeProvider.notifier).state =
                                  v ? ThemeMode.dark : ThemeMode.light;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel(label: 'Danger zone'),
                    const SizedBox(height: 10),
                    CustomCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.error),
                        title: Text(
                          'Log out',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text('Sign out on this device'),
                        trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.error),
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _pickAndSaveAvatar(
    BuildContext context,
    WidgetRef ref,
    UserProfile? p,
    AuthSession? session,
  ) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (img == null) return;
    final stored = await LocalFileStore.persistFile(
      sourcePath: img.path,
      namespace: 'profile',
      preferredName: 'avatar',
    );
    final next = UserProfile(
      name: p?.name ?? session?.name ?? 'Driver',
      email: p?.email ?? (session?.loginKey.contains('@') == true ? session!.loginKey : ''),
      phone: p?.phone ?? (session != null && !session.loginKey.contains('@') ? session.loginKey : null),
      avatarPath: stored,
    );
    try {
      await ref.read(profileActionsProvider).save(next);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  static Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    context.go('/login');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
  }
}

class _ProfileGradientHeader extends StatelessWidget {
  const _ProfileGradientHeader({
    required this.name,
    required this.subtitle,
    required this.avatarPath,
  });

  final String name;
  final String subtitle;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple,
            AppColors.purple.withOpacity(0.85),
            AppColors.blue,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: avatarPath != null && File(avatarPath!).existsSync()
                ? FileImage(File(avatarPath!))
                : null,
            child: avatarPath == null
                ? const Icon(Icons.person_rounded, color: Colors.white, size: 48)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ProfileTileCard extends StatelessWidget {
  const _ProfileTileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}
