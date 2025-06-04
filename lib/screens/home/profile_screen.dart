import 'package:flutter/material.dart';
import 'package:mentaly/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('👤', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'John Doe',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'john.doe@example.com',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood History',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildMoodHistoryItem(
                      context,
                      emoji: '😊',
                      mood: 'Happy',
                      date: 'Yesterday, 2:30 PM',
                    ),
                    const Divider(),
                    _buildMoodHistoryItem(
                      context,
                      emoji: '😔',
                      mood: 'Sad',
                      date: 'May 10, 9:15 AM',
                    ),
                    const Divider(),
                    _buildMoodHistoryItem(
                      context,
                      emoji: '😐',
                      mood: 'Neutral',
                      date: 'May 9, 7:45 PM',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsItem(
                      context,
                      icon: Icons.notifications,
                      title: 'Notifications',
                    ),
                    const Divider(),
                    _buildSettingsItem(
                      context,
                      icon: Icons.lock,
                      title: 'Privacy',
                    ),
                    const Divider(),
                    _buildSettingsItem(
                      context,
                      icon: Icons.help,
                      title: 'Help & Support',
                    ),
                    const Divider(),
                    _buildSettingsItem(
                      context,
                      icon: Icons.logout,
                      title: 'Logout',
                      isLogout: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodHistoryItem(
    BuildContext context, {
    required String emoji,
    required String mood,
    required String date,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('View')),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isLogout = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isLogout ? Colors.red : AppColors.primaryDark),
      title: Text(
        title,
        style: TextStyle(color: isLogout ? Colors.red : AppColors.primaryDark),
      ),
      trailing:
          isLogout
              ? null
              : const Icon(Icons.chevron_right, color: AppColors.grayDark),
      onTap: () {},
    );
  }
}
