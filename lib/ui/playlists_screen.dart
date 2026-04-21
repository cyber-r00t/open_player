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
//  You should have received a copy of the GNU AGPL v3 along with this

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/media_item.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_provider.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playlists = ref.watch(playlistProvider);

    return DefaultTabController(
      length: playlists.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.playlists),
          bottom: TabBar(
            isScrollable: true,
            tabs: playlists.map((p) => Tab(text: p.name)).toList(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreatePlaylistDialog(context, ref),
              tooltip: 'Crear nueva playlist',
            ),
          ],
        ),
        body: TabBarView(
          children: playlists.map((playlist) {
            return _PlaylistContent(playlist: playlist);
          }).toList(),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre de la playlist'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(playlistProvider.notifier)
                    .createPlaylist(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistContent extends ConsumerWidget {
  final Playlist playlist;

  const _PlaylistContent({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (playlist.items.isEmpty) {
      return const Center(
        child: Text(
            'Aún no hay canciones. Busca y añade canciones desde la pestaña Buscar.'),
      );
    }

    return ListView.builder(
      itemCount: playlist.items.length,
      itemBuilder: (context, index) {
        final item = playlist.items[index];
        return ListTile(
          leading: CachedNetworkImage(
            imageUrl: item.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => const Icon(Icons.music_note),
          ),
          title: Text(item.title),
          subtitle: Text(item.artist),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              ref
                  .read(playlistProvider.notifier)
                  .removeFromDefaultPlaylist(item.id);
            },
          ),
          onTap: () {
            ref
                .read(audioControllerProvider.notifier)
                .loadPlaylist(playlist.items, initialIndex: index);
          },
        );
      },
    );
  }
}
