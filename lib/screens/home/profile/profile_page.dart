import 'package:flutter/material.dart';
import 'package:mentaly/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../splash_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Fungsi untuk logout
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username'); // Remove saved username
    await prefs.remove('userId'); // Remove saved userId

    // Navigasi kembali ke SplashScreen setelah logout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()), // Navigate back to splash screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileCard(context),
            const SizedBox(height: 16),
            _buildMoodHistoryCard(context),
            const SizedBox(height: 16),
            _buildSettingsCard(context, context),
          ],
        ),
      ),
    );
  }

  // Profile Card
  Widget _buildProfileCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildProfileIcon(),
            const SizedBox(width: 16),
            _buildProfileInfo(context),
          ],
        ),
      ),
    );
  }

  // Profile Icon
  Widget _buildProfileIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text('👤', style: TextStyle(fontSize: 32)),
      ),
    );
  }

  // Profile Information
  Widget _buildProfileInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('John Doe', style: Theme.of(context).textTheme.titleMedium),
        Text('john.doe@example.com', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  // Mood History Card
  Widget _buildMoodHistoryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mood History', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildMoodHistoryItem(context, emoji: '😊', mood: 'Happy', date: 'Yesterday, 2:30 PM'),
            const Divider(),
            _buildMoodHistoryItem(context, emoji: '😔', mood: 'Sad', date: 'May 10, 9:15 AM'),
            const Divider(),
            _buildMoodHistoryItem(context, emoji: '😐', mood: 'Neutral', date: 'May 9, 7:45 PM'),
          ],
        ),
      ),
    );
  }

  // Mood History Item
  Widget _buildMoodHistoryItem(BuildContext context, {required String emoji, required String mood, required String date}) {
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
                Text(mood, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text(date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('View')),
        ],
      ),
    );
  }

  // Settings Card
  Widget _buildSettingsCard(BuildContext context, BuildContext context1) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildSettingsItem(context, icon: Icons.notifications, title: 'Notifications'),
            const Divider(),
            _buildSettingsItem(context, icon: Icons.lock, title: 'Privacy'),
            const Divider(),
            _buildSettingsItem(context, icon: Icons.help, title: 'Help & Support'),
            const Divider(),
            _buildSettingsItem(context, icon: Icons.logout, title: 'Logout', isLogout: true, logoutContext: context1),
          ],
        ),
      ),
    );
  }

  // Settings Item
  Widget _buildSettingsItem(BuildContext context, {required IconData icon, required String title, bool isLogout = false, BuildContext? logoutContext}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isLogout ? Colors.red : AppColors.primaryDark),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : AppColors.primaryDark)),
      trailing: isLogout ? null : const Icon(Icons.chevron_right, color: AppColors.grayDark),
      onTap: () {
        if (isLogout) {
          _logout(logoutContext!); // Call logout if it's logout option
        }
      },
    );
  }
}
