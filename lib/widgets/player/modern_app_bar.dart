import 'package:flutter/material.dart';

class ModernAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  const ModernAppBar({super.key, required this.title, required this.subtitle, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              key: const Key('backButton'),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: onBack,
            ),
          if (onBack == null)
            Container(
              width: 40,
              height: 40,
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: const Key('modernAppBarTitle'),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  key: const Key('modernAppBarSubtitle'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
