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

// lib/services/archive_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';

class ArchiveService {
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json',
  };

  Future<List<MediaItem>> search(String query, {int limit = 10}) async {
    if (query.trim().length < 3) return [];

    final List<MediaItem> items = [];

    try {
      final searchUri = Uri.https('archive.org', '/advancedsearch.php', {
        'q': 'title:($query) AND mediatype:audio',
        'fl[]': 'identifier,title,creator',
        'output': 'json',
        'rows': limit.toString(),
      });

      final searchResponse = await http
          .get(searchUri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (searchResponse.statusCode != 200) {
        throw Exception('HTTP ${searchResponse.statusCode}');
      }

      final searchData = json.decode(searchResponse.body);
      final docs = searchData['response']['docs'] as List? ?? [];

      for (var doc in docs) {
        if (items.length >= limit) break;

        final identifier = doc['identifier'];
        if (identifier == null) continue;

        try {
          final metaUri = Uri.https('archive.org', '/metadata/$identifier');
          final metaResponse = await http
              .get(metaUri, headers: _headers)
              .timeout(const Duration(seconds: 8));

          if (metaResponse.statusCode != 200) continue;

          final metaData = json.decode(metaResponse.body);
          final files = metaData['files'] as List? ?? [];

          String? audioFile;
          for (var file in files) {
            final name = file['name']?.toString() ?? '';
            if (name.endsWith('.mp3') || name.endsWith('.ogg')) {
              audioFile = name;
              break;
            }
          }
          if (audioFile == null) continue;

          items.add(MediaItem(
            id: 'arc-$identifier',
            title: doc['title']?.toString() ?? 'Sin título',
            artist: doc['creator']?.toString() ?? 'Various',
            url: 'https://archive.org/download/$identifier/$audioFile',
            imageUrl: 'https://archive.org/services/img/$identifier',
            source: MediaSource.archive,
          ));
        } catch (_) {
          // Ignorar este ítem y continuar
        }
      }
    } catch (e) {
      // Relanzar para que el provider muestre el banner
      throw Exception('Archive error: $e');
    }

    return items;
  }
}
