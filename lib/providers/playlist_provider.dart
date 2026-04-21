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

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

class Playlist {
  final String id;
  final String name;
  final List<MediaItem> items;

  Playlist({required this.id, required this.name, required this.items});

  Playlist copyWith({String? name, List<MediaItem>? items}) {
    return Playlist(
      id: this.id,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items
            .map((e) => {
                  'id': e.id,
                  'title': e.title,
                  'artist': e.artist,
                  'url': e.url,
                  'imageUrl': e.imageUrl,
                  'source': e.source.toString().split('.').last,
                })
            .toList(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      items: (json['items'] as List)
          .map((item) => MediaItem(
                id: item['id'],
                title: item['title'],
                artist: item['artist'],
                url: item['url'],
                imageUrl: item['imageUrl'],
                source: MediaSource.values.firstWhere(
                  (e) => e.toString().split('.').last == item['source'],
                  orElse: () => MediaSource.jamendo,
                ),
              ))
          .toList(),
    );
  }
}

final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, List<Playlist>>((ref) {
  return PlaylistNotifier();
});

class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  static const String _storageKey = 'playlists';

  PlaylistNotifier() : super([]) {
    _loadFromStorage();
  }

  // Garantiza que la playlist por defecto exista
  void _ensureDefaultPlaylist() {
    if (!state.any((p) => p.id == 'default')) {
      state = [
        Playlist(id: 'default', name: 'Mi playlist', items: []),
        ...state,
      ];
    }
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> list = json.decode(jsonString);
      state = list.map((e) => Playlist.fromJson(e)).toList();
    }
    _ensureDefaultPlaylist();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void addToDefaultPlaylist(MediaItem item) {
    _ensureDefaultPlaylist(); // ⬅️ Seguridad adicional
    final defaultPlaylist = state.firstWhere((p) => p.id == 'default');
    if (!defaultPlaylist.items.any((e) => e.id == item.id)) {
      final updatedPlaylist = defaultPlaylist.copyWith(
        items: [...defaultPlaylist.items, item],
      );
      state = [
        updatedPlaylist,
        ...state.where((p) => p.id != 'default'),
      ];
      _saveToStorage();
    }
  }

  void removeFromDefaultPlaylist(String itemId) {
    _ensureDefaultPlaylist();
    final defaultPlaylist = state.firstWhere((p) => p.id == 'default');
    final updatedItems =
        defaultPlaylist.items.where((item) => item.id != itemId).toList();
    state = [
      defaultPlaylist.copyWith(items: updatedItems),
      ...state.where((p) => p.id != 'default'),
    ];
    _saveToStorage();
  }

  void createPlaylist(String name) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    state = [...state, Playlist(id: id, name: name, items: [])];
    _saveToStorage();
  }
}
