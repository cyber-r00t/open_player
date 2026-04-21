//  OpenPlayer - Liberated Audio Experience
//  Copyright (C) 2024 [Tu Nombre o Alias]
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  Branding, logos and UI design are licensed under CC BY-NC-ND 4.0.
//  You should have received a copy of the GNU AGPL v3 along with this program.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media_item.dart';
import '../providers/favorites_provider.dart';
import '../providers/audio_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Favoritos 🌟')),
      body: favs.isEmpty
          ? const Center(child: Text('Aún no tienes canciones favoritas'))
          : ListView.builder(
              itemCount: favs.length,
              itemBuilder: (context, index) {
                final item = favs[index];
                return _buildTrackTile(context, item, ref);
              },
            ),
    );
  }

  Widget _buildTrackTile(BuildContext context, MediaItem item, WidgetRef ref) {
    // Configuración visual según la fuente
    IconData sourceIcon;
    Color sourceColor;
    String sourceName;
    switch (item.source) {
      case MediaSource.jamendo:
        sourceIcon = Icons.library_music;
        sourceColor = Colors.blue;
        sourceName = 'Jamendo';
        break;
      case MediaSource.audius:
        sourceIcon = Icons.cloud;
        sourceColor = Colors.purple;
        sourceName = 'Audius';
        break;
      case MediaSource.archive:
        sourceIcon = Icons.archive;
        sourceColor = Colors.brown;
        sourceName = 'Archive';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: () =>
            ref.read(audioControllerProvider.notifier).loadPlaylist([item]),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[900],
                        child:
                            const Icon(Icons.music_note, color: Colors.white54),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[900],
                        child: const Icon(Icons.broken_image,
                            color: Colors.white54),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: sourceColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(sourceIcon, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.artist,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: sourceColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sourceName,
                            style: TextStyle(
                              color: sourceColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggleFavorite(item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
