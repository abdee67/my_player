import 'package:flutter/material.dart';

typedef OnSearch = void Function(String query);
typedef OnSort = void Function(SortType sortBy);

enum SortType { title, artist, album, duration }

class LibraryHeader extends StatelessWidget {
  final OnSearch onSearch;
  final OnSort onSort;
  final VoidCallback onRefresh;
  final SortType selectedSort;

  const LibraryHeader({
    super.key,
    required this.onSearch,
    required this.onSort,
    required this.onRefresh,
    required this.selectedSort,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search... music, artist, album',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                ),
                onChanged: onSearch,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<SortType>(
              icon: const Icon(Icons.sort, color: Colors.white),
              color: Colors.black87,
              onSelected: (val) => onSort(val),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: SortType.title,
                  child: Row(
                    children: [
                      Icon(Icons.title, color: selectedSort == SortType.title ? Colors.deepPurpleAccent : Colors.white54),
                      const SizedBox(width: 8),
                      const Text('Title'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortType.artist,
                  child: Row(
                    children: [
                      Icon(Icons.person, color: selectedSort == SortType.artist ? Colors.deepPurpleAccent : Colors.white54),
                      const SizedBox(width: 8),
                      const Text('Artist'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortType.album,
                  child: Row(
                    children: [
                      Icon(Icons.album, color: selectedSort == SortType.album ? Colors.deepPurpleAccent : Colors.white54),
                      const SizedBox(width: 8),
                      const Text('Album'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortType.duration,
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: selectedSort == SortType.duration ? Colors.deepPurpleAccent : Colors.white54),
                      const SizedBox(width: 8),
                      const Text('Duration'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: onRefresh,
              tooltip: 'Smart Refresh',
            ),
          ],
        ),
      ),
    );
  }
}
