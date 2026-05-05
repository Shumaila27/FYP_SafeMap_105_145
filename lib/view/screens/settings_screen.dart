// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:staysafe/Controller/theme_controller.dart';
import 'package:staysafe/view/widgets/app_bar.dart';
import '../../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Privacy & Security settings
  bool profileVisibility = true;

  // App Behavior settings
  bool autoStartOnBoot = true;

  // Get theme controller
  bool get isDarkMode => context.watch<ThemeController>().isDarkMode;

  Widget _buildSettingsHeader() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColor.getPrimaryGradient(context),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColor.getInteractivePrimary(context).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.getInteractivePrimary(
              context,
            ).withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.getInteractivePrimary(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColor.getInteractivePrimary(
                    context,
                  ).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize your app experience',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppMainBar(showBack: true),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Settings Header
                _buildSettingsHeader(),

                const SizedBox(height: 24),
                // Dark Mode Toggle
                _buildToggleSetting(
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark theme',
                  value: isDarkMode,
                  onChanged: (value) {
                    context.read<ThemeController>().toggleTheme();
                    _showSnackBar(
                      'Dark mode ${value ? 'enabled' : 'disabled'}',
                    );
                  },
                  icon: LucideIcons.moon,
                ),

                const SizedBox(height: 16),

                // Profile Visibility Toggle
                _buildToggleSetting(
                  title: 'Profile Visibility',
                  subtitle: 'Control who can see your profile',
                  value: profileVisibility,
                  onChanged: (value) {
                    setState(() {
                      profileVisibility = value;
                    });
                    _showSnackBar(
                      'Profile visibility ${value ? 'enabled' : 'disabled'}',
                    );
                  },
                  icon: LucideIcons.eye,
                ),

                const SizedBox(height: 16),

                // Auto Start on Boot Toggle
                _buildToggleSetting(
                  title: 'Auto Start on Boot',
                  subtitle: 'Launch app automatically when device starts',
                  value: autoStartOnBoot,
                  onChanged: (value) {
                    setState(() {
                      autoStartOnBoot = value;
                    });
                    _showSnackBar(
                      'Auto start ${value ? 'enabled' : 'disabled'}',
                    );
                  },
                  icon: LucideIcons.power,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.getContainerBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColor.getContainerBorder(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColor.getInteractivePrimary(
                context,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColor.getIconPrimary(context),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColor.getTextSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColor.getInteractivePrimary(context),
              activeTrackColor: AppColor.getInteractivePrimary(
                context,
              ).withValues(alpha: 0.3),
              inactiveThumbColor: AppColor.getIconSecondary(context),
              inactiveTrackColor: AppColor.getContainerBorder(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColor.appSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
