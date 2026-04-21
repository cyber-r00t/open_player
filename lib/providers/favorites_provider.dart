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

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<MediaItem>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<MediaItem>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favsJson = prefs.getString('favorites');
    if (favsJson != null) {
      final List decoded = json.decode(favsJson);
      state = decoded.map((item) {
        // Parsear el source desde el string guardado
        final sourceStr = item['source'] as String?;
        final source = MediaSource.values.firstWhere(
          (e) => e.toString().split('.').last == sourceStr,
          orElse: () => MediaSource.jamendo, // valor por defecto por si acaso
        );

        return MediaItem(
          id: item['id'] as String,
          title: item['title'] as String,
          artist: item['artist'] as String,
          url: item['url'] as String,
          imageUrl: item['imageUrl'] as String,
          source: source,
        );
      }).toList();
    }
  }

  Future<void> toggleFavorite(MediaItem item) async {
    final isFav = state.any((element) => element.id == item.id);
    if (isFav) {
      state = state.where((element) => element.id != item.id).toList();
    } else {
      state = [...state, item];
    }
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(state
        .map((e) => {
              'id': e.id,
              'title': e.title,
              'artist': e.artist,
              'url': e.url,
              'imageUrl': e.imageUrl,
              'source': e.source
                  .toString()
                  .split('.')
                  .last, // guardar solo el nombre (ej: "jamendo")
            })
        .toList());
    await prefs.setString('favorites', encoded);
  }
}
