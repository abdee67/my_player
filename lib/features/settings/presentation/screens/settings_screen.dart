import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Switch between Light and Dark mode'),
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (bool value) {
                // TODO: Implement theme switching logic (e.g., via Provider or a custom ThemeNotifier)
                print('Theme switch toggled: $value');
              },
            ),
            onTap: () {
              // Can navigate to a more detailed theme selection screen
            },
          ),
          ListTile(
            title: const Text('Clear Cache'),
            subtitle: const Text('Clear downloaded album art and temporary files'),
            onTap: () {
              // TODO: Implement cache clearing logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache Cleared! (Placeholder)')),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'), // Replace with actual app version
          ),
          ListTile(
            title: const Text('Open Source Licenses'),
            onTap: () {
              showLicensePage(context: context, applicationName: 'Flutter Music Player');
            },
          ),
        ],
      ),
    );
  }
}