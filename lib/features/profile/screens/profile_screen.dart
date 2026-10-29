import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hisab/core/providers/theme_provider.dart';
import 'package:hisab/features/auth/providers/auth_provider.dart';
import 'package:hisab/features/home/providers/expense_provider.dart';
import 'package:hisab/features/home/providers/friend_provider.dart';
import 'package:hisab/core/constants.dart';
import 'package:hisab/core/services/haptic_service.dart';
import 'edit_profile_screen.dart';
import 'archive_screen.dart';

import 'package:hisab/core/widgets/avatar.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final friendAsync = ref.watch(friendProvider);
    final profileAsync = ref.watch(profileProvider);

    final myId = user?.uid;
    final friendId = friendAsync.value?['id'];
    
    int myPostCount = 0;
    int friendPostCount = 0;

    expensesAsync.whenData((expenses) {
      for (var e in expenses) {
        if (e.paidBy == myId) myPostCount++;
        if (e.paidBy == friendId) friendPostCount++;
      }
    });

    final myName = user?.displayName ?? 'User';
    final friendName = friendAsync.value?['full_name'] ?? 'Kd';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          HapticService.medium();
          await ref.refresh(expensesProvider.future);
          await ref.refresh(friendProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header with curve
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: ProfileHeaderClipper(),
                    child: Container(
                      height: 280,
                      width: double.infinity,
                      color: AppColors.primary,
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 60),
                      profileAsync.when(
                        data: (profile) => Avatar(
                          imageUrl: profile?['avatar_url'],
                          radius: 55,
                        ),
                        loading: () => const CircleAvatar(
                          radius: 55,
                          child: CircularProgressIndicator(),
                        ),
                        error: (_, __) => const Avatar(radius: 55),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        myName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Post Stats Boxes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        context,
                        '${myName.split(' ').first} Posts',
                        myPostCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        '${friendName.split(' ').first} Posts',
                        friendPostCount.toString(),
                    ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Options List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildOption(
                      context,
                      icon: Icons.person_outline,
                      label: 'Edit Profile',
                      onTap: () {
                        HapticService.light();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      icon: Icons.archive_outlined,
                      label: 'Archive',
                      onTap: () {
                        HapticService.light();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ArchiveScreen()),
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark Mode',
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          HapticService.light();
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: OutlinedButton(
                  onPressed: () {
                    HapticService.medium();
                    _showLogoutDialog(context, ref);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 45),
                    side: BorderSide(color: AppColors.alert.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.alert, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 160), // Increased from 120 to 160 to lift it above the FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? AppColors.primaryLight
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context,
      {required IconData icon, required String label, VoidCallback? onTap, Widget? trailing}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              HapticService.heavy();
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.alert)),
          ),
        ],
      ),
    );
  }
}

class ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(size.width / 2, size.height + 40, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
