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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/media_item.dart';
import '../providers/audio_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final Set<MediaSource> _enabledSources = {
    MediaSource.jamendo,
    MediaSource.audius,
    // MediaSource.archive, // ⬅️ Archive desactivado
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (ref.read(searchQueryProvider) == value) {
        ref.read(searchProvider.notifier).search(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchState = ref.watch(searchProvider);
    final query = ref.watch(searchQueryProvider);
    final favs = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildSourceFilters(),
        ),
      ),
      body: query.length < 3
          ? Center(child: Text(l10n.minChars))
          : _buildResults(searchState, favs),
    );
  }

  Widget _buildSourceFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('Jamendo'),
            selected: _enabledSources.contains(MediaSource.jamendo),
            onSelected: (_) => setState(() {
              if (_enabledSources.contains(MediaSource.jamendo)) {
                _enabledSources.remove(MediaSource.jamendo);
              } else {
                _enabledSources.add(MediaSource.jamendo);
              }
            }),
            avatar: const Icon(Icons.library_music, size: 18),
          ),
          FilterChip(
            label: const Text('Audius'),
            selected: _enabledSources.contains(MediaSource.audius),
            onSelected: (_) => setState(() {
              if (_enabledSources.contains(MediaSource.audius)) {
                _enabledSources.remove(MediaSource.audius);
              } else {
                _enabledSources.add(MediaSource.audius);
              }
            }),
            avatar: const Icon(Icons.cloud, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(SearchState state, List<MediaItem> favs) {
    final filteredResults = state.results
        .where((item) => _enabledSources.contains(item.source))
        .toList();

    if (state.isLoading && filteredResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredResults.isEmpty &&
        state.errorJamendo == null &&
        state.errorAudius == null) {
      return const Center(child: Text('No se encontraron resultados'));
    }

    return Column(
      children: [
        if (state.errorJamendo != null &&
            _enabledSources.contains(MediaSource.jamendo))
          _buildErrorBanner('Jamendo', state.errorJamendo!),
        if (state.errorAudius != null &&
            _enabledSources.contains(MediaSource.audius))
          _buildErrorBanner('Audius', state.errorAudius!),
        Expanded(
          child: ListView.builder(
            itemCount: filteredResults.length,
            itemBuilder: (context, index) {
              final item = filteredResults[index];
              final isFav = favs.any((e) => e.id == item.id);
              return _buildTrackTile(item, isFav);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String source, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.orange.withOpacity(0.2),
      child: Text(
        '⚠️ $source: $error',
        style: const TextStyle(color: Colors.orange),
      ),
    );
  }

  Widget _buildTrackTile(MediaItem item, bool isFav) {
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
      default:
        sourceIcon = Icons.help;
        sourceColor = Colors.grey;
        sourceName = 'Desconocido';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: () {
          final allResults = ref.read(searchProvider).results;
          final index = allResults.indexOf(item);
          if (index != -1) {
            ref.read(audioControllerProvider.notifier).loadPlaylist(
                  allResults,
                  initialIndex: index,
                );
          }
        },
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
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggleFavorite(item),
              ),
              IconButton(
                icon: const Icon(Icons.playlist_add),
                onPressed: () {
                  ref
                      .read(playlistProvider.notifier)
                      .addToDefaultPlaylist(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('"${item.title}" añadido a Mi playlist')),
                  );
                },
                tooltip: 'Agregar a Mi playlist',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
